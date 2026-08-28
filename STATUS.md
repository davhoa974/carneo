# STATUS : Carneo

> Fichier maintenu UNIQUEMENT par `/close`. Ne pas éditer à la main.

<!-- close:active -->
**Dernière étape** : `/plan Phase 2` le 28/08/2026. Le plan `docs/plans/phase-2-plan.md` découpe la phase en 8 tâches : migration du schéma, migration RLS, application sur le projet Supabase hébergé, types TypeScript générés, authentification minimale, seed local des vraies données, script d'audit RLS, preuve bout en bout depuis Next.js. Le Prérequis du PRD est levé : le carnet constructeur Ford est dépouillé et versionné dans `docs/references/plan-entretien-ford-fiesta-6-1.25-82.md`, 7 opérations plus le contrôle technique.
**Prochaine étape recommandée** : `/clear` puis `/challenge docs/plans/phase-2-plan.md`, prévu de longue date sur cette phase (niveau FULL, schéma et RLS). Trois points ouverts y attendent un arbitrage : la première échéance du contrôle technique (4 ans puis tous les 2 ans, non exprimable par un simple intervalle), la récurrence non prouvée de la courroie de distribution et du liquide de refroidissement, et l'ancrage des échéances quand aucune intervention n'est connue. Puis `/execute docs/plans/phase-2-plan.md`. Bloquant côté humain à la tâche 3 : le `project-ref` et le mot de passe de la base Supabase, saisis par David dans son terminal.
**Dernier commit reflété** : 27b2107

## Historique récent
- 28/08/2026 : `/plan Phase 2` validé, puis carnet constructeur Ford fourni et dépouillé. Bonne nouvelle pour le schéma : le couple `interval_km` et `interval_months` exprime la totalité du plan Ford (rapport constant de 12 mois pour 20 000 km), aucune colonne supplémentaire n'est requise. La « révision de base » est modélisée en une seule opération et non six.
- 28/08/2026 : Phase 1 ✅ Terminée. Dépôt GitHub public (choix assumé pour le portfolio, aucun secret versionné, push protection GitHub active), projet Vercel branché sur `main`, variables Supabase publiques saisies par David. Deux pièges Vercel consignés dans les Découvertes du plan.
- 28/08/2026 : `/plan Phase 1` validé. Périmètre resserré à la plomberie (clients Supabase, route de santé, dépôt GitHub, Vercel). `/challenge` volontairement sauté sur cette phase, gardé pour la Phase 2 (schéma et RLS) et la Phase 3 (moteur d'échéances).
- 28/08/2026 : `/architect` PRD validé. Écart assumé avec le brief : l'extraction des factures par photo passe de la v2 à la V1 (Phase 5), et le lien facture-intervention est inversé (`maintenance_events.document_id`) car une visite au garage produit plusieurs interventions. Scaffold Next.js + Supabase opérationnel.
- 28/08/2026 : `/start` cadrage initial. Projet perso montrable en portfolio, baseline historique fixée à l'achat 2018 (56 000 km), contrôle technique intégré au suivi, périmètre v3 parqué.
<!-- /close:active -->
