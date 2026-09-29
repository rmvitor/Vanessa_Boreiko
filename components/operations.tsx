'use client';
import {useEffect,useState,useRef} from 'react';
import {Tabs,TabsList,TabsTrigger,TabsContent} from '@/components/ui/tabs';
import {AdminData} from '@/lib/admin-types';
import {Ops,saveOperation} from '@/lib/operations-types';
import {useAreaTab} from '@/lib/use-area-tab';
import InventoryLots from './inventory-lots';
import SectionSelect from './section-select';
import SalesDesk from './sales-desk';
import Consignments from './consignments';
import Finance from './finance';
import Records from './records';
import Labels from './labels';
import Promotions from './promotions';
import EventSessions from './event-sessions';
import Routines from './routines';
export type Save=(d:unknown)=>Promise<boolean>;
export default function Operations({focused=false,lotsOnly=false}:{focused?:boolean;lotsOnly?:boolean}){const [tab,setTab]=useAreaTab('vendas',['rotinas','sessoes','vendas','financeiro','consignacoes','cadastros','etiquetas','promocoes','lotes']);const lock=useRef(false);const [base,setBase]=useState<AdminData|null>(null),[ops,setOps]=useState<Ops|null>(null),[busy,setBusy]=useState(false),[error,setError]=useState(''),[message,setMessage]=useState('');
 async function load(){const [a,b]=await Promise.all([fetch('/api/admin'),fetch('/api/operations')]);if(!a.ok||!b.ok)throw Error('Não foi possível carregar. Confira seu login e tente novamente.');setBase(await a.json());setOps(await b.json())}
 useEffect(()=>{Promise.resolve().then(load).catch(e=>setError(e.message))},[]);
 const sectionOptions=[['rotinas','Rotinas da loja'],['sessoes','Abertura e fechamento'],['vendas','Vendas de live e evento'],['financeiro','Financeiro e relatórios'],['consignacoes','Consignações'],['cadastros','Clientes e peças'],['lotes','Lotes e estoque'],['etiquetas','Códigos e etiquetas'],['promocoes','Cupons e kits']];
 const save:Save=async d=>{if(lock.current)return false;lock.current=true;setBusy(true);setError('');setMessage('');try{const result=await saveOperation(d);await load();setMessage(result.message?result.message:result.code?`Registro ${result.code} concluído.`:'Alteração salva.');return true}catch(e){setError((e as Error).message);return false}finally{lock.current=false;setBusy(false)}};
 if(lotsOnly)return <section className="operations lot-management">{error&&<p className="notice error" role="alert">{error}</p>}{message&&<p className="notice success" role="status">{message}</p>}{!base||!ops?<p>Carregando lotes…</p>:<fieldset className="ops-fieldset" disabled={busy}><InventoryLots base={base} ops={ops} save={save}/></fieldset>}</section>;
 if(focused)return <section className="operations cashier"><header className="cashier-header"><div><span className="eyebrow">VANESSA BOREIKO</span><h1>Live e Evento</h1></div><a href="/admin">Administração</a></header>{error&&<p className="notice error" role="alert">{error}</p>}{message&&<p className="notice success" role="status">{message}</p>}{!base||!ops?<p>Carregando estoque…</p>:<SalesDesk base={base} ops={ops} save={save} focused saving={busy}/>}</section>;
 return <section className="operations"><div className="admin-intro"><div><span className="eyebrow">VERSÃO BETA · GESTÃO</span><h2>O dia a dia da loja.</h2></div><a href="/admin" className="secondary-button">Produtos e pedidos</a></div><Tabs value={tab} onValueChange={v=>{setTab(v);setError('');setMessage('')}}><SectionSelect value={tab} onChange={v=>{setTab(v);setError('');setMessage('')}} options={sectionOptions}/><TabsList className="admin-tabs">{sectionOptions.map(([v,n])=><TabsTrigger key={v} value={v}>{n}</TabsTrigger>)}</TabsList>{error&&<p className="notice error" role="alert">{error} <button onClick={()=>load().catch(e=>setError(e.message))}>Atualizar</button></p>}{message&&<p className="notice success" role="status">{message}</p>}{!base||!ops?<p>Carregando operações…</p>:<fieldset disabled={busy} className="ops-fieldset"><TabsContent value="rotinas"><Routines ops={ops} save={save}/></TabsContent><TabsContent value="sessoes"><EventSessions base={base} ops={ops} save={save}/></TabsContent><TabsContent value="vendas"><SalesDesk base={base} ops={ops} save={save} saving={busy}/></TabsContent><TabsContent value="lotes"><InventoryLots base={base} ops={ops} save={save}/></TabsContent><TabsContent value="financeiro"><Finance base={base} ops={ops} save={save}/></TabsContent><TabsContent value="consignacoes"><Consignments base={base} ops={ops} save={save}/></TabsContent><TabsContent value="cadastros"><Records base={base} ops={ops} save={save}/></TabsContent><TabsContent value="etiquetas"><Labels base={base} ops={ops} save={save}/></TabsContent><TabsContent value="promocoes"><Promotions base={base} ops={ops} save={save}/></TabsContent></fieldset>}</Tabs></section>;
}

