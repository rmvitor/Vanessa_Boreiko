# Vanessa Boreiko Acessórios — primeira entrega

Fundação do site e da gestão, sem pedidos, financeiro ou consignações nesta etapa.

## Estrutura

- React 19, Next.js App Router, TypeScript e Tailwind; execução e publicação com Vinext/Cloudflare Workers.
- `app/page.tsx`: vitrine pública responsiva, usando as fotos fornecidas.
- `components/storefront.tsx`: categorias, busca, ordenação, detalhes e consulta pelo WhatsApp.
- `app/admin/page.tsx` e `components/admin.tsx`: login, categorias, grupos, cadastro individual, cadastro por fotos e estoque.
- `lib/supabase.ts`: cliente HTTP Supabase no servidor, validação de sessão e autorização administrativa.
- `app/api/catalog`, `app/api/session`, `app/api/admin`, `app/api/upload`: endpoints com validações e proteção de operações.
- `supabase/migrations/202609120001_foundation.sql`: estrutura PostgreSQL, RLS, Storage e operação atômica de cadastro.

## Dados

Tabelas: `categories`, `sales_groups`, `products`, `product_items`, `product_images`, `product_costs`, `admin_users`, `stock_movements`. A view `catalog` expõe apenas informações comerciais e disponibilidade agregada. Custos, localização e códigos de peças não são públicos.

Produtos, peças e grupos são entidades distintas. Cada foto no cadastro rápido gera um produto e uma peça de quantidade 1. O cadastro individual aceita diversas fotos do mesmo produto. Códigos VB são gerados no banco. Um trigger registra entradas e alterações no estoque. O cadastro de um lote é uma transação PostgreSQL: falhas não deixam produtos parcialmente cadastrados.

## Ativar o Supabase

1. Crie ou escolha um projeto Supabase.
2. Execute a migration no SQL Editor ou com `supabase db push` após vincular o projeto.
3. No Supabase Auth, crie o usuário administrativo com e-mail e senha. Não há autoinscrição administrativa.
4. No SQL Editor, autorize o UUID desse usuário:

```sql
insert into public.admin_users(user_id) values ('UUID-DO-USUARIO');
```

5. Copie `.env.example` para `.env` e informe `SUPABASE_URL` e `SUPABASE_ANON_KEY`. Uma chave pública é suficiente. Não use `service_role`. Configure os mesmos valores no ambiente hospedado.
6. Reinicie o site e entre em `/admin`.

Sem configuração, a vitrine mostra somente as fotos fornecidas, com nomes descritivos provisórios e valores/disponibilidade sob consulta. Não cria estoque fictício. O login fica inativo. Ao conectar o banco, o catálogo passa a usar os registros reais, inclusive o estado vazio inicial.

## Execução local

Node.js 22.13 ou superior, npm instalado:

```sh
npm ci
npm run dev
```

Abra `http://localhost:5173`. Verificação: `npx tsc --noEmit` e `npm run build`. `npm start` serve a compilação local.

## Validação e limites

O Supabase não foi provisionado nem recebeu a migration automaticamente: faltam os dados do projeto. Portanto, login real, políticas RLS, upload, persistência e transações precisam de teste integrado após configuração. Nenhum sucesso de gravação é simulado no navegador. A sessão expira conforme o token Supabase e exige novo login; renovação automática fica pendente. Uploads concluídos antes de um cadastro interrompido podem deixar arquivos órfãos no Storage, sem registros de produto; limpeza fica pendente.

Não foi solicitado teste visual automatizado no navegador. A responsividade foi implementada em CSS. WebMCP tem filtro opcional, com detecção de suporte; não foi verificado em um contexto WebMCP compatível.

Próxima validação: criar usuário administrador, negar usuário não autorizado, cadastrar/editar categoria, cadastrar produto com foto, cadastrar lote, conferir códigos e movimentações, e verificar leitura anônima sem acesso a custos/estoque interno.

## Etapas posteriores

Pedidos, carrinho, reservas, vendas, modo evento, financeiro, consignações, etiquetas e portal de revendedoras aguardam validação desta base. Preços, composição e estoque das fotos fornecidas precisam ser cadastrados pela loja. O telefone e Instagram foram transcritos das imagens.
