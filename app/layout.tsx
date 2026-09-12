import type { Metadata } from 'next';
import './globals.css';
export const metadata:Metadata={title:'Vanessa Boreiko | Acessórios que encantam',description:'Brincos, colares e pulseiras para expressar o seu jeito de brilhar.',icons:{icon:'/images/logo.png'}};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="pt-BR"><body>{children}</body></html>}
