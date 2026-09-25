/* eslint-disable @next/next/no-html-link-for-pages -- Full document navigation is required for the hosted admin entry points. */
import AreaNav from '@/components/area-nav';

export default function Layout({children}:{children:React.ReactNode}){return <main className="admin"><header className="admin-head"><a className="brand" href="/"><img src="/images/logo.png" alt="Logo"/><span>VANESSA BOREIKO<small>ADMINISTRAÇÃO</small></span></a><AreaNav/></header>{children}</main>}


