import { createBrowserClient } from "@supabase/ssr";

import type { Database } from "@/types/database";

import {
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  NEXT_PUBLIC_SUPABASE_URL,
} from "@/lib/env";

/**
 * Client Supabase pour le navigateur (Client Components). Il lit et écrit la
 * session dans les cookies, ce qui la rend visible du serveur : c'est la
 * contrepartie de `createSupabaseServerClient`.
 */
export function createSupabaseBrowserClient() {
  return createBrowserClient<Database>(
    NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  );
}
