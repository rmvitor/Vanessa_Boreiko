import type { Metadata } from 'next';
import './globals.css';
import Pwa from '@/components/pwa';
export const metadata:Metadata={manifest:'/manifest.webmanifest',title:'Vanessa Boreiko | Acessórios que encantam',description:'Brincos, colares e pulseiras para expressar o seu jeito de brilhar.',icons:{icon:'/images/logo.png'}};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="pt-BR"><body><Pwa/>{children}</body></html>}
