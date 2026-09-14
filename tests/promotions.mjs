import assert from 'node:assert/strict';
const base='http://localhost:5173',login=await fetch(base+'/signin-with-chatgpt?return_to=/admin',{redirect:'manual'}),cookie=login.headers.get('set-cookie').split(';')[0];
async function call(path,body){const r=await fetch(base+path,{method:body?'POST':'GET',headers:{Cookie:cookie,Origin:base,'Content-Type':'application/json'},body:body?JSON.stringify(body):undefined});return {status:r.status,data:await r.json()}}
const a=(await call('/api/admin')).data,tag='Promo '+crypto.randomUUID();
await call('/api/admin',{action:'products',products:[{name:tag,category_id:a.categories[0].id,price:50,cost:10,quantity:3,group_id:null,images:['/images/peca-3.png']}]});
const current=(await call('/api/admin')).data,p=current.products.find(p=>p.name===tag),code='BETA-'+Date.now();
assert.equal((await call('/api/operations',{action:'coupon',code,kind:'percentual',value:1000,expires:'2099-12-31',active:true})).status,200);
assert.equal((await call('/api/coupon?code='+code+'&total=5000')).data.discount,500);
const checkout={request_key:crypto.randomUUID(),receipt_token:crypto.randomUUID(),name:'Cliente teste',phone:'41999998888',delivery:'retirada',coupon:code,items:[{product_id:p.id,price_cents:5000,quantity:1}]};
const result=await call('/api/orders',checkout);assert.equal(result.status,201,JSON.stringify(result.data));assert.equal(result.data.total,45);assert.equal(result.data.discount,500);
assert.equal((await call('/api/orders',{...checkout,request_key:crypto.randomUUID(),receipt_token:crypto.randomUUID(),coupon:'INEXISTENTE'})).status,400);
const item=(await call('/api/admin')).data.items.find(i=>i.product_id===p.id&&i.status==='disponivel');
const live=await call('/api/operations',{action:'live',request_key:crypto.randomUUID(),customer:'Cliente live',phone:'41999997777',items:[item.id]});assert.equal(live.status,200,JSON.stringify(live.data));
const updated=(await call('/api/admin')).data;assert.equal(updated.items.find(i=>i.id===item.id).status,'reservado');assert.equal(updated.orders.find(o=>o.phone==='41999997777'&&o.status==='novo').origin,'Live');
const second=current.products.find(x=>x.id!==p.id&&x.published);
assert.equal((await call('/api/operations',{action:'kit',name:tag,products:[p.id,second.id]})).status,200);assert((await call('/api/kits')).data.kits.some(k=>k.name===tag));
await call('/api/admin',{action:'edit_product',...p,published:false});assert(!(await call('/api/kits')).data.kits.some(k=>k.name===tag));
console.log('PASS: percentage coupons, stored discount totals, invalid coupons, live reservation, origin tracking, kit composition and hidden-product kit protection.');
