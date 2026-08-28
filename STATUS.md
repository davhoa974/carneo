# STATUS — Carneo

> Fichier maintenu UNIQUEMENT par `/close`. Ne pas éditer à la main.

<!-- close:active -->
**Dernière étape** : Phase 1 clôturée le 28/08/2026. `/validate docs/plans/phase-1-plan.md` rend un verdict ✅ OK sur les quatre critères de phase. Le squelette technique est en production sur `https://carneo-one.vercel.app`, la page de santé affiche Supabase connecté et le SHA déployé, et un `git push` sur `main` déclenche bien un déploiement automatique (vérifié en 30 secondes avec un commit vide).
**Prochaine étape recommandée** : `/clear` puis `/plan Phase 2` (schéma des 6 tables, RLS, migrations versionnées, types générés). Bloquant côté humain avant de commencer : le Prérequis du PRD, extraire du carnet constructeur Ford le plan d'entretien (opérations, périodicités km et mois, criticité). Sans lui, la Phase 2 n'a pas de données à modéliser. Prévoir aussi `/challenge` sur le plan de la Phase 2, volontairement sauté en Phase 1.
**Dernier commit reflété** : `29d5c3c`

## Historique récent
- 28/08/2026 : Phase 1 ✅ Terminée. Dépôt GitHub public (choix assumé pour le portfolio, aucun secret versionné, push protection GitHub active), projet Vercel branché sur `main`, variables Supabase publiques saisies par David. Deux pièges Vercel consignés dans les Découvertes du plan.
- 28/08/2026 : `/plan Phase 1` validé. Périmètre resserré à la plomberie (clients Supabase, route de santé, dépôt GitHub, Vercel). `/challenge` volontairement sauté sur cette phase, gardé pour la Phase 2 (schéma et RLS) et la Phase 3 (moteur d'échéances).
- 28/08/2026 : `/architect` PRD validé. Écart assumé avec le brief : l'extraction des factures par photo passe de la v2 à la V1 (Phase 5), et le lien facture-intervention est inversé (`maintenance_events.document_id`) car une visite au garage produit plusieurs interventions. Scaffold Next.js + Supabase opérationnel.
- 28/08/2026 : `/start` cadrage initial. Projet perso montrable en portfolio, baseline historique fixée à l'achat 2018 (56 000 km), contrôle technique intégré au suivi, périmètre v3 parqué.
<!-- /close:active -->
