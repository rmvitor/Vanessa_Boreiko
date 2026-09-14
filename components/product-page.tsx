'use client';
import {useState} from 'react';
import Link from 'next/link';
import {Product,money} from '@/lib/catalog';
import {Barcode} from './labels';
export default function ProductPage({product:p}:{product:Product}){const [photo,setPhoto]=useState(0),[message,setMessage]=useState('');const url='https://vanessa-boreiko-acessorios.vitorrmachado.chatgpt.site/produto/'+p.id;
 return <main className="product-page"><Link href="/">← Voltar à coleção</Link><div className="product-page-grid"><section><img className="product-full-image" src={p.images?.[photo]||p.image} alt={p.name}/><div className="image-thumbs">{p.images?.map((image,i)=><button aria-label={'Foto '+(i+1)} onClick={()=>setPhoto(i)} key={image}><img src={image} alt=""/></button>)}</div></section><section><span className="eyebrow">{p.category} · {p.collection}</span><h1>{p.name}</h1><h2>{money(p.price)}</h2><p>{p.description}</p><p>{p.color} · {p.material}</p><p>{p.quantity>0?p.quantity+' peça(s) disponível(is)':'Esgotado'}</p><Link className="primary" href={'/?produto='+p.id+'#catalogo'}>Ver na loja e adicionar à sacola</Link><button className="secondary-button" onClick={async()=>{try{await navigator.clipboard.writeText(url);setMessage('Link copiado.')}catch{setMessage(url)}}}>Copiar link da peça</button><p role="status">{message}</p><details><summary>QR Code da peça</summary><Barcode qr code={url}/></details></section></div></main>;
}
