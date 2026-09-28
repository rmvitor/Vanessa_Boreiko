import {all,database,statement} from './database';
import {z} from 'zod';
export async function settleLot(data:unknown,actor:string){
 const d=z.object({request_key:z.string().uuid(),consignment_id:z.string(),lot_id:z.string(),quantity:z.number().int().min(1).max(100),status:z.enum(['vendida','devolvida','perdida']),price_cents:z.number().int().min(1).max(10000000)}).parse(data);
 if((await all('SELECT key FROM product_requests WHERE key=?',d.request_key)).length)return {};
 const rows=await all<{id:string;item_id:string;cost_cents:number;commission:number;reseller_id:string;name:string;category_id:string;group_id:string|null}>("SELECT ci.*,c.commission,c.reseller_id,p.name,p.category_id,i.group_id FROM consignment_items ci JOIN consignments c ON c.id=ci.consignment_id JOIN product_items i ON i.id=ci.item_id JOIN products p ON p.id=i.product_id JOIN inventory_lots l ON l.product_id=p.id WHERE ci.consignment_id=? AND l.id=? AND ci.status='em_posse' ORDER BY ci.id LIMIT ?",d.consignment_id,d.lot_id,d.quantity);
 if(rows.length!==d.quantity)throw Error('Quantidade em consignação insuficiente. Atualize a tela.');
 const commands=[statement('INSERT INTO product_requests(key) VALUES(?)',d.request_key)];
 if(d.status==='vendida'){const sale=crypto.randomUUID();commands.push(statement("INSERT INTO sales(id,code,request_key,origin,customer,method,total_cents,expected,actor) VALUES(?,?,?,'Revendedora',?,'outro',?,?,?)",sale,'REV-'+sale.slice(0,8).toUpperCase(),d.request_key,rows[0].reseller_id,d.price_cents*d.quantity,d.quantity,actor));for(const row of rows)commands.push(statement('INSERT INTO sale_lines(id,sale_id,item_id,group_id,category_id,name,price_cents,cost_cents,commission_cents,consignment_item_id) VALUES(?,?,?,?,?,?,?,?,?,?)',crypto.randomUUID(),sale,row.item_id,row.group_id,row.category_id,row.name,d.price_cents,row.cost_cents,Math.round(d.price_cents*row.commission/10000),row.id));commands.push(statement("UPDATE sales SET status='concluida' WHERE id=?",sale));}
 for(const row of rows)commands.push(statement("UPDATE consignment_items SET status=?,settled_at=strftime('%Y-%m-%dT%H:%M:%fZ','now') WHERE id=?",d.status,row.id));
 await database().batch(commands);return {};
}
