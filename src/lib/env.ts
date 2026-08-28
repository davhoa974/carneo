/**
 * Garde d'environnement : centralise la lecture des variables et transforme
 * un `string | undefined` en `string` garanti, ou échoue tôt avec un message
 * qui nomme la variable fautive.
 *
 * Les accès à `process.env` sont volontairement écrits en toutes lettres :
 * Next.js n'inline dans le bundle client que les accès littéraux
 * `process.env.NEXT_PUBLIC_*`. Un accès dynamique (`process.env[nom]`)
 * renverrait `undefined` côté navigateur.
 */

function requireEnv(name: string, value: string | undefined): string {
  if (value === undefined || value.trim() === "") {
    throw new Error(
      `Variable d'environnement manquante : ${name}. ` +
        `Renseigne-la dans .env en local (voir .env.example), ` +
        `et dans les variables d'environnement de l'hébergeur en production.`,
    );
  }

  return value;
}

export const NEXT_PUBLIC_SUPABASE_URL: string = requireEnv(
  "NEXT_PUBLIC_SUPABASE_URL",
  process.env.NEXT_PUBLIC_SUPABASE_URL,
);

export const NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: string = requireEnv(
  "NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY",
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
);
