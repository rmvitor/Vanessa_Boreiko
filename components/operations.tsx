'use client';
import {useEffect,useState,useRef} from 'react';
import Link from 'next/link';
import {Tabs,TabsList,TabsTrigger,TabsContent} from '@/components/ui/tabs';
import {AdminData} from '@/lib/admin-types';
import {Ops,saveOperation} from '@/lib/operations-types';
import {useAreaTab} from '@/lib/use-area-tab';
import InventoryLots from './inventory-lots';
import SalesDesk from './sales-desk';
import Consignments from './consignments';
import Finance from './finance';
import Records from './records';
import Labels from './labels';
import Promotions from './promotions';
export type Save=(d:unknown)=>Promise<boolean>;
export default function Operations({focused=false,lotsOnly=false}:{focused?:boolean;lotsOnly?:boolean}){const [tab,setTab]=useAreaTab('vendas',['vendas','financeiro','consignacoes','cadastros','etiquetas','promocoes','lotes']);const lock=useRef(false);const [base,setBase]=useState<AdminData|null>(null),[ops,setOps]=useState<Ops|null>(null),[busy,setBusy]=useState(false),[error,setError]=useState(''),[message,setMessage]=useState('');
 async function load(){const [a,b]=await Promise.all([fetch('/api/admin'),fetch('/api/operations')]);if(!a.ok||!b.ok)throw Error('Não foi possível carregar. Confira seu login e tente novamente.');setBase(await a.json());setOps(await b.json())}
 useEffect(()=>{Promise.resolve().then(load).catch(e=>setError(e.message))},[]);
 const save:Save=async d=>{if(lock.current)return false;lock.current=true;setBusy(true);setError('');setMessage('');try{const result=await saveOperation(d);await load();setMessage(result.code?`Registro ${result.code} concluído.`:'Alteração salva.');return true}catch(e){setError((e as Error).message);return false}finally{lock.current=false;setBusy(false)}};
 if(lotsOnly)return <section>{error&&<p className="notice error" role="alert">{error}</p>}{message&&<p className="notice success" role="status">{message}</p>}{!base||!ops?<p>Carregando lotes…</p>:<fieldset disabled={busy}><InventoryLots base={base} ops={ops} save={save}/></fieldset>}</section>;
 if(focused)return <section className="operations cashier"><header className="cashier-header"><div><span className="eyebrow">VANESSA BOREIKO</span><h1>Live & Evento</h1></div><a href="/admin">Administração ↗</a></header>{error&&<p className="notice error" role="alert">{error}</p>}{message&&<p className="notice success" role="status">{message}</p>}{!base||!ops?<p>Carregando estoque…</p>:<SalesDesk base={base} ops={ops} save={save} focused saving={busy}/>}</section>;
 return <section className="operations"><div className="admin-intro"><div><span className="eyebrow">VERSÃO BETA · GESTÃO</span><h2>O dia a dia da loja.</h2></div><Link href="/admin" className="secondary-button">Produtos e pedidos</Link></div><Tabs value={tab} onValueChange={v=>{setTab(v);setError('');setMessage('')}}><TabsList className="admin-tabs">{[['vendas','Vendas / Evento'],['financeiro','Financeiro & relatórios'],['consignacoes','Revendedoras & consignações'],['cadastros','Clientes & peças'],['lotes','Lotes & estoque'],['etiquetas','Códigos & etiquetas'],['promocoes','Cupons & kits']].map(([v,n])=><TabsTrigger key={v} value={v}>{n}</TabsTrigger>)}</TabsList>{error&&<p className="notice error" role="alert">{error} <button onClick={()=>load().catch(e=>setError(e.message))}>Atualizar</button></p>}{message&&<p className="notice success" role="status">{message}</p>}{!base||!ops?<p>Carregando operações…</p>:<fieldset disabled={busy} className="ops-fieldset"><TabsContent value="vendas"><SalesDesk base={base} ops={ops} save={save} saving={busy}/></TabsContent><TabsContent value="lotes"><InventoryLots base={base} ops={ops} save={save}/></TabsContent><TabsContent value="financeiro"><Finance base={base} ops={ops} save={save}/></TabsContent><TabsContent value="consignacoes"><Consignments base={base} ops={ops} save={save}/></TabsContent><TabsContent value="cadastros"><Records base={base} ops={ops} save={save}/></TabsContent><TabsContent value="etiquetas"><Labels base={base} ops={ops} save={save}/></TabsContent><TabsContent value="promocoes"><Promotions base={base} ops={ops} save={save}/></TabsContent></fieldset>}</Tabs></section>;
}

