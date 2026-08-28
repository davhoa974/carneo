# Plan : Phase 1, squelette technique

> PRD parent : `PRD.md` (section 7, Phase 1)
> Date : 2026-08-28
> Niveau Request Classification : FULL

## Cadrage retenu

Décisions prises au moment du `/plan`, pour éviter d'avoir à les rediscuter en cours d'exécution :

- **Pas d'authentification en Phase 1.** Une policy RLS ne se teste pas sans utilisateur connecté ni table à protéger : auth et RLS partent ensemble en Phase 2.
- **Pas de migration SQL, pas de table.** La preuve que Supabase répond passe par un appel réel à son API depuis une route serveur, pas par une table de santé qui empiéterait sur la Phase 2.
- **Pas de `/design`.** La page de cette phase est une page de santé technique, pas un écran produit. `/design` se justifie avant la Phase 3.
- **Pas de Vitest.** L'outillage de tests s'installe en Phase 3, quand le moteur d'échéances existe (conforme à `STRUCTURE.md`). Ici, la vérification c'est `lint`, `build` et `curl`.
- **Pas d'user stories Given/When/Then.** Aucun parcours utilisateur dans cette phase.

Architecture déduite : deux clients Supabase via `@supabase/ssr` (navigateur avec la clé publiable, serveur), une route serveur `/api/health` qui interroge réellement Supabase, une page serveur qui affiche cet état.

## Tâches

- [x] **1. Garde d'environnement et clients Supabase.** Créer `src/lib/env.ts` (lecture et validation des variables), `src/lib/supabase/server.ts` et `src/lib/supabase/client.ts`.
  *Fait quand* : `npm run lint` et `npx tsc --noEmit` sortent avec 0 erreur, `env.ts` exporte `NEXT_PUBLIC_SUPABASE_URL` et `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` typées `string` (et non `string | undefined`), lève une erreur nommant la variable quand elle est absente, et `grep -r "SUPABASE_SECRET_KEY" src/` ne remonte aucun résultat (la clé secrète n'a aucun usage avant la Phase 6).

- [x] **2. Route de santé `/api/health`.** Créer `src/app/api/health/route.ts` : appel réel à l'API Supabase, mesure de la latence, réponse non mise en cache.
  *Fait quand* : en local, `curl -s localhost:3000/api/health` renvoie 200 et un corps `{"status":"ok","supabase":"ok","latency_ms":<nombre>}` ; avec la clé volontairement corrompue dans `.env`, la même commande renvoie 503 avec un champ `reason` non vide ; dans les deux cas la réponse ne contient ni l'URL du projet Supabase ni le moindre fragment de clé.

- [x] **3. Page d'accueil de santé.** Remplacer le template Next.js par un composant serveur affichant le nom du projet, l'état de la connexion Supabase et le SHA du commit déployé (`VERCEL_GIT_COMMIT_SHA`).
  *Fait quand* : `npm run build` passe, la page affiche "Carneo" et un état de connexion lisible, et les cinq SVG de template (`next.svg`, `vercel.svg`, `file.svg`, `globe.svg`, `window.svg`) sont supprimés de `public/`.

- [ ] **4. Repo GitHub privé et push initial.** Vérifier le `.gitignore`, créer le dépôt distant, pousser `main`. Dépend des tâches 1 à 3.
  *Fait quand* : `git ls-files` ne contient ni `.env`, ni `tmp/`, ni `.next/`, ni `node_modules/` ; le dépôt distant est **privé** ; `git log origin/main --oneline` montre les commits locaux.

- [ ] **5. Déploiement Vercel et variables d'environnement.** Connecter le dépôt à Vercel, renseigner les deux variables publiques Supabase dans le dashboard, déclencher le premier déploiement. Dépend de la tâche 4.
  *Fait quand* : le build Vercel est vert et l'URL de production répond 200 sur `/`.
  *Répartition* : les valeurs des variables sont saisies **par David**, jamais par l'agent (règle projet, aucun secret ne transite par la conversation). La clé secrète Supabase n'est pas renseignée : elle attend la phase qui l'utilise.

- [ ] **6. Smoke test de production.** Dépend de la tâche 5.
  *Fait quand* : `curl -s https://<url-prod>/api/health` renvoie 200 avec `"supabase":"ok"` ; le sous-agent `browser-verifier` rend un verdict ✅ sur l'URL de production ; un commit vide poussé sur `main` déclenche un nouveau déploiement Vercel qui aboutit (preuve que le déploiement automatique est réellement branché, et pas seulement le premier import).

## Critère de phase complète

- [ ] Tâches 1 à 6 cochées
- [ ] L'URL de production affiche la page de santé avec Supabase "ok", depuis un navigateur mobile
- [ ] Aucun secret n'est présent dans le dépôt distant
- [ ] Un `git push` sur `main` déclenche un déploiement qui aboutit

## Hors périmètre de cette phase

Déjà fait au scaffold, ne pas refaire : Next.js 16.3.3, React 19, Tailwind 4, `tsconfig.json` en mode strict, `@supabase/ssr` et `@supabase/supabase-js` installés, `.env` rempli côté Supabase, `supabase/config.toml` présent.

Reporté : authentification et RLS (Phase 2), migrations SQL (Phase 2), Vitest (Phase 3), design system (avant Phase 3), cron Vercel et `CRON_SECRET` (Phase 7), PWA (Phase 8).

## Rappel hors code

Le **Prérequis** du PRD (extraire du carnet constructeur Ford le plan d'entretien : opérations, périodicités km et mois, criticité) bloque la Phase 2, pas celle-ci. Il peut avancer en parallèle de cette phase.

## Prochaine étape

`/execute docs/plans/phase-1-plan.md`

## Découvertes (hors plan)

- 28/08/2026 : le MCP Playwright n'est pas installé sur ce projet (aucun `.mcp.json` à la racine, aucun outil `mcp__playwright__*` exposé). Le sous-agent `browser-verifier` tombe en repli `curl`, ce qui ne couvre ni les erreurs console ni le rendu visuel. Bloque le critère "verdict ✅ du `browser-verifier`" de la tâche 6.
- 28/08/2026 : `git ls-files` remonte `tmp/.gitkeep`, ce qui est voulu par le `.gitignore` du projet (`tmp/*` ignoré, `!tmp/.gitkeep` conservé). Le critère de la tâche 4 dit "ne contient pas `tmp/`" : à lire comme "aucun contenu temporaire", le placeholder vide restant légitime.
- 28/08/2026 : `public/` est désormais vide après suppression des cinq SVG du template. Git ne suit pas les dossiers vides, donc `public/` n'existera pas sur le dépôt distant tant qu'aucun asset n'y sera ajouté (sans conséquence pour Next.js).
