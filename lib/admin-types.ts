export type Named={id:string;name:string};
export type AdminProduct={id:string;name:string;category:string;category_id:string;price:number;cost:number;color:string;material:string;description:string;published:number;quantity:number;image:string};
export type Piece={id:string;product_id:string;code:string;name:string;category:string;image:string;price_cents:number;status:string;group_id:string|null;group_name:string|null;location:string};
export type OrderLine={name:string;price_cents:number;image:string;code_seq:number};
export type Order={id:string;code:string;name:string;phone:string;status:string;payment:string;payment_method:string;total_cents:number;delivery:string;cep:string;street:string;number:string;complement:string;neighborhood:string;city:string;state:string;reference:string;notes:string;created_at:string;expires_at:string|null;items:OrderLine[]};
export type Movement={id:number;name:string;code_seq:number;type:string;reason:string;actor:string;created_at:string};
export type Customer={id:string;name:string;phone:string;order_count:number;total_cents:number;created_at:string};
export type AdminData={categories:Named[];groups:Named[];products:AdminProduct[];items:Piece[];orders:Order[];movements:Movement[];settings:Record<string,string>;customers:Customer[]};
export const labels:Record<string,string>={novo:'Novo',confirmado:'Confirmado',preparando:'Preparando',enviado:'Enviado',entregue:'Entregue',cancelado:'Cancelado',expirado:'Reserva expirada',disponivel:'Disponível',reservado:'Reservado',vendido:'Vendido',inativo:'Inativo',consignado:'Consignado',aguardando:'Aguardando pagamento',pago:'Pago',estornado:'Estornado'};
export const date=(v:string)=>new Date(v).toLocaleString('pt-BR',{dateStyle:'short',timeStyle:'short'});
export async function adminSave(payload:unknown){const r=await fetch('/api/admin',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(payload)});const d=await r.json() as {error?:string};if(!r.ok)throw Error(d.error||'Não foi possível salvar.');}
