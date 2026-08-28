# Plan d'entretien constructeur, Ford Fiesta 6, 1.25 82 ch

> Source : carnet d'entretien constructeur Ford, fourni par David le 28/08/2026.
> Sert de source unique au seed de la table `plan_operations` (Phase 2, tâche 6).
> Ne pas modifier sans reporter le changement dans le seed et inversement.

## Périodicités dépouillées

Les deux tableaux du constructeur (par âge et par kilométrage) sont parallèles : chaque prestation
revient à intervalle régulier, avec un rapport constant de 12 mois pour 20 000 km. Ford suppose
donc un usage de 20 000 km par an.

| Opération | `interval_km` | `interval_months` | `category` | `criticality` |
|---|---|---|---|---|
| Révision de base | 20000 | 12 | moteur | critique |
| Filtre d'habitacle (changement) | 20000 | 12 | filtration | confort |
| Purge du liquide de frein | 40000 | 24 | freinage | critique |
| Bougies d'allumage (changement) | 60000 | 36 | moteur | recommande |
| Filtre à air (changement) | 60000 | 36 | filtration | recommande |
| Kit de courroie de distribution (changement) | 160000 | 96 | moteur | critique |
| Purge du liquide de refroidissement | 200000 | 120 | moteur | recommande |

**Révision de base** regroupe : vidange de l'huile moteur, changement du filtre à huile, contrôle du
véhicule, mise à niveau des fluides, remise à zéro du témoin d'entretien, diagnostic électronique.
Modélisée comme une opération unique, ce détail va dans `plan_operations.notes` (voir le cadrage du
plan de Phase 2).

**Hors carnet constructeur** : le contrôle technique, ajouté au plan comme opération
`reglementaire`, `interval_months = 24`, `interval_km = NULL`. Sa première échéance (4 ans après la
première mise en circulation) n'est pas exprimable par un simple intervalle, c'est le point ouvert
soumis à `/challenge`.

## Justification des périodicités déduites

Vérification ligne à ligne des deux tableaux sources :

- Révision de base et filtre d'habitacle : présents à chaque révision, années 1 à 15 et paliers
  20 000 à 300 000 km.
- Purge du liquide de frein : années 2, 4, 6, 8, 10, 12, 14 et paliers 40 000, 80 000, 120 000,
  160 000, 200 000, 240 000, 280 000 km.
- Bougies d'allumage et filtre à air : années 3, 6, 9, 12, 15 et paliers 60 000, 120 000, 180 000,
  240 000, 300 000 km.
- Kit de courroie de distribution : une seule occurrence, année 8 et 160 000 km.
- Purge du liquide de refroidissement : une seule occurrence, année 10 et 200 000 km.

Les deux dernières périodicités ne sont **pas prouvées** par le document : le tableau s'arrête à
15 ans et 300 000 km, donc une éventuelle récurrence à 16 ans ou 320 000 km n'y figure pas. Elles
sont modélisées comme périodiques par prudence : au pire l'application propose une opération déjà
faite, au mieux elle ne la rate pas. Écart assumé, à revérifier sur le carnet papier si l'occasion
se présente.

La catégorie `pneumatiques` de l'enum `operation_category` n'est utilisée par aucune opération de ce
plan : le carnet Ford ne prescrit rien sur les pneus. Elle reste dans l'enum pour les plans futurs.

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
