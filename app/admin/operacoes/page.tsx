import {getAdmin} from '@/lib/auth';
import Operations from '@/components/operations';
export const dynamic='force-dynamic';
export default async function Page(){if(!await getAdmin())return <p>Acesso restrito. <a href="/signin-with-chatgpt?return_to=/admin/operacoes" target="_top">Entrar com ChatGPT</a></p>;return <Operations/>}
