import {getAdmin} from '@/lib/auth';
import {getChatGPTUser,chatGPTSignInPath} from '@/app/chatgpt-auth';
import Admin from '@/components/admin';
export const dynamic='force-dynamic';
export default async function Page({searchParams}:{searchParams:Promise<{tab?:string}>}){const {tab}=await searchParams;const returnTo='/admin'+(tab?'?tab='+encodeURIComponent(tab):'');const admin=await getAdmin();if(admin)return <Admin displayName={admin.fullName||'Vitor'}/>;const user=await getChatGPTUser();return <section className="admin-login"><span className="eyebrow">SEU ESPAÇO DE GESTÃO</span><h2>Bem-vinda de volta.</h2><p>{user?'Esta conta não tem permissão para administrar a loja. Entre com a conta proprietária do site.':'Acesse produtos, estoque e pedidos com sua conta do ChatGPT.'}</p><a className="primary" href={chatGPTSignInPath(returnTo)} target="_top">Entrar com ChatGPT</a></section>}
