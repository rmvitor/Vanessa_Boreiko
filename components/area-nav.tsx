'use client';
import {usePathname,useSearchParams} from 'next/navigation';
const areas=[['/','Catálogo'],['/admin','Administração'],['/vendas','Caixa · Live e Evento'],['/admin?tab=lotes','Lotes'],['/admin/operacoes?tab=financeiro','Financeiro e operações'],['/revendedora','Portal da revendedora']];
export default function AreaNav(){
 const path=usePathname(),params=useSearchParams();
 const current=path==='/admin'?(params.get('tab')==='lotes'?'/admin?tab=lotes':'/admin'):path==='/admin/operacoes'?areas[4][0]:path;
 return <><nav className="area-nav" aria-label="Áreas da loja">{areas.map(([href,label])=><a key={href} href={href} aria-current={current===href?'page':undefined}>{label}</a>)}</nav><label className="mobile-area-select">Ir para outra área<select value={current} onChange={e=>window.location.assign(e.target.value)}>{areas.map(([href,label])=><option key={href} value={href}>{label}</option>)}</select></label></>;
}
