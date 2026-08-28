<!--
PRD vivant discipliné. Cap 100 lignes hard.
Mis à jour par /evoluer (déplace checkboxes Hors scope → Scope actuel, append Implementation Phases).
JAMAIS réécrit destructivement.
-->

# PRD — Carneo

> **Niveau Request Classification** : FULL
> **Source de cadrage** : `projet-carnet-entretien.md` (brief du 28/08/2026, §10 fait foi en cas de contradiction, sauf sur l'extraction par photo tranchée ici en V1)

## 1. Vision

Carneo répond à une question qu'un propriétaire de véhicule ne sait pas trancher seul : qu'est-ce qui est dû maintenant sur ma voiture, et quand. L'application croise le plan d'entretien constructeur, les interventions réellement effectuées et le rythme kilométrique observé pour produire une liste d'échéances classées par urgence. Elle assume les zones d'ombre plutôt que de les masquer : ce qui est inconnu est affiché comme inconnu. La saisie se fait principalement en photographiant une facture, jamais en retapant un historique.

## 2. Personas

- **Le propriétaire suiveur (David, cas de référence)** — particulier, une Ford Fiesta 2014 achetée d'occasion en 2018. Consulte depuis son téléphone, photographie ses factures au retour du garage. Douleur : aucune visibilité sur ce qui a été fait ni sur ce qui est dû, et huit ans de factures qu'il refuse de ressaisir à la main.
- **Le visiteur de démonstration** — recruteur, prospect ou pair technique. Arrive par un lien public, veut comprendre le produit en moins de deux minutes sans créer de compte. Douleur : un écran de connexion nu ne montre rien.

## 3. Scope actuel (V1)

### Core
- [ ] Créer et éditer plusieurs véhicules par utilisateur (dont `first_registration_date` et `purchase_price`)
- [ ] Rattacher un plan d'entretien à un véhicule (plan indépendant du véhicule, réutilisable)
- [ ] Saisir, corriger et supprimer des relevés kilométriques datés, avec alerte si un relevé fait reculer le compteur
- [ ] Saisir, corriger et supprimer des interventions (date, km, coût TTC global, garage, notes)
- [ ] Uploader une facture depuis l'appareil photo du téléphone, bucket privé, accès par URL signée
- [ ] Extraction par photo : la facture pré-remplit le formulaire d'intervention, l'utilisateur revoit et corrige avant enregistrement
- [ ] Une facture produit une ou plusieurs interventions (une visite garage = vidange + filtre + plaquettes), chacune rattachable à une opération du plan
- [ ] Écran des prochaines échéances : double critère km/mois au premier atteint, trois états (à jour ou en retard / à faire / inconnu à vérifier)
- [ ] Projection de la date d'atteinte d'un seuil kilométrique à partir du rythme observé
- [ ] Contrôle technique suivi comme opération `réglementaire`, sur la date uniquement
- [ ] Compte de démonstration à données fictives, accessible sans inscription, en lecture seule
- [ ] Rappel email des échéances proches, envoyé par un cron quotidien

### Technique
- [ ] Auth Supabase + RLS active sur toutes les tables, buckets Storage privés
- [ ] Lien facture-intervention porté par `maintenance_events.document_id` (une facture, N interventions), et non l'inverse
- [ ] Extraction vision via l'API Claude (`claude-opus-5`, structured outputs) appelée depuis une route serveur Next.js, clé jamais exposée au navigateur
- [ ] Extraction brute conservée en base (`ocr_data`, `ocr_status`) pour rejouer une correspondance sans rappeler ni repayer l'API
- [ ] Migrations SQL versionnées dans le repo, aucune modification de schéma via l'interface Supabase
- [ ] TypeScript strict, types de base générés depuis le schéma Supabase
- [ ] Moteur d'échéances = fonction TypeScript pure, sans accès base, couverte par des tests
- [ ] Envoi de rappel derrière une interface unique, canal remplaçable sans réécriture
- [ ] PWA installable : manifest, icônes, service worker

## 4. Hors scope (différé)

- [ ] Coût de possession réel au kilomètre (v3, §7.1) — `purchase_price` est saisi dès la V1, rien ne l'exploite avant
- [ ] Analyse de devis de garage (v3, §7.3) — devient peu coûteuse une fois l'extraction en place, mais suppose un historique déjà dense pour dire quoi que ce soit d'utile
- [ ] Aide à la décision réparer ou revendre (v3, §7.2) — dépend d'une cote saisie manuellement, jamais estimée par calcul
- [ ] Suivi carburant et détection d'anomalies de consommation (v3, §7.4) — bien traité par les applications existantes, ne sert pas l'écran principal
- [ ] Notifications push web — reportées, capricieuses sur iOS
- [ ] Plusieurs plans d'entretien par véhicule — évolution connue si l'impureté du contrôle technique dans le plan constructeur devient gênante

## 5. Constraints non-négociables

- Toute la donnée est saisie par l'utilisateur, depuis ses propres documents. Aucune API tierce de données véhicule, aucun scraping.
- **Aucune donnée extraite d'une photo n'est écrite en base sans revue humaine.** La photo pré-remplit un formulaire, elle ne le valide pas. Une seule voie d'écriture pour les interventions, qu'elles viennent d'une photo ou d'une saisie.
- RLS active sur toutes les tables, sans exception. Un utilisateur ne voit que ses propres données.
- Le moteur de calcul des échéances est une fonction pure sans accès base. Les écrans et le cron consomment exactement la même fonction.
- Aucune date d'échéance projetée n'est affichée sans au moins 3 relevés couvrant 60 jours. En dessous, l'écran affiche les kilomètres restants et la mention explicite que le rythme n'est pas encore mesurable.
- Le schéma évolue uniquement par migration SQL versionnée et committée.
- Le compte de démonstration ne contient aucune donnée réelle et n'autorise aucune écriture.
- Une phase se termine par `/validate` avant que la suivante ne se discute. Toute idée surgie en cours de route passe par `/evoluer`.

## 6. Success Criteria

- À la fin de la Phase 3, l'application dit sur la Fiesta quelque chose que son propriétaire ne savait pas (jalon de vérité du brief).
- Les trois états d'échéance sont rendus correctement, dont l'état « inconnu, à faire vérifier » sur la courroie de distribution.
- Le moteur d'échéances passe une suite de tests couvrant : double critère km/mois, absence d'intervention, historique antérieur à l'achat, relevés insuffisants pour projeter.
- L'historique 2018-2026 est repris en photographiant les factures, sans ressaisie complète. Une facture multi-prestations produit bien N interventions distinctes.
- Un audit RLS ne trouve aucune table lisible ou modifiable par un autre utilisateur, et aucun document accessible sans URL signée.
- Un visiteur non inscrit atteint l'écran des échéances du compte de démonstration en moins de deux minutes.
- L'application est installable sur l'écran d'accueil d'un téléphone et s'ouvre en plein écran.

## 7. Implementation Phases

- **Prérequis (hors code)** — Extraire du carnet constructeur Ford le plan d'entretien complet : opérations, périodicités km et mois, criticité. Cadre tout le reste.
- **Phase 1** — Squelette technique : Next.js + TypeScript strict + Tailwind, Supabase connecté, déployé sur Vercel, une page. Chaîne complète validée avant toute logique métier.
- **Phase 2** — Schéma et données réelles : 6 tables, RLS, migrations versionnées, types générés, saisie à la main du véhicule et des interventions récentes nécessaires pour éprouver le modèle.
- **Phase 3** — Lecture et moteur d'échéances ⭐ : fonction pure testée, vue véhicule, historique, écran des prochaines échéances. Jalon de vérité.
- **Phase 4** — Écriture manuelle : formulaires intervention et relevé, upload de facture, correction et suppression. C'est le substrat que la Phase 5 pré-remplira.
- **Phase 5** — Extraction par photo ⭐ : route serveur d'extraction, écran de revue des interventions proposées, rattachement aux opérations du plan, puis reprise de tout l'historique 2018-2026.
- **Phase 6** — Compte de démonstration : jeu de données fictives, accès public en lecture seule.
- **Phase 7** — Rappels : cron quotidien qui rejoue le moteur et envoie un email via une interface d'envoi remplaçable.
- **Phase 8** — PWA : manifest, icônes, service worker, installabilité vérifiée sur mobile.

## 8. Risks & Mitigations

- **Risque** : une extraction fausse sur un montant ou une date entre en base et fausse silencieusement le moteur d'échéances, sans jamais paraître anormale → **Mitigation** : revue humaine obligatoire avant écriture (contrainte §5), champs issus de l'extraction visuellement distingués des champs saisis dans l'écran de revue.
- **Risque** : le modèle de données se révèle faux une fois confronté à l'historique réel, après que les écrans sont construits dessus → **Mitigation** : Phase 2 saisit de vraies interventions avant la moindre ligne d'écran, quand corriger le schéma coûte encore une migration.
- **Risque** : la projection kilométrique affiche des dates fausses avec l'aplomb d'une certitude → **Mitigation** : seuil de 3 relevés sur 60 jours inscrit en contrainte, fenêtre glissante de 12 mois, état explicite quand la donnée manque.
- **Risque** : le scope glisse vers les fonctionnalités v3, plus séduisantes que l'écran principal → **Mitigation** : critère de tri unique, est-ce que ça sert l'écran des prochaines échéances. Le reste est en §4 et passe par `/evoluer`.
- **Risque** : une régression silencieuse du moteur d'échéances, invisible à l'œil sur un écran plausible → **Mitigation** : fonction pure, tests unitaires sur les cas limites, `/challenge` systématique avant `/execute` (niveau FULL).
- **Risque** : le compte de démonstration expose des données réelles ou devient modifiable par un visiteur → **Mitigation** : jeu fictif dédié, lecture seule appliquée par des policies RLS distinctes, vérifiée en audit Phase 6.
- **Risque** : la règle du contrôle technique évolue ou est mal transcrite → **Mitigation** : revérification sur service-public.fr avant implémentation, périodicité stockée en donnée (`interval_months`), pas en code.
