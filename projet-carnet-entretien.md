# Projet : Carnet d'entretien automobile intelligent

> Document de cadrage à fournir à Claude Code en début de projet.
> Rédigé le 28/08/2026.

---

## 1. Contexte et intention

### Pourquoi ce projet

Projet personnel de montée en compétences techniques. L'objectif n'est pas de sortir un produit vite fait, mais de construire une **application maintenable, bien architecturée, testée et déployée**, pour progresser sur :

- l'architecture applicative et la modélisation de données
- le développement assisté par IA sur une vraie codebase (pas un one-shot)
- l'infrastructure, le déploiement, l'authentification
- la qualité de code : tests, typage, structure de projet

### Le besoin réel

Aucune visibilité sur l'entretien de ma voiture. Je ne sais jamais :

- ce qui a été fait l'an dernier, ni à quel kilométrage
- ce qui est dû maintenant
- combien la voiture me coûte réellement
- où sont mes factures

Le besoin est vécu personnellement, ce qui garantit que je peux juger de la pertinence du produit sans dépendre d'un tiers.

### Contrainte structurante

**Toute la donnée est saisie par l'utilisateur.** Aucune dépendance à une API tierce, aucun scraping, aucune autorisation réglementaire. C'est un choix délibéré : ça permet d'avancer à 100 % en autonomie.

### Véhicules de test

**Ford Fiesta (2014, essence, 82 ch)** : mon véhicule, seul cas de référence pour la v1. Tout le plan d'entretien, l'historique et les tests s'appuient dessus.

Le modèle gère malgré tout **plusieurs véhicules par utilisateur dès la v1**. Pas pour un besoin immédiat, mais parce que c'est structurant : une fois l'outil validé sur la Fiesta, l'extension naturelle est d'y ajouter d'autres véhicules de l'entourage, et rétrofitter le multi-véhicules serait coûteux.

---

## 2. Périmètre fonctionnel

### v1 (MVP utilisable)

- Créer un ou plusieurs véhicules (marque, modèle, année, motorisation, date d'achat)
- Rattacher un plan d'entretien à un véhicule
- Saisir des relevés kilométriques datés
- Saisir des interventions réalisées (date, km, coût, garage, notes)
- Uploader et stocker les factures associées
- **Écran principal : les prochaines échéances**, calculées à partir du croisement plan d'entretien × interventions réalisées

### v2

- Rappels (email ou Telegram, voir §6)
- OCR sur les factures pour pré-remplir montant, date, prestations
- Suivi carburant / consommation

### v3 : fonctionnalités à forte valeur ajoutée

Voir §7. C'est là que se trouve la vraie différenciation.

---

## 3. Stack technique

| Couche | Choix | Raison |
|---|---|---|
| Front | **Next.js (App Router) + TypeScript** | Standard du marché, très documenté, le typage évite beaucoup d'erreurs en dev assisté par IA |
| Back / DB | **Supabase** | PostgreSQL réel + Auth + Storage en un seul service. Le SQL appris est transférable |
| Stockage fichiers | **Supabase Storage** | Factures et photos, buckets privés |
| Déploiement | **Vercel** | Intégration native avec Next.js, déploiement trivial |
| Tâches planifiées | **Vercel Cron** ou **Supabase Edge Functions** | Pour le calcul d'échéances et l'envoi des rappels |
| Style | **Tailwind CSS** | Cohérent avec l'écosystème Next.js |

### Livrable : PWA

L'application est un **site web installable (Progressive Web App)** :

- une seule base de code, accessible depuis mobile et desktop
- "Ajouter à l'écran d'accueil" → icône, plein écran, sans barre de navigateur
- pas d'App Store, pas de compte développeur Apple

La couche PWA (manifest + service worker) est **ajoutée après** que le cœur fonctionne. Ce n'est pas une réécriture.

> ⚠️ Limite connue : les notifications push web sont capricieuses sur iOS. Prévoir un fallback email ou Telegram pour les rappels.

---

## 4. Modèle de données

### Principe directeur

**Le plan d'entretien est indépendant du véhicule.** Un véhicule *pointe vers* un plan, il ne le contient pas. C'est ce qui permettra plus tard d'ajouter des plans pour d'autres modèles sans refactoriser.

### Tables

#### `vehicles`
Un véhicule appartenant à un utilisateur.

| Champ | Type | Note |
|---|---|---|
| `id` | uuid, PK | |
| `user_id` | uuid, FK → auth.users | |
| `maintenance_plan_id` | uuid, FK → maintenance_plans | nullable |
| `make` | text | ex. "Citroën" |
| `model` | text | ex. "Fiesta" |
| `year` | int | |
| `engine` | text | ex. "1.25 Duratec 82" |
| `fuel_type` | enum | diesel / essence / hybride / électrique |
| `purchase_date` | date | |
| `purchase_mileage` | int | km au moment de l'achat |
| `plate` | text | nullable |

> Le kilométrage courant **n'est pas** un champ ici. Il est dérivé de `mileage_readings`.

#### `maintenance_plans`
Un plan constructeur, réutilisable entre véhicules du même modèle.

| Champ | Type |
|---|---|
| `id` | uuid, PK |
| `name` | text, ex. "Ford Fiesta 2014 essence 82 ch" |
| `make`, `model`, `year_from`, `year_to`, `engine` | text / int |
| `source` | text, constructeur, saisie manuelle, etc. |

#### `plan_operations`
Les opérations prévues par un plan, avec leur périodicité.

| Champ | Type | Note |
|---|---|---|
| `id` | uuid, PK | |
| `maintenance_plan_id` | uuid, FK | |
| `name` | text | ex. "Vidange huile moteur" |
| `category` | enum | moteur / freinage / pneumatiques / filtration / contrôle |
| `interval_km` | int, nullable | ex. 20000 |
| `interval_months` | int, nullable | ex. 12 |
| `criticality` | enum | critique / recommandé / confort |
| `notes` | text | |

> **Double critère obligatoire** : les constructeurs expriment toujours les échéances en « X km **ou** Y mois, au premier des deux atteint ». La logique de calcul doit respecter ça.

#### `maintenance_events`
Les interventions réellement effectuées.

| Champ | Type |
|---|---|
| `id` | uuid, PK |
| `vehicle_id` | uuid, FK |
| `plan_operation_id` | uuid, FK, nullable, si l'intervention correspond à une opération planifiée |
| `label` | text, libellé libre si hors plan |
| `performed_at` | date |
| `mileage` | int |
| `cost` | numeric |
| `garage` | text |
| `notes` | text |

#### `mileage_readings`
Série de relevés kilométriques datés.

| Champ | Type |
|---|---|
| `id` | uuid, PK |
| `vehicle_id` | uuid, FK |
| `recorded_at` | date |
| `mileage` | int |

> **Point clé.** Stocker le kilométrage comme une série temporelle, pas comme un champ unique, permet de calculer le **rythme d'utilisation mensuel** et donc de *prédire* la date à laquelle une échéance kilométrique sera atteinte. C'est ce qui transforme un carnet passif en outil qui anticipe.

#### `documents`
Factures, photos, carnets scannés.

| Champ | Type |
|---|---|
| `id` | uuid, PK |
| `vehicle_id` | uuid, FK |
| `maintenance_event_id` | uuid, FK, nullable |
| `storage_path` | text |
| `file_name`, `mime_type`, `size` | text / int |
| `uploaded_at` | timestamptz |
| `ocr_status`, `ocr_data` | enum / jsonb, pour la v2 |

### Le cœur de la logique

```
prochaines_échéances = plan_operations (du plan du véhicule)
                       ⨯ dernière maintenance_event correspondante
                       ⨯ kilométrage projeté (depuis mileage_readings)
```

Pour chaque opération du plan :
1. trouver la dernière intervention correspondante (date + km)
2. calculer l'échéance km = km_dernière + interval_km
3. calculer l'échéance date = date_dernière + interval_months
4. retenir la plus proche des deux
5. estimer la date d'atteinte du seuil km via le rythme mensuel
6. classer par urgence

---

## 5. Sécurité et accès

- Authentification Supabase (email/password ou magic link)
- **Row Level Security activée sur toutes les tables** : un utilisateur ne voit que ses propres données
- Buckets Storage privés, accès par URL signée à durée limitée

---

## 6. Feuille de route

L'ordre est important : chaque étape valide quelque chose avant de passer à la suite.

### Étape 1 : Le plan d'entretien sur papier
**Pas de code.** Extraire du carnet constructeur de la Fiesta la liste des opérations avec leurs périodicités : vidange huile moteur + filtre à huile, filtre à air, filtre habitacle, bougies d'allumage, courroie de distribution (point critique sur cette motorisation), liquide de frein, plaquettes et disques, liquide de refroidissement, pneumatiques, contrôle technique. C'est ce qui cadre tout le reste.

### Étape 2 : Squelette technique
Projet Next.js + TypeScript, Supabase connecté, déployé sur Vercel, une seule page qui affiche « Hello ». **Valider la chaîne complète de bout en bout avant d'écrire la moindre logique métier.**

### Étape 3 : Schéma et données réelles
Créer les tables, activer RLS, saisir manuellement la Fiesta et tout l'historique connu. Objectif : confronter le modèle à la réalité et le corriger tant que c'est peu coûteux.

### Étape 4 : Écrans de lecture ⭐
Vue véhicule, historique des interventions, et **calcul des prochaines échéances**. C'est le cœur de valeur : **à la fin de cette étape, l'application doit déjà être utile.**

### Étape 5 : Écriture
Formulaire d'ajout d'intervention + upload de facture. Ajout de relevés kilométriques.

### Étape 6 : Rappels
Cron quotidien qui recalcule les échéances et envoie une notification (email ou Telegram).

### Étape 7 : PWA
Manifest, icônes, service worker, installabilité.

---

## 7. Fonctionnalités avancées (v3) : la vraie valeur ajoutée

Ces quatre idées sont ce qui distinguerait l'outil des applications existantes (Drivvo, Fuelio…), qui restent des carnets passifs orientés carburant. Le principe est le même que pour un agrégateur bancaire : **la valeur n'est pas dans le stockage de la donnée, elle est dans les insights obtenus en la recoupant.**

### 7.1 Coût de possession réel ⭐ (la plus forte)
En croisant factures, kilomètres et durée de détention : **« ta voiture te coûte 0,18 € du kilomètre, tout compris »**. Décomposable par poste (entretien, réparations, carburant, assurance). Quasiment personne ne connaît ce chiffre pour son propre véhicule, et c'est une information qui change des décisions.

### 7.2 Aide à la décision « je répare ou je revends »
Croiser la courbe des coûts d'entretien annuels avec la valeur de revente estimée du modèle. Quand les frais annuels dépassent la décote, l'application le signale. Nécessite une source de cotation (saisie manuelle acceptable au début).

### 7.3 Analyse de devis de garage
L'utilisateur photographie un devis, l'IA le lit et le confronte à l'historique du véhicule : *« ils proposent une vidange, mais elle a été faite il y a 4 000 km »*. Prestation pertinente / redondante / prématurée. **Très utile, très peu fait, et directement actionnable.**

### 7.4 Détection d'anomalies de consommation
Suivi des pleins et de la consommation aux 100 km. Une hausse progressive et régulière est souvent le signe d'un problème mécanique naissant (bougies usées, sonde lambda, filtre à air encrassé, pression des pneus). Alerte sur écart statistique.

---

## 8. Instructions pour Claude Code

Au démarrage :

1. **Ne pas tout générer d'un coup.** Suivre la feuille de route §6, étape par étape, en validant chaque étape avant la suivante.
2. **Expliquer les choix d'architecture** au fur et à mesure. Je découvre ces sujets : je veux comprendre le *pourquoi*, pas seulement recevoir du code qui marche.
3. **Privilégier la lisibilité et la maintenabilité** sur la concision ou l'astuce. Nommage explicite, découpage clair, pas de magie.
4. **Typage strict.** TypeScript en mode strict, types générés depuis le schéma Supabase.
5. **Migrations SQL versionnées** dans le repo, pas de modification de schéma via l'interface Supabase.
6. **Tests** au minimum sur la logique de calcul des échéances, c'est le cœur métier et c'est là que les bugs feront le plus mal.
7. Me proposer des alternatives quand un choix est discutable, plutôt que de trancher silencieusement.

---

## 9. Points ouverts à trancher

- Source des plans d'entretien pour la mise à l'échelle (saisie manuelle au début ; scraping ou base ouverte à explorer plus tard)
- Canal de notification définitif : email vs Telegram vs push web
- Solution OCR pour les factures (modèle vision vs service dédié)
- Source de cotation véhicule pour la fonctionnalité 7.2
- Le projet reste-t-il perso, ou vise-t-il à terme une distribution publique ? (impacte l'auth, le multi-tenant, la conformité RGPD)

---

## 10. Décisions arrêtées au 28/08/2026

> Section ajoutée après la session `/start`. Elle tranche une partie des points ouverts du §9 et corrige trois trous du modèle de données. Elle prime sur les §2, §4 et §9 en cas de contradiction.

### 10.1 Nature du projet

Projet **personnel, sans visée commerciale**. Objectif principal : construire une application de bout en bout et monter en compétences sur l'architecture, le SQL, les tests et le déploiement.

Objectif secondaire assumé : le projet doit être **montrable en portfolio** (entretien d'embauche, prospect, démonstration publique). Deux conséquences concrètes :

- Il faut un **compte de démonstration à données fictives**, accessible sans créer de compte, pour montrer l'application sans exposer les vraies factures. C'est une fonctionnalité à part entière, à planifier (pas avant l'étape 4, mais avant toute mise en avant publique).
- La qualité de code doit rester défendable à l'oral : nommage explicite, découpage clair, tests sur le cœur métier, migrations versionnées. Ce sont les critères regardés par un relecteur externe.

RGPD et multi-tenant : hors périmètre tant que le projet reste personnel. L'authentification Supabase avec RLS activée suffit et reste la bonne base si le périmètre change un jour.

### 10.2 Point de départ de l'historique

**Véhicule de référence** : Ford Fiesta 2014, essence 82 ch, achetée d'occasion en **2018 à environ 56 000 km**.

L'historique est **fiable et documenté par facture à partir de l'achat en 2018**. Rien n'est connu avec certitude sur la période antérieure.

Ce n'est pas un cas particulier à modéliser à part : les champs `purchase_date` et `purchase_mileage` déjà prévus sur `vehicles` **font office de frontière de l'historique fiable**. Aucune table ni colonne supplémentaire.

En revanche, la logique de calcul des échéances rend **trois états**, pas deux :

| Situation | Statut rendu |
|---|---|
| Une intervention correspondante existe depuis la date d'achat | Calcul nominal (à jour ou en retard, selon km et date) |
| Aucune intervention, et l'intervalle de l'opération est **plus court** que la période écoulée depuis l'achat | **À faire** (opération réellement due, ou facture non saisie) |
| Aucune intervention, et l'intervalle est **plus long** que la période écoulée depuis l'achat | **Inconnu, à faire vérifier** (la réponse dépend d'avant 2018) |

Le troisième état est le cœur de l'utilité réelle sur ce véhicule : c'est le cas de la courroie de distribution, point critique de cette motorisation.

Si une information antérieure à 2018 est retrouvée (carnet tamponné par le vendeur, ancienne facture), elle se saisit comme une `maintenance_event` datée avant l'achat. Le modèle l'accepte sans aménagement.

### 10.3 Contrôle technique

Le contrôle technique entre dans le périmètre du suivi, et se calcule **sur la date uniquement, jamais sur le kilométrage**.

Règle française pour une voiture particulière, à revérifier sur service-public.fr avant implémentation (sujet réglementaire, susceptible d'évoluer) : premier contrôle dans les 6 mois précédant le 4e anniversaire de la **première mise en circulation**, puis **tous les 24 mois**. Contre-visite sous 2 mois en cas de défaillance majeure.

Note : une vente d'occasion exige un contrôle de moins de 6 mois, l'achat de 2018 coïncide donc probablement avec un contrôle. À confirmer dans les documents du véhicule, cela ancre le cycle (2018, 2020, 2022, 2024, 2026).

**Modélisation retenue** : une ligne de `plan_operations` avec `interval_months: 24`, `interval_km: null`, et une valeur `réglementaire` ajoutée à l'enum `category`. L'impureté (un contrôle technique n'est pas une opération du plan constructeur Ford) est acceptée : avec un seul plan et un seul véhicule elle est sans conséquence. Si elle devient gênante, l'évolution connue est de passer à plusieurs plans par véhicule. **Ne pas construire cette généralisation maintenant.**

### 10.4 Corrections du modèle de données (§4)

Deux champs à ajouter sur `vehicles`, coût négligeable aujourd'hui, coûteux à rétrofitter :

| Champ | Type | Raison |
|---|---|---|
| `first_registration_date` | date | Le champ `year` (entier) ne suffit pas : le contrôle technique se calcule sur la date exacte de première mise en circulation figurant sur la carte grise. |
| `purchase_price` | numeric | Sans lui, la dépréciation, premier poste de coût d'un véhicule, est hors de portée définitivement. Le champ est rempli dès la v1 même si rien ne l'exploite avant la v3. |

### 10.5 Où vit la logique de calcul

**Fonction TypeScript pure, sans accès à la base de données.** Elle reçoit un plan d'entretien, une liste d'interventions et une liste de relevés kilométriques, et rend une liste d'échéances classées.

Raison : c'est la seule forme qui rende le §8.6 (tests sur le cœur métier) réellement praticable, et le cron de l'étape 6 réutilise exactement la même fonction que les écrans de l'étape 4. Une vue SQL aurait été plus rapide à écrire et beaucoup plus difficile à tester.

### 10.6 Périmètre parqué

Critère de tri unique pour la v1 : **est-ce que ça sert l'écran des prochaines échéances ?** Si non, cela attend.

Parqué explicitement, à ne pas approfondir avant que le cœur fonctionne :

- Coût de possession réel (§7.1)
- Suivi carburant et consommation (§7.4). Des applications existantes (Drivvo, Fuelio) traitent déjà bien ce sujet, il n'y a aucune urgence à le refaire, et cela ne sert pas l'écran principal.
- OCR des factures (v2)
- Analyse de devis de garage (§7.3)
- Aide à la décision réparer / revendre (§7.2)

**Sur la cote argus** : ne pas tenter de l'estimer par calcul à partir des caractéristiques du véhicule. Cela produirait un chiffre indéfendable, contraire à l'objectif du projet. Le jour venu, la valeur est saisie manuellement après consultation d'une source externe, et l'application se contente du croisement.

### 10.7 Points à trancher pendant `/architect`

Ces points restent ouverts, mais ils sont petits et n'engagent pas la feuille de route :

- **Seuil de fiabilité de la projection kilométrique.** Avec deux relevés espacés d'une semaine, le rythme mensuel est du bruit. Définir le nombre minimum de relevés, la fenêtre glissante utilisée, et l'affichage quand la donnée est insuffisante. Sans cela, l'écran principal affiche des dates fausses avec l'aplomb d'une certitude.
- **Correction et suppression des relevés kilométriques et des interventions.** Un relevé saisi à tort fausse toute la projection. Le cas du compteur qui recule (remplacement de tableau de bord, faute de frappe) doit être géré. Le §6 étape 5 ne parle que de saisie.
- **Nature du champ `cost`** : TTC ou HT, pièces et main d'œuvre confondues ou séparées. À décider et documenter, sinon le calcul de coût de la v3 sera bancal.
- Canal de notification définitif pour l'étape 6 (email, Telegram ou push web).

### 10.8 Discipline de travail

La feuille de route du §6 est conservée telle quelle.

Une phase à la fois, avec le rituel `/plan` puis `/execute` puis `/validate` puis `/close`. La phase suivante ne se discute pas tant que la précédente n'est pas validée. Toute idée de fonctionnalité qui surgit en cours de route va dans une liste, jamais directement dans le code : `/evoluer` est fait pour ça.

**Jalon de vérité : la fin de l'étape 4.** À ce moment, l'application doit dire quelque chose que son utilisateur ne savait pas sur son véhicule. Tout ce qui n'est pas sur le chemin de ce moment est un détour.
