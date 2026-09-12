import {env} from 'cloudflare:workers';
export function database(){if(!env.DB)throw Error('Banco de dados indisponível.');return env.DB}
export function storage(){if(!env.BUCKET)throw Error('Armazenamento indisponível.');return env.BUCKET}
export const statement=(sql:string,...args:(string|number|null)[])=>database().prepare(sql).bind(...args);
export async function all<T>(sql:string,...args:(string|number|null)[]){return (await statement(sql,...args).all<T>()).results}
export async function expireOrders(){await statement("UPDATE orders SET status='expirado',actor='sistema' WHERE status='novo' AND expires_at < strftime('%Y-%m-%dT%H:%M:%fZ','now')").run()}
export function orderCode(seq:number,created:string){return `VB-${created.slice(0,4)}-${String(seq).padStart(6,'0')}`}
export function pieceCode(seq:number){return `VB${String(seq).padStart(6,'0')}`}
