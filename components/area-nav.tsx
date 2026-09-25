'use client';
import Link from 'next/link';
import {usePathname} from 'next/navigation';
export default function AreaNav(){const path=usePathname();return <nav className="area-nav" aria-label="Áreas da loja">{[['/','Loja'],['/admin','Administração'],['/vendas','Caixa · Live e Evento'],['/admin/operacoes?tab=lotes','Lotes'],['/admin/operacoes?tab=financeiro','Financeiro'],['/revendedora','Revendedoras']].map(([href,label])=><Link key={href} href={href} aria-current={path===href?'page':undefined}>{label}</Link>)}</nav>}
