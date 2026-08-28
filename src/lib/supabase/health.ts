import {
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  NEXT_PUBLIC_SUPABASE_URL,
} from "@/lib/env";

/** Au-delà, on considère le projet Supabase injoignable. */
const TIMEOUT_MS = 5_000;

export type SupabaseHealth =
  | { ok: true; latencyMs: number }
  | { ok: false; latencyMs: number; reason: string };

/**
 * Vérifie que le projet Supabase répond et que la clé publiable est acceptée.
 *
 * L'endpoint `/auth/v1/health` est le seul point d'entrée qui valide la clé
 * sans dépendre d'une table : il renvoie 200 avec une clé valide et 401 avec
 * une clé corrompue. C'est donc une preuve de bout en bout de la chaîne
 * application vers Supabase, sans anticiper le schéma de la Phase 2.
 *
 * Le motif d'échec est construit à partir d'un vocabulaire fixe : ni l'URL du
 * projet ni le moindre fragment de clé ne doit pouvoir remonter dans une
 * réponse HTTP, y compris via le message d'une erreur réseau.
 */
export async function checkSupabaseHealth(): Promise<SupabaseHealth> {
  const startedAt = performance.now();

  try {
    const response = await fetch(`${NEXT_PUBLIC_SUPABASE_URL}/auth/v1/health`, {
      headers: { apikey: NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY },
      cache: "no-store",
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });

    const latencyMs = Math.round(performance.now() - startedAt);

    if (!response.ok) {
      return {
        ok: false,
        latencyMs,
        reason:
          response.status === 401
            ? "cle Supabase refusee (401)"
            : `reponse inattendue de Supabase (${response.status})`,
      };
    }

    return { ok: true, latencyMs };
  } catch {
    return {
      ok: false,
      latencyMs: Math.round(performance.now() - startedAt),
      reason: "Supabase injoignable (reseau ou delai depasse)",
    };
  }
}
