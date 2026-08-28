# Décisions d'architecture du projet

> Ce fichier a deux usages :
>
> 1. **ADR fondateurs/architecturaux numérotés** (écrits par `/architect` Étape 6.6 ADR-001 + `/evoluer` Étape 5f si choix significatif). Format strict, idempotent (ne réécrit pas un ADR existant).
> 2. **Harvest libre** (écrit par `/close` lors du harvest learnings, zone `<!-- close:decisions -->` ci-dessous, format bullet libre).
>
> Les deux coexistent : ADR numérotés en tête (rigueur), bullets en bas (rapidité).

## ADR — Architecture Decision Records

> Format : `ADR-NNN — {Titre court}` puis bloc `Status / Date / Context / Decision / Consequences`. Status ∈ {Accepted, Superseded, Deprecated}. Numérotation strictement incrémentale, jamais réutilisée.

<!-- ADR-NNN entries appended here by /architect (Étape 6.6) and /evoluer (Étape 5f) -->

### ADR-001 — Stack Next.js + Supabase + Vercel pour Carneo

**Status** : Accepted
**Date** : 2026-08-28
**Context** : Carnet d'entretien automobile personnel (`project_type: webapp`, niveau FULL), cadré par `projet-carnet-entretien.md`. Objectif double : un outil réellement utilisé sur une Ford Fiesta 2014, et un projet montrable en portfolio. Toute la donnée est saisie par l'utilisateur, aucune API tierce de données véhicule. Besoin d'auth, de PostgreSQL avec isolation par utilisateur, de stockage privé de factures, et d'une tâche planifiée.
**Decision** : Next.js 16 (App Router) + TypeScript strict + Tailwind 4 en front. Supabase pour l'auth, PostgreSQL (RLS active sur toutes les tables) et le Storage privé. Vercel pour l'hébergement et le cron. Resend pour l'email (Phase 7). API Claude `claude-opus-5` pour l'extraction des factures (Phase 5). Vitest sur le moteur d'échéances, Playwright sur les parcours.
**Consequences** :
- ✅ Un seul service (Supabase) couvre auth, base relationnelle et fichiers : moins de pièces à assembler pour une personne seule.
- ✅ Le SQL et la RLS appris ici sont transférables ailleurs, contrairement à un backend-as-a-service propriétaire.
- ✅ Migrations versionnées dans le repo : le schéma est relisible et défendable à l'oral, ce qui était un objectif explicite.
- ⚠️ Le kit occupait déjà la racine du dépôt : `create-next-app` a dû être scaffoldé dans `/tmp` puis rapatrié, en excluant `README.md`, `.gitignore`, `AGENTS.md` et `CLAUDE.md` qu'il aurait écrasés. À refaire de la même manière si le scaffold est rejoué.
- ⚠️ Dépendance à Vercel pour le cron. Si l'hébergement change, le déclencheur de la Phase 7 est à réimplémenter (les Edge Functions Supabase sont l'alternative connue).

### ADR-002 — L'extraction par photo pré-remplit un formulaire, elle n'écrit jamais en base

**Status** : Accepted
**Date** : 2026-08-28
**Context** : La saisie principale des interventions se fait en photographiant une facture (décidé pendant `/architect`, en écart avec le §10.6 du brief qui parquait l'OCR en v2). Se posait la question de savoir si l'extraction constituait une voie d'écriture autonome, parallèle à la saisie manuelle.
**Decision** : Non. La photo pré-remplit le formulaire d'intervention existant, l'utilisateur revoit et corrige, puis enregistre. Une seule voie d'écriture. L'extraction brute est conservée en base (`ocr_data`) pour rejouer une correspondance sans rappeler l'API. Corollaire de modélisation : le lien facture-intervention est porté par `maintenance_events.document_id` et non par `documents.maintenance_event_id` comme le prévoyait le §4 du brief, car une visite au garage produit une facture mais plusieurs interventions.
**Consequences** :
- ✅ Une extraction fausse sur un montant ou une date ne peut pas entrer silencieusement en base et fausser le moteur d'échéances. C'était le risque le plus dangereux du projet, parce qu'une date fausse mais plausible ne se voit pas.
- ✅ Une seule validation, un seul jeu de tests, un seul chemin à auditer.
- ✅ Le formulaire manuel de la Phase 4 devient le substrat de la Phase 5 : il est construit une fois et sert aux deux.
- ⚠️ Reprendre huit ans d'historique demande une relecture par facture. C'est le prix de la fiabilité, et c'est très inférieur à une ressaisie complète.
- ⚠️ L'écran de revue doit distinguer visuellement les champs issus de l'extraction de ceux saisis à la main, sinon la relecture devient machinale et la garantie disparaît.

## Décisions (harvest libre)

<!-- close:decisions -->
{Vide au démarrage. Premier exemple après quelques sessions :

- **2026-05-15** — BDD : Supabase au lieu de Neon. Rationale : Auth + BDD + Realtime en un, RLS native, gratuit jusqu'à 500 MB suffisant pour le MVP.
- **2026-05-22** — Hosting : Vercel au lieu de Netlify. Rationale : meilleure intégration Next.js, déploiement preview par PR, gratuit pour projet perso.
- **2026-06-01** — Email transactionnel : Resend. Rationale : DX moderne (React Email), 3000 emails/mois gratuit, dépendance minimale.}
<!-- /close:decisions -->
