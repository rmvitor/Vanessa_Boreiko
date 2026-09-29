import {z} from 'zod';
import {all,database,statement} from './database';
const id=z.string().min(1).max(100);
export function routinePeriod(task:string){const today=new Date().toLocaleDateString('en-CA',{timeZone:'America/Sao_Paulo'});if(task.startsWith('daily_'))return today;const d=new Date(today+'T12:00:00Z');d.setUTCDate(d.getUTCDate()-((d.getUTCDay()+6)%7));return d.toISOString().slice(0,10)}
export const routineTasks=['daily_orders','daily_payments','daily_reserves','weekly_consignments','weekly_receipts','weekly_costs','weekly_expenses'] as const;
export async function eventOperation(data:unknown,actor:string){
 const d=z.object({action:z.string()}).passthrough().parse(data);
 if(d.action==='routine_check'){const v=z.object({task:z.enum(routineTasks),done:z.boolean(),notes:z.string().trim().max(1000).default('')}).parse(d),period=routinePeriod(v.task);await statement("INSERT INTO routine_checks(id,period,task,done,notes,actor,updated_at) VALUES(?,?,?,?,?,?,?) ON CONFLICT(period,task) DO UPDATE SET done=excluded.done,notes=excluded.notes,actor=excluded.actor,updated_at=excluded.updated_at",crypto.randomUUID(),period,v.task,v.done?1:0,v.notes,actor,new Date().toISOString()).run();return {}}
 if(d.action==='event_open'||d.action==='event_restock'){
  const v=z.object({request_key:z.string().uuid(),session_id:id.optional(),name:z.string().trim().min(2).max(120).optional(),channel:z.enum(['Evento','Live']).optional(),location:z.string().trim().min(2).max(160).optional(),notes:z.string().max(2000).default(''),items:z.array(z.object({product_id:id,quantity:z.number().int().min(1).max(500)})).min(1).max(100)}).parse(d);
  if((await all('SELECT key FROM product_requests WHERE key=?',v.request_key)).length)return {};
  if(new Set(v.items.map(i=>i.product_id)).size!==v.items.length||v.items.reduce((n,i)=>n+i.quantity,0)>500)throw Error('Separe até 500 unidades por saída, sem repetir o produto.');
  const opening=d.action==='event_open',session=opening?v.request_key:v.session_id;
  if(!session||opening&&(!v.name||!v.channel||!v.location))throw Error('Informe nome, local e canal.');
  if(!opening&&!(await all("SELECT id FROM event_sessions WHERE id=? AND status='aberto'",session)).length)throw Error('Esta sessão não está aberta.');
  const commands=[statement('INSERT INTO product_requests(key) VALUES(?)',v.request_key)];
  if(opening)commands.push(statement('INSERT INTO event_sessions(id,name,channel,location,notes,actor) VALUES(?,?,?,?,?,?)',session,v.name!,v.channel!,v.location!,v.notes,actor));
  for(const item of v.items){const units=await all<{id:string;name:string;location:string}>("SELECT i.id,i.location,p.name FROM product_items i JOIN products p ON p.id=i.product_id WHERE i.product_id=? AND i.status='disponivel' AND i.event_id IS NULL AND p.deleted_at IS NULL ORDER BY i.seq LIMIT ?",item.product_id,item.quantity);if(units.length!==item.quantity)throw Error('Saldo insuficiente para separar. Atualize a tela.');for(const unit of units)commands.push(statement('INSERT INTO event_stock(id,session_id,item_id,product_id,name,original_location) VALUES(?,?,?,?,?,?)',crypto.randomUUID(),session,unit.id,item.product_id,unit.name,unit.location));}
  await database().batch(commands);return {message:opening?'Abertura registrada':'Reposição enviada'};
 }
 if(d.action==='event_close'){
  const v=z.object({request_key:z.string().uuid(),session_id:id,counts:z.array(z.object({product_id:id,expected:z.number().int().min(0),returned:z.number().int().min(0)})).min(1).max(500),expected_cents:z.number().int().min(0),counted_cents:z.number().int().min(0).max(100000000),notes:z.string().trim().max(2000).default('')}).parse(d);
  if((await all('SELECT id FROM event_closures WHERE id=?',v.request_key)).length)return {};
  await statement('INSERT INTO event_closures(id,session_id,counts,expected_cents,counted_cents,notes,actor) VALUES(?,?,?,?,?,?,?)',v.request_key,v.session_id,JSON.stringify(v.counts),v.expected_cents,v.counted_cents,v.notes,actor).run();return {message:'Fechamento registrado; retorno ao estoque de origem concluído'};
 }
 throw Error('Rotina inválida.');
}
export async function eventData(){
 const [sessions,sessionStock,closures,sessionPayments,routineChecks,routineSummary]=await Promise.all([
 all(`SELECT e.*,coalesce((SELECT sum(total_cents) FROM sales WHERE event_id=e.id AND status='concluida'),0)+coalesce((SELECT sum(total_cents) FROM orders WHERE event_id=e.id AND status IN ('confirmado','preparando','enviado','entregue') AND payment='pago'),0) expected_cents,(SELECT count(*) FROM orders WHERE event_id=e.id AND (status IN ('novo','draft') OR (status IN ('confirmado','preparando','enviado','entregue') AND payment<>'pago') OR (status IN ('cancelado','expirado') AND payment='pago'))) pending_orders FROM event_sessions e ORDER BY e.created_at DESC`),
 all(`SELECT es.session_id,es.product_id,max(es.name) name,(SELECT id FROM inventory_lots WHERE product_id=es.product_id) lot_id,count(*) sent,sum(CASE WHEN es.outcome='vendido' OR (e.status='aberto' AND i.status='vendido') THEN 1 ELSE 0 END) sold,sum(CASE WHEN e.status='aberto' AND i.status='disponivel' THEN 1 ELSE 0 END) available,sum(CASE WHEN e.status='aberto' AND i.status='reservado' THEN 1 ELSE 0 END) reserved,sum(CASE WHEN es.outcome='retornado' THEN 1 ELSE 0 END) returned,sum(CASE WHEN es.outcome='divergencia' THEN 1 ELSE 0 END) missing FROM event_stock es JOIN event_sessions e ON e.id=es.session_id JOIN product_items i ON i.id=es.item_id GROUP BY es.session_id,es.product_id`),
 all('SELECT * FROM event_closures ORDER BY created_at DESC'),
 all(`SELECT event_id,method,sum(total_cents) amount FROM (SELECT event_id,method,total_cents FROM sales WHERE event_id IS NOT NULL AND status='concluida' UNION ALL SELECT event_id,payment_method method,total_cents FROM orders WHERE event_id IS NOT NULL AND status IN ('confirmado','preparando','enviado','entregue') AND payment='pago') GROUP BY event_id,method`),
 all('SELECT * FROM routine_checks ORDER BY updated_at DESC LIMIT 200'),
 all(`SELECT (SELECT count(*) FROM orders WHERE deleted_at IS NULL AND status='novo') new_orders,(SELECT count(*) FROM orders WHERE deleted_at IS NULL AND status IN ('novo','confirmado','preparando','enviado','entregue') AND payment='aguardando') awaiting_payment,(SELECT count(*) FROM product_items WHERE status='reservado') reservations,(SELECT count(*) FROM consignment_items WHERE status='em_posse') consigned,(SELECT count(*) FROM products WHERE deleted_at IS NULL AND cost_cents=0) missing_costs,coalesce((SELECT sum(l.price_cents*l.quantity-l.commission_cents) FROM sale_lines l JOIN sales s ON s.id=l.sale_id WHERE s.origin='Revendedora' AND s.status='concluida'),0)-coalesce((SELECT sum(amount_cents) FROM reseller_receipts),0) due_cents`)
 ]);
 return {sessions,sessionStock,closures,sessionPayments,routineChecks,routineSummary:routineSummary[0],routinePeriods:{daily:routinePeriod('daily_orders'),weekly:routinePeriod('weekly_costs')}};
}
