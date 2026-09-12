-- Execute once in the SQL editor of the project's Supabase database.
create extension if not exists pgcrypto;
create table public.admin_users(user_id uuid primary key references auth.users(id) on delete cascade);
alter table public.admin_users enable row level security;
create policy own_admin_record on public.admin_users for select to authenticated using(user_id=auth.uid());
create function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$select exists(select 1 from public.admin_users where user_id=auth.uid())$$;
create table public.categories(id uuid primary key default gen_random_uuid(),name text not null unique check(length(trim(name)) between 1 and 100),created_at timestamptz not null default now());
create table public.sales_groups(id uuid primary key default gen_random_uuid(),name text not null unique check(length(trim(name)) between 1 and 100),created_at timestamptz not null default now());
create table public.products(id uuid primary key default gen_random_uuid(),category_id uuid not null references public.categories(id),name text not null check(length(trim(name)) between 1 and 180),price numeric(12,2) not null check(price>=0),color text not null default '',material text not null default '',description text not null default '',published boolean not null default true,created_at timestamptz not null default now());
create table public.product_costs(product_id uuid primary key references public.products(id) on delete cascade,cost numeric(12,2) not null default 0 check(cost>=0));
create sequence public.item_code_seq;
create table public.product_items(id uuid primary key default gen_random_uuid(),product_id uuid not null references public.products(id),code text not null unique default ('VB'||lpad(nextval('public.item_code_seq')::text,6,'0')),quantity integer not null default 1 check(quantity between 1 and 1000),status text not null default 'disponivel' check(status in ('disponivel','reservado','vendido','consignado','devolvido','inativo')),group_id uuid references public.sales_groups(id),location text not null default 'Loja',created_at timestamptz not null default now());
create table public.product_images(id uuid primary key default gen_random_uuid(),product_id uuid not null references public.products(id) on delete cascade,url text not null,position integer not null default 0);
create table public.stock_movements(id uuid primary key default gen_random_uuid(),item_id uuid not null references public.product_items(id),type text not null,quantity integer not null,actor uuid references auth.users(id),reason text not null,reference uuid,created_at timestamptz not null default now());
create function public.audit_item() returns trigger language plpgsql security definer set search_path=public as $$begin
 insert into stock_movements(item_id,type,quantity,actor,reason,reference) values(new.id,case when TG_OP='INSERT' then 'entrada' else 'ajuste' end,case when TG_OP='INSERT' then new.quantity else new.quantity-old.quantity end,auth.uid(),case when TG_OP='INSERT' then 'Cadastro inicial' else 'Alteração de estoque: '||old.status||' → '||new.status end,new.product_id);return new;end$$;
create trigger audit_stock after insert or update on public.product_items for each row execute function public.audit_item();
alter table public.categories enable row level security;
alter table public.sales_groups enable row level security;
alter table public.products enable row level security;
alter table public.product_costs enable row level security;
alter table public.product_items enable row level security;
alter table public.product_images enable row level security;
alter table public.stock_movements enable row level security;
create policy read_categories on public.categories for select using(true);
create policy manage_categories on public.categories for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy manage_groups on public.sales_groups for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy read_products on public.products for select using(published or public.is_admin());
create policy manage_products on public.products for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy manage_costs on public.product_costs for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy manage_items on public.product_items for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy read_images on public.product_images for select using(exists(select 1 from public.products p where p.id=product_id and p.published) or public.is_admin());
create policy manage_images on public.product_images for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy read_movements on public.stock_movements for select to authenticated using(public.is_admin());
-- A narrowly scoped definer view exposes aggregate availability, never item locations or costs.
create view public.catalog as select p.id,p.name,c.name as category,p.price,p.color,p.material,p.description,p.created_at,coalesce((select sum(i.quantity)::integer from public.product_items i where i.product_id=p.id and i.status='disponivel'),0) as quantity,(select pi.url from public.product_images pi where pi.product_id=p.id order by pi.position limit 1) as image from public.products p join public.categories c on c.id=p.category_id where p.published;
grant select on public.catalog to anon,authenticated;
create function public.create_product_batch(entries jsonb) returns jsonb language plpgsql security invoker set search_path=public as $$declare entry jsonb;pid uuid;image_url text;idx integer;ids jsonb='[]';begin
 if not public.is_admin() then raise exception 'Administrator required';end if;
 if jsonb_typeof(entries)<>'array' or jsonb_array_length(entries) not between 1 and 30 then raise exception 'Invalid batch';end if;
 for entry in select * from jsonb_array_elements(entries) loop
 if jsonb_array_length(entry->'images') not between 1 and 20 then raise exception 'Images required';end if;
 insert into public.products(name,category_id,price,color,material,description) values(entry->>'name',(entry->>'category_id')::uuid,(entry->>'price')::numeric,coalesce(entry->>'color',''),coalesce(entry->>'material',''),coalesce(entry->>'description','')) returning id into pid;
 insert into public.product_costs(product_id,cost) values(pid,coalesce((entry->>'cost')::numeric,0));
 insert into public.product_items(product_id,quantity,group_id) values(pid,coalesce((entry->>'quantity')::integer,1),(entry->>'group_id')::uuid);
 idx=0;for image_url in select jsonb_array_elements_text(entry->'images') loop
 insert into public.product_images(product_id,url,position) values(pid,image_url,idx);idx=idx+1;end loop;
 ids=ids||jsonb_build_array(pid);end loop;return ids;end$$;
revoke all on function public.create_product_batch(jsonb) from public,anon;
grant execute on function public.create_product_batch(jsonb) to authenticated;
insert into public.categories(name) values('Brincos'),('Colares'),('Pulseiras'),('Anéis'),('Conjuntos'),('Outros');
insert into public.sales_groups(name) values('Site'),('Evento'),('Live'),('Loja'),('Consignado');
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('product-images','product-images',true,8388608,array['image/jpeg','image/png','image/webp']);
create policy public_product_images on storage.objects for select using(bucket_id='product-images');
create policy admin_upload on storage.objects for insert to authenticated with check(bucket_id='product-images' and public.is_admin());
create policy admin_remove_image on storage.objects for delete to authenticated using(bucket_id='product-images' and public.is_admin());
create index product_items_product_idx on public.product_items(product_id);
create index product_images_product_idx on public.product_images(product_id);
create index stock_movements_item_idx on public.stock_movements(item_id);
