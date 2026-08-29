import { redirect } from "next/navigation";

import { createSupabaseServerClient } from "@/lib/supabase/server";
import { deconnexion } from "@/app/login/actions";

/**
 * Preuve de bout en bout de la Phase 2 : le schéma, la RLS, les types générés
 * et l'authentification, tous traversés par une seule page serveur.
 *
 * La garde tient ici, dans la page elle-même. `proxy.ts` redirige aussi, mais
 * la doc Next 16 est explicite : cette couche n'est pas une solution
 * d'autorisation. Retirer le proxy ne doit rien changer au comportement.
 *
 * La lecture passe par le client serveur, donc par la clé publiable, donc par
 * la RLS. La clé secrète n'apparaît nulle part : ce que cette page affiche est
 * exactement ce que la base accepte de montrer à cet utilisateur.
 *
 * Volontairement non stylée. Les écrans définitifs viendront après `/design`.
 */

/** JJ/MM/AAAA, la convention du projet. */
function formatDate(iso: string | null): string {
  if (!iso) return "inconnue";
  const [annee, mois, jour] = iso.split("-");
  return `${jour}/${mois}/${annee}`;
}

/** « 1 234,56 EUR ». NULL veut dire inconnu, jamais zéro. */
function formatEuros(montant: number | string | null): string {
  if (montant === null) return "montant inconnu";
  return `${Number(montant).toLocaleString("fr-FR", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })} EUR`;
}

function formatKm(km: number | null): string {
  return km === null
    ? "kilométrage inconnu"
    : `${km.toLocaleString("fr-FR")} km`;
}

export default async function PageVehicules() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  const { data: vehicules, error } = await supabase
    .from("vehicles")
    .select(
      `
      id, make, model, year, engine, plate,
      first_registration_date, purchase_date, purchase_mileage,
      maintenance_plans ( name, source ),
      mileage_readings ( recorded_at, mileage ),
      maintenance_events (
        label, performed_at, mileage, cost, garage,
        plan_operations ( name )
      )
    `,
    )
    .order("created_at");

  if (error) {
    return (
      <main className="p-8">
        <h1 className="text-xl font-bold">Mes véhicules</h1>
        <p role="alert" className="mt-4 border border-current p-2">
          Lecture impossible : {error.message}
        </p>
      </main>
    );
  }

  return (
    <main className="p-8">
      <h1 className="text-xl font-bold">Mes véhicules</h1>
      <p className="mt-2">Connecté en tant que {user.email}</p>

      {vehicules.length === 0 ? (
        <p className="mt-4">Aucun véhicule.</p>
      ) : (
        vehicules.map((vehicule) => {
          // Tri côté serveur plutôt qu'en base : les volumes sont ceux d'un
          // carnet d'entretien, quelques dizaines de lignes par véhicule.
          const releves = [...vehicule.mileage_readings].sort((a, b) =>
            b.recorded_at.localeCompare(a.recorded_at),
          );
          const interventions = [...vehicule.maintenance_events].sort((a, b) =>
            b.performed_at.localeCompare(a.performed_at),
          );
          const dernierReleve = releves[0];

          return (
            <section key={vehicule.id} className="mt-6">
              <h2 className="text-lg font-bold">
                {vehicule.make} {vehicule.model} {vehicule.year}
                {vehicule.plate ? ` (${vehicule.plate})` : ""}
              </h2>
              <p>{vehicule.engine ?? "motorisation inconnue"}</p>
              <p>
                Première mise en circulation :{" "}
                {formatDate(vehicule.first_registration_date)}
              </p>
              <p>
                Achat : {formatDate(vehicule.purchase_date)} à{" "}
                {formatKm(vehicule.purchase_mileage)}
              </p>
              <p>
                Plan d&apos;entretien :{" "}
                {vehicule.maintenance_plans?.name ?? "aucun plan rattaché"}
              </p>

              <h3 className="mt-4 font-bold">
                Dernier relevé ({releves.length} au total)
              </h3>
              <p>
                {dernierReleve
                  ? `${formatKm(dernierReleve.mileage)} le ${formatDate(dernierReleve.recorded_at)}`
                  : "aucun relevé"}
              </p>

              <h3 className="mt-4 font-bold">
                Interventions ({interventions.length})
              </h3>
              <ul className="mt-2 list-disc pl-6">
                {interventions.map((intervention) => (
                  <li
                    key={`${intervention.performed_at}-${intervention.label}`}
                    className="mt-1"
                  >
                    {formatDate(intervention.performed_at)},{" "}
                    {intervention.label}, {formatKm(intervention.mileage)},{" "}
                    {formatEuros(intervention.cost)}
                    {intervention.garage ? `, ${intervention.garage}` : ""}
                    {intervention.plan_operations
                      ? ` (rattachée à « ${intervention.plan_operations.name} »)`
                      : " (hors plan)"}
                  </li>
                ))}
              </ul>
            </section>
          );
        })
      )}

      <form action={deconnexion} className="mt-8">
        <button className="border border-current p-2">Se déconnecter</button>
      </form>
    </main>
  );
}
