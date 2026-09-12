import assert from 'node:assert/strict';
const base='http://localhost:5173';
let cookie='';
async function call(path,{method='GET',body,admin=false,origin=base,headers={}}={}){const r=await fetch(base+path,{method,redirect:'manual',headers:{...(method!=='GET'?{Origin:origin}:{}),...(body?{'Content-Type':'application/json'}:{}),...(admin?{Cookie:cookie}:{}),...headers},body:body?JSON.stringify(body):undefined});let data;try{data=await r.json()}catch{data={}}return {status:r.status,data,headers:r.headers};}
const login=await call('/signin-with-chatgpt?return_to=/admin');assert.equal(login.status,302);cookie=login.headers.get('set-cookie').split(';')[0];
assert.equal((await call('/api/admin')).status,401);
assert.equal((await call('/api/admin',{headers:{'oai-authenticated-user-id':'fake','oai-authenticated-user-email':'vitorrmachado@hotmail.com'}})).status,401);
assert.equal((await call('/api/admin',{method:'POST',admin:true,origin:'https://other.example',body:{action:'settings'}})).status,403);
const initial=await call('/api/admin',{admin:true});assert.equal(initial.status,200,JSON.stringify(initial.data));
const fixture='Teste '+crypto.randomUUID();
const category=initial.data.categories[0].id;
const newProduct={name:fixture,category_id:category,price:42.5,cost:10,color:'Dourado',material:'Teste',description:'Fixture local',group_id:null,quantity:1,images:['/images/peca-3.png']};
const created=await call('/api/admin',{method:'POST',admin:true,body:{action:'products',products:[newProduct]}});assert.equal(created.status,200,JSON.stringify(created.data));
let current=(await call('/api/admin',{admin:true})).data;const product=current.products.find(p=>p.name===fixture);assert(product);assert.equal(product.quantity,1);
const checkout=()=>({request_key:crypto.randomUUID(),receipt_token:crypto.randomUUID(),name:'Cliente de teste',phone:'41988887777',delivery:'retirada',items:[{product_id:product.id,quantity:1,price_cents:4250}]});
const tampered=checkout();tampered.items[0].price_cents=1;assert.equal((await call('/api/orders',{method:'POST',body:tampered})).status,409);
assert.equal((await call('/api/admin',{admin:true})).data.products.find(p=>p.id===product.id).quantity,1);
const address=checkout();address.delivery='entrega';assert.equal((await call('/api/orders',{method:'POST',body:address})).status,400);
const a=checkout(),b=checkout();const races=await Promise.all([call('/api/orders',{method:'POST',body:a}),call('/api/orders',{method:'POST',body:b})]);assert.deepEqual(races.map(r=>r.status).sort(),[201,409]);const winner=races[0].status===201?a:b;const order=races.find(r=>r.status===201).data;assert.equal(order.total,42.5);
const repeated=await call('/api/orders',{method:'POST',body:winner});assert.equal(repeated.status,200);assert.equal(repeated.data.id,order.id);
const receipt=await call('/api/orders?token='+winner.receipt_token);assert.equal(receipt.status,200);assert.equal(receipt.data.code,order.code);assert.equal((await call('/api/orders?token='+crypto.randomUUID())).status,404);
current=(await call('/api/admin',{admin:true})).data;assert.equal(current.products.find(p=>p.id===product.id).quantity,0);assert.equal(current.orders.find(o=>o.id===order.id).items.length,1);assert(!('receipt_hash' in current.orders[0]));
const edited=await call('/api/admin',{method:'POST',admin:true,body:{action:'edit_product',...product,name:fixture,price:55.9,published:true}});assert.equal(edited.status,200,JSON.stringify(edited.data));assert.equal((await call('/api/orders?token='+winner.receipt_token)).data.total,42.5);
const paid=await call('/api/admin',{method:'POST',admin:true,body:{action:'payment',id:order.id,payment:'pago',method:'pix'}});assert.equal(paid.status,200,JSON.stringify(paid.data));
assert.equal((await call('/api/admin',{method:'POST',admin:true,body:{action:'order_status',id:order.id,status:'cancelado',expected_status:'confirmado'}})).status,400);
assert.equal((await call('/api/admin',{method:'POST',admin:true,body:{action:'payment',id:order.id,payment:'estornado',method:'pix'}})).status,200);
assert.equal((await call('/api/admin',{method:'POST',admin:true,body:{action:'order_status',id:order.id,status:'cancelado',expected_status:'confirmado'}})).status,200);
current=(await call('/api/admin',{admin:true})).data;assert.equal(current.products.find(p=>p.id===product.id).quantity,1);
assert(current.movements.some(m=>m.type==='reserva'&&m.name===fixture));assert(current.movements.some(m=>m.type==='venda'&&m.name===fixture));assert(current.movements.some(m=>m.type==='devolucao'&&m.name===fixture));
// Insufficient quantity must not leave partial orders, customers or reservations.
const count=current.orders.length;const excess=checkout();excess.items[0]={product_id:product.id,quantity:2,price_cents:5590};assert.equal((await call('/api/orders',{method:'POST',body:excess})).status,409);current=(await call('/api/admin',{admin:true})).data;assert.equal(current.orders.length,count);assert.equal(current.products.find(p=>p.id===product.id).quantity,1);
// A second order from the same phone is grouped under one customer.
const second=checkout();second.items[0].price_cents=5590;const secondResult=await call('/api/orders',{method:'POST',body:second});assert.equal(secondResult.status,201,JSON.stringify(secondResult.data));current=(await call('/api/admin',{admin:true})).data;assert.equal(current.customers.filter(c=>c.phone==='41988887777').length,1);
assert.equal((await call('/api/admin',{method:'POST',admin:true,body:{action:'order_status',id:secondResult.data.id,status:'cancelado',expected_status:'novo'}})).status,200);
// Uploads require auth and reject disguised files.
const form=new FormData();form.set('file',new Blob(['not a png'],{type:'image/png'}),'bad.png');const bad=await fetch(base+'/api/upload',{method:'POST',headers:{Origin:base,Cookie:cookie},body:form});assert.equal(bad.status,400);
assert.equal((await fetch(base+'/api/upload',{method:'POST',headers:{Origin:base},body:form})).status,401);
// Keep local fixtures out of the visible catalog after the test.
assert.equal((await call('/api/admin',{method:'POST',admin:true,body:{action:'edit_product',...product,name:fixture,price:55.9,published:false}})).status,200);
console.log('PASS: authentication, authorization, editable prices, checkout validation, concurrent last-item checkout, idempotency, receipts, immutable prices, payments, cancellations, rollback, customer grouping, stock audit, upload restrictions.');
