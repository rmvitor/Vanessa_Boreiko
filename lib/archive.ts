import {all,database,statement} from './database';
import {z} from 'zod';
export async function archiveRecord(data:unknown,actor:string){
 const d=z.object({action:z.enum(['delete_product','restore_product','delete_order','restore_order']),id:z.string().min(1)}).parse(data);
 if(d.action==='delete_product')await database().batch([statement("UPDATE products SET deleted_at=strftime('%Y-%m-%dT%H:%M:%fZ','now') WHERE id=? AND deleted_at IS NULL",d.id),statement("UPDATE product_items SET status='inativo',actor=?,reason='Produto excluído' WHERE product_id=? AND status='disponivel'",actor,d.id)]);
 if(d.action==='restore_product')await database().batch([statement('UPDATE products SET deleted_at=NULL WHERE id=?',d.id),statement("UPDATE product_items SET status='disponivel',actor=?,reason='Produto restaurado' WHERE product_id=? AND status='inativo' AND reason='Produto excluído'",actor,d.id)]);
 if(d.action==='delete_order'){
  const [o]=await all<{status:string;payment:string}>('SELECT status,payment FROM orders WHERE id=?',d.id);if(!o)throw Error('Pedido não encontrado.');
  if(['novo','confirmado','preparando'].includes(o.status)&&o.payment==='pago')throw Error('Registre o estorno antes de excluir um pedido pago ainda não enviado.');
  await database().batch([statement("UPDATE orders SET status='cancelado',actor=?,expires_at=NULL WHERE id=? AND status IN ('novo','confirmado','preparando')",actor,d.id),statement("UPDATE orders SET deleted_at=strftime('%Y-%m-%dT%H:%M:%fZ','now') WHERE id=?",d.id)]);
 }
 if(d.action==='restore_order')await statement('UPDATE orders SET deleted_at=NULL WHERE id=?',d.id).run();
}
