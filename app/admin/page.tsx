import {adminToken,configured} from '@/lib/supabase';
import Admin from '@/components/admin';
export const dynamic='force-dynamic';
export default async function Page(){return <Admin configured={configured()} authorized={!!await adminToken()}/>}
