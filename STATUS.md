# STATUS : Carneo

> Fichier maintenu UNIQUEMENT par `/close`. Ne pas éditer à la main.

<!-- close:active -->
**Dernière étape** : `/challenge docs/plans/phase-2-plan.md` le 28/08/2026, verdict **REWORK**, corrections appliquées au plan dans la foulée. Trois trous fermés : le script d'audit RLS de la tâche 7 pouvait rendre 26 lignes vertes sans rien prouver (l'éditeur SQL de Supabase tourne en `postgres`, propriétaire des tables et porteur de `BYPASSRLS`), la tâche 5 était écrite sur `middleware.ts` déprécié depuis Next 16 alors que le projet est en 16.3.3, et la tâche 6 n'avait aucun canal d'exécution du seed (`db push` ne joue pas les seeds, il n'y a pas de stack locale). Les trois points ouverts sont tranchés : colonne `first_due_months` pour la première échéance du contrôle technique, périodicités déduites conservées mais marquées en `notes`, ancrage sur l'âge du véhicule clos côté schéma sans colonne supplémentaire.
**Prochaine étape recommandée** : `/clear` puis les trois prérequis P1 à P3 du plan, à faire par David avant toute ligne de code (10 min, aucun code) : désactiver la confirmation d'email sur le projet Supabase hébergé, tester un `INSERT` dans `auth.users` depuis l'éditeur SQL, et compter les factures et relevés réellement disponibles. Puis `/execute docs/plans/phase-2-plan.md`. Bloquant côté humain à la tâche 3 : le `project-ref` et le mot de passe de la base Supabase, saisis par David dans son terminal.
**Dernier commit reflété** : 88f631d

## Historique récent
- 28/08/2026 : `/challenge` Phase 2, verdict REWORK appliqué. Le plan passe de 78 à 110 lignes : section Prérequis ajoutée, colonnes attendues listées table par table en tâche 1, policies d'écriture rendues aux tables de plan en tâche 2, `proxy.ts` substitué à `middleware.ts` en tâche 5, harnais `set local role` plus témoin de bascule imposés à l'audit RLS en tâche 7.
- 28/08/2026 : `/plan Phase 2` validé, puis carnet constructeur Ford fourni et dépouillé. Bonne nouvelle pour le schéma : le couple `interval_km` et `interval_months` exprime la totalité du plan Ford (rapport constant de 12 mois pour 20 000 km), aucune colonne supplémentaire n'est requise. La « révision de base » est modélisée en une seule opération et non six.
- 28/08/2026 : Phase 1 ✅ Terminée. Dépôt GitHub public (choix assumé pour le portfolio, aucun secret versionné, push protection GitHub active), projet Vercel branché sur `main`, variables Supabase publiques saisies par David. Deux pièges Vercel consignés dans les Découvertes du plan.
- 28/08/2026 : `/plan Phase 1` validé. Périmètre resserré à la plomberie (clients Supabase, route de santé, dépôt GitHub, Vercel). `/challenge` volontairement sauté sur cette phase, gardé pour la Phase 2 (schéma et RLS) et la Phase 3 (moteur d'échéances).
- 28/08/2026 : `/architect` PRD validé. Écart assumé avec le brief : l'extraction des factures par photo passe de la v2 à la V1 (Phase 5), et le lien facture-intervention est inversé (`maintenance_events.document_id`) car une visite au garage produit plusieurs interventions. Scaffold Next.js + Supabase opérationnel.
<!-- /close:active -->
