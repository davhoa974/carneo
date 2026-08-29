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
  // confirmation par email. C'est le symptôme exact du prérequis P1 non tenu.
  if (!data.session) {
    retourAvecErreur(
      "Compte créé mais aucune session ouverte : la confirmation d'email est " +
        "encore active sur le projet Supabase (prérequis P1).",
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
