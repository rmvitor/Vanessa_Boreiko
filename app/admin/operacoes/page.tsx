import {getAdmin} from '@/lib/auth';
import {chatGPTSignInPath} from '@/app/chatgpt-auth';
import Operations from '@/components/operations';
export const dynamic='force-dynamic';
export default async function Page({searchParams}:{searchParams:Promise<{tab?:string}>}){const {tab}=await searchParams;const returnTo='/admin/operacoes'+(tab?'?tab='+encodeURIComponent(tab):'');if(!await getAdmin())return <p>Acesso restrito. <a href={chatGPTSignInPath(returnTo)} target="_top">Entrar com ChatGPT</a></p>;return <Operations/>}
