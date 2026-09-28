export const channels=['Evento','Live','Site','Consignado'] as const;
export function availableIn(value:string|undefined,channel:string){try{return JSON.parse(value||'[]').includes(channel)}catch{return false}}
export function readChannels(value?:string){try{return JSON.parse(value||'[]') as string[]}catch{return []}}
