import Link from 'next/link';
export default function Layout({children}:{children:React.ReactNode}){return <main className="admin"><header className="admin-head"><Link className="brand" href="/"><img src="/images/logo.png" alt="Logo"/><span>VANESSA BOREIKO<small>ADMINISTRAÇÃO</small></span></Link><Link href="/">Ver catálogo ↗</Link></header>{children}</main>}
