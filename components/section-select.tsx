'use client';
export default function SectionSelect({value,onChange,options}:{value:string;onChange:(value:string)=>void;options:string[][]}){return <label className="section-select">Seção atual<select value={value} onChange={e=>onChange(e.target.value)}>{options.map(([id,label])=><option key={id} value={id}>{label}</option>)}</select></label>}
