'use client';
import {usePathname,useSearchParams} from 'next/navigation';
export default function AreaNav(){
 const path=usePathname(),params=useSearchParams();
 const current=path+(params.get('tab')?'?tab='+params.get('tab'):'');
 return <nav className="area-nav" aria-label="Áreas da loja">{[['/','Loja'],['/admin','Administração'],['/vendas','Caixa · Live e Evento'],['/admin?tab=lotes','Lotes'],['/admin/operacoes?tab=financeiro','Financeiro'],['/revendedora','Revendedoras']].map(([href,label])=><a key={href} href={href} aria-current={current===href?'page':undefined}>{label}</a>)}</nav>
}
