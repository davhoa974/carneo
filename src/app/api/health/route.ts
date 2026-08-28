import { checkSupabaseHealth } from "@/lib/supabase/health";

/**
 * Sonde de santé : prouve que l'application déployée parle réellement à son
 * projet Supabase. Jamais mise en cache, sinon elle rapporterait l'état d'un
 * déploiement précédent.
 */
export const dynamic = "force-dynamic";

export async function GET() {
  const health = await checkSupabaseHealth();

  const body = health.ok
    ? { status: "ok", supabase: "ok", latency_ms: health.latencyMs }
    : {
        status: "error",
        supabase: "error",
        latency_ms: health.latencyMs,
        reason: health.reason,
      };

  return Response.json(body, {
    status: health.ok ? 200 : 503,
    headers: { "Cache-Control": "no-store" },
  });
}
