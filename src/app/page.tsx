import { checkSupabaseHealth } from "@/lib/supabase/health";

/**
 * Page de santé technique de la Phase 1 : elle prouve, depuis un navigateur,
 * que le déploiement en cours parle à Supabase. Elle sera remplacée par le
 * tableau de bord des véhicules à partir de la Phase 3.
 *
 * Rendu à chaque requête : une page de santé mise en cache rapporterait
 * l'état d'un déploiement précédent.
 */
export const dynamic = "force-dynamic";

function deployedCommit(): string {
  const sha = process.env.VERCEL_GIT_COMMIT_SHA;

  return sha ? sha.slice(0, 7) : "local (hors Vercel)";
}

export default async function Home() {
  const health = await checkSupabaseHealth();

  return (
    <main className="mx-auto flex min-h-full w-full max-w-xl flex-col justify-center gap-8 px-6 py-16">
      <header>
        <h1 className="text-3xl font-semibold tracking-tight">Carneo</h1>
        <p className="mt-2 text-sm opacity-70">
          Carnet d&apos;entretien automobile. Page de santé technique.
        </p>
      </header>

      <dl className="flex flex-col gap-4 text-sm">
        <div className="flex items-baseline justify-between gap-4 border-t pt-4">
          <dt className="opacity-70">Connexion Supabase</dt>
          <dd className="font-medium">
            {health.ok
              ? `connectee (${health.latencyMs} ms)`
              : `indisponible : ${health.reason}`}
          </dd>
        </div>

        <div className="flex items-baseline justify-between gap-4 border-t pt-4">
          <dt className="opacity-70">Commit deploye</dt>
          <dd className="font-mono font-medium">{deployedCommit()}</dd>
        </div>
      </dl>
    </main>
  );
}
