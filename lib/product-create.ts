import {database,statement,all} from './database';
import {productInput} from './validation';
import {z} from 'zod';
export async function createProducts(data:Record<string,unknown>,actor:string){
 const key=data.request_key===undefined?crypto.randomUUID():z.string().uuid().parse(data.request_key);
 if((await all('SELECT key FROM product_requests WHERE key=?',key)).length)return;
 const entries=z.array(productInput).min(1).max(30).parse(data.products);
 if(entries.reduce((n,p)=>n+p.quantity,0)>200)throw Error('Cadastre até 200 peças por envio.');
 const payload=JSON.stringify(entries.map(p=>({...p,id:crypto.randomUUID(),price:Math.round(p.price*100),cost:Math.round(p.cost*100),published:p.published?1:0})));
 try{await database().batch([
 statement('INSERT INTO product_requests(key) VALUES(?)',key),
 statement(`INSERT INTO products(id,name,category_id,price_cents,cost_cents,color,material,description,published,channels) SELECT json_extract(value,'$.id'),json_extract(value,'$.name'),json_extract(value,'$.category_id'),json_extract(value,'$.price'),json_extract(value,'$.cost'),json_extract(value,'$.color'),json_extract(value,'$.material'),json_extract(value,'$.description'),json_extract(value,'$.published'),json_extract(value,'$.channels') FROM json_each(?)`,payload),
 statement(`INSERT INTO product_images(id,product_id,url,position) SELECT lower(hex(randomblob(16))),json_extract(p.value,'$.id'),i.value,i.key FROM json_each(?) p,json_each(json_extract(p.value,'$.images')) i`,payload),
 statement(`WITH RECURSIVE nums(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM nums WHERE n<100) INSERT INTO product_items(id,product_id,group_id,actor,reason) SELECT lower(hex(randomblob(16))),json_extract(p.value,'$.id'),json_extract(p.value,'$.group_id'),?,'Cadastro de produto' FROM json_each(?) p JOIN nums ON nums.n<=json_extract(p.value,'$.quantity')`,actor,payload)
 ])}catch(e){if(!(await all('SELECT key FROM product_requests WHERE key=?',key)).length)throw e}
}
