# STATUS — Carneo

> Fichier maintenu UNIQUEMENT par `/close`. Ne pas éditer à la main.

<!-- close:active -->
**Dernière étape** : `/plan Phase 1` le 28/08/2026. `docs/plans/phase-1-plan.md` créé et validé (6 tâches). Cadrage tranché : pas d'auth ni de migration SQL en Phase 1 (elles partent ensemble en Phase 2, une policy RLS ne se testant ni sans utilisateur ni sans table), preuve de chaîne par une route serveur `/api/health`, déploiement Vercel branché sur un dépôt GitHub privé, Vitest reporté en Phase 3.
**Prochaine étape recommandée** : `/clear` puis `/execute docs/plans/phase-1-plan.md`. Attention à la tâche 5 : c'est David qui saisit les deux variables Supabase dans le dashboard Vercel (premier usage de la plateforme, prévoir de l'expliquer pas à pas). En parallèle, côté humain : le Prérequis hors code, extraire le plan d'entretien du carnet constructeur de la Fiesta. Il bloque la Phase 2.
**Dernier commit reflété** : `4405277` (rafraîchi au prochain `/close` de fin de phase)

## Historique récent
- 28/08/2026 : `/plan Phase 1` validé. Périmètre resserré à la plomberie (clients Supabase, route de santé, dépôt GitHub, Vercel). `/challenge` volontairement sauté sur cette phase, gardé pour la Phase 2 (schéma et RLS) et la Phase 3 (moteur d'échéances).
- 28/08/2026 : `/architect` PRD validé. Écart assumé avec le brief : l'extraction des factures par photo passe de la v2 à la V1 (Phase 5), et le lien facture-intervention est inversé (`maintenance_events.document_id`) car une visite au garage produit plusieurs interventions. Scaffold Next.js + Supabase opérationnel.
- 28/08/2026 : `/start` cadrage initial. Projet perso montrable en portfolio, baseline historique fixée à l'achat 2018 (56 000 km), contrôle technique intégré au suivi, périmètre v3 parqué.
<!-- /close:active -->
