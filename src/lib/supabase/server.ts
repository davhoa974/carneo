import { cookies } from "next/headers";
import { createServerClient } from "@supabase/ssr";

import {
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  NEXT_PUBLIC_SUPABASE_URL,
} from "@/lib/env";

/**
 * Client Supabase pour le rendu serveur (Server Components, Route Handlers,
 * Server Actions). Un client neuf par requête : il porte les cookies de
 * session de l'utilisateur courant, il ne doit jamais être partagé.
 *
 * Il utilise la clé publiable, donc il reste soumis à la RLS. La clé secrète
 * n'a aucun usage tant que la Phase 6 ne l'exige pas.
 */
export async function createSupabaseServerClient() {
  const cookieStore = await cookies();

  return createServerClient(
    NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            for (const { name, value, options } of cookiesToSet) {
              cookieStore.set(name, value, options);
            }
          } catch {
            // Appel depuis un Server Component : les cookies y sont en lecture
            // seule. Le rafraîchissement de session sera écrit par le
            // middleware, mis en place avec l'authentification (Phase 2).
          }
        },
      },
    },
  );
}
