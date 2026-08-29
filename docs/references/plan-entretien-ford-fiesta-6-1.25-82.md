# Plan d'entretien, Ford Fiesta 6, 1.25 82 ch (VIN de David)

> **Source principale : calendrier d'entretien officiel Ford**, obtenu le 29/08/2026 pour le VIN exact
> du véhicule, via `ford.fr/support/verification-intervalles-entretien` (l'API interrogée est
> `api.mss.ford.com/digitalservices/fs/api/v2/vehicles/maintenance/schedule`, le VIN voyage en en-tête
> de requête). Réponse : 20 paliers de 20 000 km ou 1 an, jusqu'à 400 000 km et 20 ans, 49 opérations
> par palier, identiques d'un palier à l'autre.
>
> **Historique de ce fichier.** Il a d'abord été écrit le 28/08/2026 à partir d'un site tiers non
> officiel, étiqueté à tort « carnet d'entretien constructeur Ford ». Le re-sourçage officiel du
> 29/08/2026 a corrigé quatre points et en a confirmé trois. Le détail de la confrontation est en fin
> de fichier, et la source tierce d'origine est conservée pour la traçabilité des deux opérations
> qu'elle est seule à prescrire.
>
> **Piste écartée** : le Manuel du conducteur Ford en ligne (`fordservicecontent.com`,
> `bookcode=O25675`) ne contient AUCUN plan de révisions. Sommaire complet parcouru, chapitre
> « Entretien » limité au contrôle des niveaux et aux consommables. Inutile d'y retourner.
>
> Sert de source unique au seed de la table `plan_operations` (Phase 2, tâche 6).
> Ne pas modifier sans reporter le changement dans le seed et inversement.

## Les 9 opérations du plan

| Opération | `interval_km` | `interval_months` | `first_due_months` | `category` | `criticality` | Source |
|---|---|---|---|---|---|---|
| Révision de base | 20000 | 12 | NULL | moteur | critique | Ford officiel |
| Filtre d'habitacle (changement) | 20000 | 12 | NULL | filtration | confort | Ford officiel |
| Purge du liquide de frein | NULL | 24 | NULL | freinage | critique | Ford officiel |
| Kit de courroie de distribution (changement) | 160000 | 96 | NULL | moteur | critique | Ford officiel |
| Courroie d'entraînement des accessoires (changement) | 160000 | 96 | NULL | moteur | critique | Ford officiel |
| Purge du liquide de refroidissement | NULL | 120 | NULL | moteur | recommande | Ford officiel |
| Bougies d'allumage (changement) | 60000 | 36 | NULL | moteur | recommande | **tiers, non confirmé** |
| Filtre à air (changement) | 60000 | 36 | NULL | filtration | recommande | **tiers, non confirmé** |
| Contrôle technique | NULL | 24 | 48 | reglementaire | critique | Réglementation française |

**Révision de base** est le palier des 20 000 km ou 1 an. Ford y liste 49 opérations : vidange de
l'huile moteur et remplacement du filtre à huile, appoints, remise à zéro du témoin, et une
quarantaine de contrôles (freins, pneus, direction, ceintures, éclairage, fuites, essai sur route).
Le garage la facture sur une ligne unique et l'extraction de la Phase 5 fera correspondre une ligne
de facture à une opération : elle est donc modélisée en **une seule** opération, pas en 49. Le détail
va dans `plan_operations.notes`.

**Filtre d'habitacle** correspond au « Filtre anti-odeurs, remplacer » que Ford inscrit à chaque
palier de 20 000 km. À ne pas confondre avec le « Filtre de protection MicronAir » (12 mois ou
15 000 km), qui est une prestation optionnelle facturée à part, hors plan constructeur.

**Les deux courroies sont distinctes.** Ford prescrit séparément la courroie de distribution
(opération 21 304 9) et les courroies d'entraînement des accessoires (opération 21 567 5), aux mêmes
périodicités. Une facture ne mentionnant que « courroie » sera ambiguë, la Phase 5 devra le prévoir.

**Liquide de frein et liquide de refroidissement n'ont aucun critère kilométrique.** Ford écrit
« Tous les 2 ans » et « Tous les 10 ans », sans mention de kilomètres. Le document tiers y avait
ajouté 40 000 km et 200 000 km, ce qui correspond à ces durées sous l'hypothèse de 20 000 km par an,
mais ce n'est pas ce que dit le constructeur. `interval_km` reste donc NULL sur ces deux lignes.

**Bougies d'allumage et filtre à air : à traiter comme incertains.** Recherche exhaustive dans la
réponse officielle : zéro occurrence de « bougie », « allumage », « filtre à air ». Ces deux
opérations ne viennent que du site tiers. Elles sont **conservées** dans le plan par asymétrie des
conséquences (un faux « à faire » coûte une question au garage, un faux « à jour » coûte une panne),
et `notes` porte la mention « non prescrit par le calendrier officiel Ford, provient d'une source
tierce » que la Phase 3 affichera plutôt que de présenter l'échéance comme une certitude.

**Contrôle technique** : hors constructeur. Première échéance 4 ans après la première mise en
circulation, puis tous les 2 ans. Règle à revérifier sur `service-public.fr` avant l'implémentation
du moteur d'échéances.

La catégorie `pneumatiques` de l'enum `operation_category` n'est utilisée par aucune opération de ce
plan : Ford ne prescrit aucun remplacement de pneu à échéance, il les classe en pièce d'usure
remplacée à la demande. Elle reste dans l'enum pour les plans futurs.

## Ce que le calendrier officiel dit d'autre, et qui n'entre pas au plan

Écarté volontairement, pour que personne ne se demande plus tard si c'est un oubli.

- **Contrôle visuel de la carrosserie et de la peinture**, « tous les 12 ou 24 mois en fonction du
  type de véhicule ». Périodicité non déterminée pour ce véhicule, et sans conséquence mécanique.
- **Filtre de protection MicronAir**, 12 mois ou 15 000 km. Prestation optionnelle facturée à part.
- **Option entretien climatisation.** Optionnelle, sur demande du client.
- **Pièces d'usure** (échappement, amortisseurs, disques et plaquettes, balais d'essuie-glace,
  pneus) : Ford les liste comme « Remplacer » sans aucune périodicité, elles se changent à l'usure
  constatée. Elles relèvent de l'intervention ponctuelle (`maintenance_events` avec
  `plan_operation_id` à NULL), pas du plan.

## Confrontation avec la source tierce d'origine

| Opération | Document tiers (28/08) | Ford officiel (29/08) | Verdict |
|---|---|---|---|
| Révision de base | 20 000 km / 12 mois | identique | confirmé |
| Filtre d'habitacle | 20 000 km / 12 mois | identique | confirmé |
| Kit de courroie de distribution | 160 000 km / 96 mois | « 160 000 km ou 8 ans, selon première échéance » | confirmé |
| Purge du liquide de frein | 40 000 km / 24 mois | « Tous les 2 ans », sans critère km | corrigé |
| Purge du liquide de refroidissement | 200 000 km / 120 mois | « Tous les 10 ans », sans critère km | corrigé |
| Courroie d'entraînement des accessoires | absente | « 160 000 km ou 8 ans » | ajoutée |
| Bougies d'allumage | 60 000 km / 36 mois | absente du calendrier | non confirmée, conservée |
| Filtre à air | 60 000 km / 36 mois | absente du calendrier | non confirmée, conservée |

Le document tiers s'arrêtait à 15 ans et 300 000 km, ce qui laissait croire que la courroie et le
liquide de refroidissement n'étaient prescrits qu'une seule fois. Le calendrier officiel va jusqu'à
20 ans et 400 000 km et les énonce comme des règles périodiques explicites. C'est ce qui permet de
retirer la mention « périodicité déduite » qui figurait sur ces deux lignes.

Corroboration indépendante : une facture d'entretien d'un centre auto, datée du 27/02/2021, mentionne, dans son pavé « prochaines
étapes », courroie de distribution 160 000 km ou 8 ans, liquide de frein 2 ans, liquide de
refroidissement 10 ans, et courroie d'accessoires 160 000 km ou 8 ans. Quatre points sur quatre
concordent avec Ford.

---

# Annexe : la source tierce d'origine

Conservée telle quelle. Elle reste la seule source des bougies d'allumage et du filtre à air.

## Source brute

Reproduite telle que fournie, pour pouvoir refaire le dépouillement sans redemander le document.

### Suivant l'âge du véhicule

- **1 an** : révision de base, filtre d'habitacle
- **2 ans** : révision de base, purge du liquide de frein, filtre d'habitacle
- **3 ans** : révision de base, filtre d'habitacle, bougies d'allumage, filtre à air
- **4 ans** : révision de base, purge du liquide de frein, filtre d'habitacle
- **5 ans** : révision de base, filtre d'habitacle
- **6 ans** : révision de base, bougies d'allumage, filtre d'habitacle, purge du liquide de frein, filtre à air
- **7 ans** : révision de base, filtre d'habitacle
- **8 ans** : révision de base, kit de courroie de distribution, filtre d'habitacle, purge du liquide de frein
- **9 ans** : révision de base, filtre d'habitacle, bougies d'allumage, filtre à air
- **10 ans** : révision de base, purge du liquide de refroidissement, purge du liquide de frein, filtre d'habitacle
- **11 ans** : révision de base, filtre d'habitacle
- **12 ans** : révision de base, bougies d'allumage, filtre d'habitacle, purge du liquide de frein, filtre à air
- **13 ans** : révision de base, filtre d'habitacle
- **14 ans** : révision de base, purge du liquide de frein, filtre d'habitacle
- **15 ans** : révision de base, filtre d'habitacle, bougies d'allumage, filtre à air

### Suivant le kilométrage

- **20 000 km** : révision de base, filtre d'habitacle
- **40 000 km** : révision de base, purge du liquide de frein, filtre d'habitacle
- **60 000 km** : révision de base, filtre d'habitacle, bougies d'allumage, filtre à air
- **80 000 km** : révision de base, purge du liquide de frein, filtre d'habitacle
- **100 000 km** : révision de base, filtre d'habitacle
- **120 000 km** : révision de base, bougies d'allumage, filtre d'habitacle, purge du liquide de frein, filtre à air
- **140 000 km** : révision de base, filtre d'habitacle
- **160 000 km** : révision de base, kit de courroie de distribution, filtre d'habitacle, purge du liquide de frein
- **180 000 km** : révision de base, filtre d'habitacle, bougies d'allumage, filtre à air
- **200 000 km** : révision de base, purge du liquide de refroidissement, purge du liquide de frein, filtre d'habitacle
- **220 000 km** : révision de base, filtre d'habitacle
- **240 000 km** : révision de base, bougies d'allumage, filtre d'habitacle, purge du liquide de frein, filtre à air
- **260 000 km** : révision de base, filtre d'habitacle
- **280 000 km** : révision de base, purge du liquide de frein, filtre d'habitacle
- **300 000 km** : révision de base, filtre d'habitacle, bougies d'allumage, filtre à air

### Définition de la révision de base

Vidange de l'huile moteur, filtre à huile (changement), contrôle du véhicule, mise à niveau des
fluides, remise à zéro du témoin d'entretien, diagnostic électronique.
