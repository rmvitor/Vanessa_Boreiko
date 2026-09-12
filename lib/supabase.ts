import {env} from 'cloudflare:workers';
import {cookies} from 'next/headers';
type Config={SUPABASE_URL?:string;SUPABASE_ANON_KEY?:string};
export function config(){const e=env as unknown as Config;return {url:e.SUPABASE_URL||process.env.SUPABASE_URL,key:e.SUPABASE_ANON_KEY||process.env.SUPABASE_ANON_KEY}}
export const configured=()=>{const c=config();return !!(c.url&&c.key)};
export async function sb<T=unknown>(path:string,init:RequestInit={},token?:string){const c=config();if(!c.url||!c.key)throw Error('Supabase não configurado');const r=await fetch(c.url+path,{...init,headers:{apikey:c.key,Authorization:`Bearer ${token||c.key}`,...init.headers},cache:'no-store'});if(!r.ok)throw Error('Não foi possível concluir a operação. Confira os dados e a configuração.');return r.status===204?({} as T):r.json() as Promise<T>;}
export async function adminToken(){const token=(await cookies()).get('vb_session')?.value;if(!token||!configured())return null;try{const user=await sb<{id:string}>('/auth/v1/user',{},token);const rows=await sb<{user_id:string}[]>(`/rest/v1/admin_users?user_id=eq.${encodeURIComponent(user.id)}&select=user_id`,{},token);return rows.length?token:null}catch{return null}}
export function sameOrigin(r:Request){const origin=r.headers.get('origin');return !!origin&&origin===new URL(r.url).origin}

