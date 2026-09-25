export type Sale={id:string;code:string;origin:string;customer:string;phone:string;method:string;status:string;total_cents:number;created_at:string};
export type SaleLine={id:string;sale_id:string;item_id:string|null;group_id:string|null;category_id:string|null;name:string;price_cents:number;cost_cents:number;commission_cents:number;quantity:number};
export type Reseller={email?:string;id:string;name:string;phone:string;notes:string;active:number;commission:number};
export type Lot={id:string;code:string;reseller_id:string;reseller:string;commission:number;notes:string;created_at:string};
export type Consigned={id:string;consignment_id:string;item_id:string;name:string;image:string;code:string;status:string;price_cents:number;cost_cents:number};
export type Expense={id:string;description:string;category:string;amount_cents:number;date:string;method:string;notes:string};
export type Receipt={id:string;reseller_id:string;amount_cents:number;date:string;notes:string};
export type Quick={id:string;code:string;name:string;price_cents:number;group_id:string;category_id:string};
export type CustomerDetail={id:string;name:string;phone:string;address:string;notes:string;first_order:string|null;last_order:string|null};
export type Detail={product_id:string;supplier:string;acquired:string;notes:string;collection:string;featured:number};
export type InventoryLot={id:string;code:string;product_id:string;group_id:string|null;name:string;price_cents:number;cost_cents:number;quantity:number;reserved:number;sold:number;category:string};
export type Ops={inventoryLots:InventoryLot[];history:{id:string;customer_id:string;seq:number;total_cents:number;created_at:string;status:string}[];coupons:{id:string;code:string;kind:string;value:number;expires:string;active:number}[];kits:{id:string;name:string;active:number}[];kitItems:{kit_id:string;product_id:string}[];sales:Sale[];lines:SaleLine[];expenses:Expense[];resellers:Reseller[];lots:Lot[];consigned:Consigned[];receipts:Receipt[];quick:Quick[];customers:CustomerDetail[];details:Detail[];images:{id:string;product_id:string;url:string;position:number}[]};
export async function saveOperation(payload:unknown){const r=await fetch('/api/operations',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(payload)});const d=await r.json() as {error?:string;code?:string};if(!r.ok)throw Error(d.error||'Não foi possível salvar.');return d as {code?:string};}
export const today=()=>new Date().toLocaleDateString('en-CA',{timeZone:'America/Sao_Paulo'});
