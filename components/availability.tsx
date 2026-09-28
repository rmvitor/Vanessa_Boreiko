'use client';
import {channels} from '@/lib/channels';
export default function Availability({value,onChange}:{value:string[];onChange:(v:string[])=>void}){return <fieldset className="availability full-width"><legend>Disponibilidade</legend><p>Marque onde este cadastro pode ser oferecido. O saldo é compartilhado entre os canais.</p><div className="admin-actions">{channels.map(channel=><label key={channel}><input type="checkbox" checked={value.includes(channel)} onChange={e=>onChange(e.target.checked?[...value,channel]:value.filter(c=>c!==channel))}/>{channel}</label>)}</div></fieldset>}
