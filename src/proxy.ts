import { NextResponse, type NextRequest } from "next/server";
import { createServerClient } from "@supabase/ssr";

import {
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  NEXT_PUBLIC_SUPABASE_URL,
} from "@/lib/env";
import type { Database } from "@/types/database";

/**
 * Depuis Next 16 le fichier s'appelle `proxy.ts` et exporte `proxy` : le nom
 * `middleware` est déprécié.
 *
 * Deux rôles, et un seul est une garantie.
 *   1. Rafraîchir la session Supabase et réécrire les cookies. C'est utile :
 *      sans ça, un jeton expiré déconnecte l'utilisateur au milieu de sa
 *      navigation.
 *   2. Rediriger les routes applicatives vers `/login`. Ce n'est qu'un confort
 *      d'affichage : la doc Next 16 dit que cette couche n'est ni une gestion
 *      de session ni une autorisation. La garantie vient de l'appel
 *      `getUser()` fait par la page serveur, et de la RLS.
 */

const ROUTES_PROTEGEES = ["/vehicules"];

export async function proxy(request: NextRequest) {
  let response = NextResponse.next({ request });

  const supabase = createServerClient<Database>(
    NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          for (const { name, value } of cookiesToSet) {
            request.cookies.set(name, value);
          }

          response = NextResponse.next({ request });

          for (const { name, value, options } of cookiesToSet) {
            response.cookies.set(name, value, options);
          }
        },
      },
    },
  );

  // Appel obligatoire : c'est lui qui déclenche le rafraîchissement du jeton.
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { pathname } = request.nextUrl;
  const estProtegee = ROUTES_PROTEGEES.some(
    (route) => pathname === route || pathname.startsWith(`${route}/`),
  );

  if (!user && estProtegee) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    return NextResponse.redirect(url);
  }

  return response;
}

export const config = {
  matcher: [
    // Tout sauf les fichiers statiques et les images, qui n'ont pas de session
    // à rafraîchir.
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};
