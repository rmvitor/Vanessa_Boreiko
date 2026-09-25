import AreaNav from '@/components/area-nav';
import Link from 'next/link';
export default function Layout({children}:{children:React.ReactNode}){return <main className="admin"><header className="admin-head"><Link className="brand" href="/"><img src="/images/logo.png" alt="Logo"/><span>VANESSA BOREIKO<small>ADMINISTRAÇÃO</small></span></Link><AreaNav/></header>{children}</main>}
