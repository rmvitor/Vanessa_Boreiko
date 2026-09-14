import {couponDiscount} from '@/lib/coupons';
import {z} from 'zod';
export async function GET(r:Request){try{const p=new URL(r.url).searchParams;const code=z.string().max(30).parse(p.get('code')),total=z.coerce.number().int().min(1).max(1000000000).parse(p.get('total'));return Response.json({discount:await couponDiscount(code,total)},{headers:{'Cache-Control':'no-store'}})}catch(e){return Response.json({error:e instanceof Error?e.message:'Cupom inválido.'},{status:400})}}
