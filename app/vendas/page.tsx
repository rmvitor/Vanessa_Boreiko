import {getAdmin} from '@/lib/auth';
import Operations from '@/components/operations';
export const dynamic='force-dynamic';
export default async function Page(){if(!await getAdmin())return <main className="admin-login"><h1>Caixa de vendas</h1><p>Entre com a conta administrativa para vender em lives e eventos.</p><a className="primary" href="/signin-with-chatgpt?return_to=/vendas" target="_top">Entrar com ChatGPT</a></main>;return <main className="cashier-page"><Operations focused/></main>}
