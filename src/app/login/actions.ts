"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { createSupabaseServerClient } from "@/lib/supabase/server";

/**
 * Authentification minimale de la Phase 2. Elle existe pour qu'un vrai
 * utilisateur soit disponible face à la RLS : les écrans définitifs arrivent
 * après `/design`.
 */

/** Renvoie sur `/login` avec le motif affichable. `redirect` interrompt le flux. */
function retourAvecErreur(message: string): never {
  redirect(`/login?erreur=${encodeURIComponent(message)}`);
}

export async function connexion(formData: FormData) {
  const email = String(formData.get("email") ?? "");
  const password = String(formData.get("password") ?? "");

  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });

  if (error) {
    retourAvecErreur(error.message);
  }

  revalidatePath("/", "layout");
  redirect("/vehicules");
}

export async function inscription(formData: FormData) {
  const email = String(formData.get("email") ?? "");
  const password = String(formData.get("password") ?? "");

  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase.auth.signUp({ email, password });

  if (error) {
    retourAvecErreur(error.message);
  }

  // Une inscription sans session ouverte signifie que Supabase attend une
  // confirmation par email. C'est le comportement VOULU depuis le 29/08/2026 :
  // la confirmation a été désactivée le temps de la Phase 2 puis réactivée
  // avant la mise en ligne, pour ne pas laisser une inscription ouverte sans
  // vérification sur une URL publique. Ce n'est donc pas une anomalie à
  // réparer en la redésactivant.
  if (!data.session) {
    retourAvecErreur(
      "Compte créé. Ouvre l'email de confirmation que Supabase vient de " +
        "t'envoyer, puis reviens te connecter.",
    );
  }

  revalidatePath("/", "layout");
  redirect("/vehicules");
}

export async function deconnexion() {
  const supabase = await createSupabaseServerClient();
  await supabase.auth.signOut();

  revalidatePath("/", "layout");
  redirect("/login");
}
