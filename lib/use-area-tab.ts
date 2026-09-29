'use client';
import {useSearchParams,useRouter,usePathname} from 'next/navigation';
export function useAreaTab(fallback:string,allowed:string[]):[string,(value:string)=>void]{const params=useSearchParams(),router=useRouter(),path=usePathname();const value=params.get('tab')||fallback;return [allowed.includes(value)?value:fallback,(next:string)=>router.push(path+'?tab='+encodeURIComponent(next),{scroll:false})]}
