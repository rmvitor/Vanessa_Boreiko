import {catalog,initialize} from '@/lib/shop';
import {expireOrders} from '@/lib/database';
import {notFound} from 'next/navigation';
import ProductPage from '@/components/product-page';
export const dynamic='force-dynamic';
export default async function Page({params}:{params:Promise<{id:string}>}){const {id}=await params;await initialize();await expireOrders();const product=(await catalog()).find(p=>p.id===id);if(!product)notFound();return <ProductPage product={product}/>}
