import {getChatGPTUser} from '@/app/chatgpt-auth';
export async function getAdmin(){const user=await getChatGPTUser();if(!user)return null;const local=process.env.NODE_ENV==='development'&&user.userId==='local_seedy'&&user.email==='seedy@sites.test';return local||user.email.toLowerCase()==='vitorrmachado@hotmail.com'?user:null}
export function sameOrigin(r:Request){return r.headers.get('origin')===new URL(r.url).origin}
export function fail(error:unknown,status=400){console.error('Vanessa API:',error instanceof Error?error.message:'operation failed');return Response.json({error:status===503?'Serviço indisponível. Tente novamente em instantes.':error instanceof Error?error.message:'Não foi possível concluir a operação.'},{status})}

