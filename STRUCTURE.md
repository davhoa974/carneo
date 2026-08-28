# STRUCTURE.md — Carte d'architecture du projet

> Ce fichier est **rempli automatiquement par `/architect`** Étape 6.5 après scaffold du repo. Il est ensuite **lu par `/prime`** au début de chaque session pour charger le contexte d'architecture rapidement.
>
> Tu peux le mettre à jour à la main si tu réorganises le projet après le scaffold initial. `/architect` ne réécrit pas par-dessus si le fichier existe déjà — il appendera dans une section "Modifications post-scaffold" si tu relances l'étape 6.

## Arborescence

<!-- architect:directories -->
Les dossiers marqués *(à créer)* n'existent pas encore : ils apparaîtront à la phase indiquée. Ne pas les créer d'avance.

- `src/app/` — routes App Router. Contient aujourd'hui `layout.tsx`, `page.tsx`, `globals.css`.
- `src/components/` — composants UI *(à créer, Phase 3)*
- `src/lib/` — helpers et clients Supabase *(à créer, Phase 1)*
- `src/lib/echeances/` — moteur de calcul des échéances, fonction pure + ses tests *(à créer, Phase 3)*
- `src/types/` — types générés depuis le schéma Supabase *(à créer, Phase 2)*
- `supabase/` — `config.toml` et migrations SQL versionnées (`supabase/migrations/`, créé au premier `supabase migration new`)
- `public/` — assets statiques, plus tard les icônes PWA (Phase 8)
- `docs/plans/` — plans de phase écrits par `/plan` *(à créer)*
- `memory/` — mémoire projet (`decisions.md`, learnings), écrite par `/close`
- `tmp/` — fichiers temporaires, gitignored (screenshots de vérification, scripts ad-hoc)
<!-- /architect:directories -->

## Patterns clés

<!-- architect:patterns -->
- **React Server Components par défaut.** `use client` uniquement quand l'interactivité l'exige (formulaires, upload). Une page qui ne fait que lire reste serveur.
- **Server Actions pour les mutations.** Pas de route API pour un simple formulaire, sauf quand un tiers doit être appelé.
- **Deux clients Supabase distincts**, via `@supabase/ssr` : un client navigateur avec la clé `anon` (soumis à la RLS), un client serveur. La clé `service_role` ne quitte jamais le serveur et n'est utilisée que par le cron et le seed de démo.
- **Le moteur d'échéances est une fonction pure**, sans accès base. Elle reçoit un plan, des interventions et des relevés, elle rend des échéances classées. Les écrans et le cron appellent exactement la même fonction.
- **Une seule voie d'écriture pour les interventions.** L'extraction par photo pré-remplit le formulaire, elle n'écrit jamais directement. Aucune exception.
- **Validation aux frontières** : formulaires et sortie du modèle d'extraction. Ce qui entre en base est validé, pas supposé.
<!-- /architect:patterns -->

## Tests

<!-- architect:tests -->
- **Vitest**, fichiers `*.test.ts` co-localisés à côté de la source. Installé en Phase 3, quand il y a quelque chose à tester.
- **Priorité absolue** : `src/lib/echeances/`. C'est le coeur métier, c'est là qu'un bug fait le plus mal et qu'il est le plus difficile à voir à l'oeil.
- Cas limites à couvrir : double critère km/mois au premier atteint, absence d'intervention, intervention antérieure à la date d'achat, relevés insuffisants pour projeter, compteur qui recule.
- **Playwright** (via le MCP) pour la vérification visuelle des parcours, jamais en `file://` — toujours sur `localhost` ou l'URL déployée.
- Lancement : `npm test`
<!-- /architect:tests -->

## Conventions d'arborescence

<!-- architect:conventions -->
- Fichiers en kebab-case (`prochaines-echeances.tsx`), composants React en PascalCase.
- Migrations SQL : `supabase/migrations/{timestamp}_{description}.sql`, créées par `npx supabase migration new`. **Jamais de modification de schéma via l'interface Supabase** — le repo est la source de vérité du schéma.
- Dates au format JJ/MM/AAAA côté interface.
- Montants en EUR, TTC, pièces et main d'oeuvre confondues (décidé le 28/08/2026).
- Helpers dans `src/lib/`, types partagés dans `src/types/`.
- Pas de pop-up JavaScript (`alert`, `confirm`) : des toasts.
<!-- /architect:conventions -->

## Intégrations externes

<!-- structure:integrations -->
- **Supabase** — Auth (email/password ou magic link), PostgreSQL avec RLS active sur toutes les tables, Storage en bucket privé pour les factures. Actif dès la Phase 1.
- **Vercel** — hosting et Cron (recalcul quotidien des échéances). Branché en Phase 1, le cron en Phase 7.
- **API Claude** (`claude-opus-5`, vision + structured outputs) — extraction des factures photographiées. Phase 5.
- **Resend** — envoi des rappels d'échéance par email. Phase 7.
<!-- /structure:integrations -->

## Fichiers clés

<!-- structure:key-files -->
- `PRD.md` — les 8 sections du produit, dont les contraintes non-négociables. À relire avant toute décision de périmètre.
- `projet-carnet-entretien.md` — brief de cadrage d'origine, dont le modèle de données détaillé (§4) et les décisions du 28/08/2026 (§10).
- `src/app/layout.tsx`, `src/app/page.tsx` — entrées de l'application (encore le template Next.js par défaut).
- `tsconfig.json` — TypeScript en mode strict (`"strict": true`, ligne 7).
- `supabase/config.toml` — configuration Supabase locale.
- `.env.example` — variables d'environnement groupées par phase. Le `.env` réel est gitignored.
<!-- /structure:key-files -->

## Évolutions livrées (résumé)

<!-- structure:evolutions-summary -->
_(Maintenu par /evoluer après chaque livraison. 1 ligne par évolution livrée, lien vers `docs/specs/SPEC-{date}-{slug}.md`. Vide à l'init.)_
<!-- /structure:evolutions-summary -->
