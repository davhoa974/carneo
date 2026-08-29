import { connexion, inscription } from "./actions";

/** Page volontairement non stylée : elle sert la Phase 2, pas l'utilisateur final. */
export default async function PageConnexion({ searchParams }: PageProps<"/login">) {
  const { erreur } = await searchParams;
  const message = Array.isArray(erreur) ? erreur[0] : erreur;

  return (
    <main className="p-8">
      <h1 className="text-xl font-bold">Carneo, connexion</h1>

      {message ? (
        <p role="alert" className="mt-4 border border-current p-2">
          {message}
        </p>
      ) : null}

      <form className="mt-4 flex max-w-sm flex-col gap-2">
        <label htmlFor="email">Email</label>
        <input
          id="email"
          name="email"
          type="email"
          required
          autoComplete="email"
          className="border border-current p-1"
        />

        <label htmlFor="password">Mot de passe</label>
        <input
          id="password"
          name="password"
          type="password"
          required
          minLength={6}
          autoComplete="current-password"
          className="border border-current p-1"
        />

        <div className="mt-2 flex gap-2">
          <button formAction={connexion} className="border border-current p-2">
            Se connecter
          </button>
          <button formAction={inscription} className="border border-current p-2">
            Créer un compte
          </button>
        </div>
      </form>
    </main>
  );
}
