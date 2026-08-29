-- =========================================================================
-- Carneo, seed d'exemple (Phase 2, tâche 6).
--
-- CE FICHIER NE S'EXÉCUTE PAS TEL QUEL. Il ne connaît aucun UUID réel : il
-- attend qu'on lui substitue l'identifiant d'un utilisateur existant, à la
-- ligne marquée « À REMPLACER » ci-dessous.
--
-- Il a deux raisons d'être :
--   1. documenter le format attendu par chaque table, pour qu'on puisse
--      écrire un nouveau jeu de données sans relire les migrations ;
--   2. servir de matrice au jeu de démonstration de la Phase 6.
--
-- Toutes les valeurs sont FICTIVES : ni plaque, ni garage, ni montant réels.
-- Les vraies données de David vivent dans `seed.local.sql`, gitignoré.
--
-- Le script est idempotent : chaque insertion porte un `on conflict do
-- nothing` sur la clé naturelle de sa table, donc un second passage ne
-- duplique rien.
--
-- Exécution : copier-coller dans l'éditeur SQL du projet Supabase. Il n'y a
-- pas de stack locale, et `supabase db push` ne joue pas les seeds.
-- =========================================================================

begin;

-- -------------------------------------------------------------------------
-- 0. L'utilisateur propriétaire
--
-- Récupérer l'UUID avec :  select id, email from auth.users;
-- Déclaré une seule fois ici, jamais recopié dans les insertions.
-- -------------------------------------------------------------------------

create temporary table seed_contexte on commit drop as
select
  -- À REMPLACER par l'UUID d'un utilisateur réel avant exécution.
  '00000000-0000-0000-0000-000000000000'::uuid as user_id,
  'Ford Fiesta 6 (2008-2017), 1.25 82 ch'      as nom_plan,
  'exemple-fiesta'                             as cle_vehicule;

-- -------------------------------------------------------------------------
-- 1. Le plan d'entretien constructeur, en plan PARTAGÉ (user_id NULL)
--
-- user_id NULL = lisible par tout utilisateur authentifié, modifiable par
-- personne. C'est une référence commune, elle ne se corrige que par migration.
-- Source des périodicités : docs/references/plan-entretien-ford-fiesta-6-1.25-82.md
-- 9 opérations : 6 confirmées par le calendrier officiel Ford, 2 issues d'une source
-- tierce et marquées comme telles dans notes, 1 réglementaire (contrôle technique).
-- -------------------------------------------------------------------------

insert into public.maintenance_plans
  (user_id, name, make, model, year_from, year_to, engine, source)
select
  null,
  c.nom_plan,
  'Ford',
  'Fiesta',
  2008,
  2017,
  '1.25 Duratec 82 ch',
  'Calendrier d''entretien officiel Ford, obtenu par VIN le 29/08/2026'
from seed_contexte c
on conflict (user_id, name) do nothing;

-- -------------------------------------------------------------------------
-- 2. Les 9 opérations du plan
--
-- 6 lignes sont confirmées par le calendrier officiel Ford pour ce VIN, 2 (bougies
-- d'allumage, filtre à air) ne viennent que d'une source tierce et le disent dans
-- notes, et la 9e (contrôle technique) est réglementaire, hors constructeur.
--
-- interval_km NULL      = ce critère ne s'applique pas (le contrôle technique
--                         ne dépend pas du kilométrage).
-- first_due_months      = première échéance comptée depuis la première mise en
--                         circulation, quand elle diffère de l'intervalle.
-- notes                 = détail d'un forfait, ou aveu d'une périodicité
--                         déduite plutôt que lue.
-- -------------------------------------------------------------------------

insert into public.plan_operations
  (maintenance_plan_id, name, category, interval_km, interval_months,
   first_due_months, criticality, notes)
select
  p.id, o.name, o.category, o.interval_km, o.interval_months,
  o.first_due_months, o.criticality, o.notes
from seed_contexte c
join public.maintenance_plans p
  on p.user_id is null and p.name = c.nom_plan
cross join (values
  ('Révision de base',
   'moteur'::public.operation_category, 20000, 12, null::integer,
   'critique'::public.criticality,
   'Palier des 20 000 km ou 1 an. Ford y liste 49 opérations, facturées sur une ligne unique : vidange de l''huile moteur, remplacement du filtre à huile, appoints, remise à zéro du témoin d''entretien, et une quarantaine de contrôles (freins, pneus, direction, ceintures, éclairage, fuites, essai sur route).'),

  ('Filtre d''habitacle (changement)',
   'filtration'::public.operation_category, 20000, 12, null::integer,
   'confort'::public.criticality,
   'Le « Filtre anti-odeurs, remplacer » que Ford inscrit à chaque palier de 20 000 km. À ne pas confondre avec le Filtre de protection MicronAir (12 mois ou 15 000 km), prestation optionnelle facturée à part et hors plan constructeur.'),

  ('Purge du liquide de frein',
   'freinage'::public.operation_category, null::integer, 24, null::integer,
   'critique'::public.criticality,
   'Ford écrit « Tous les 2 ans », sans aucun critère kilométrique. interval_km reste donc NULL : le 40 000 km qu''on lit ailleurs est une conversion sous l''hypothèse de 20 000 km par an, pas une prescription du constructeur.'),

  ('Kit de courroie de distribution (changement)',
   'moteur'::public.operation_category, 160000, 96, null::integer,
   'critique'::public.criticality,
   'Ford : « Tous les 160 000 km ou après 8 ans, selon première échéance » (opération 21 304 9). Distincte de la courroie d''entraînement des accessoires, qui porte la même périodicité mais une autre opération.'),

  ('Courroie d''entraînement des accessoires (changement)',
   'moteur'::public.operation_category, 160000, 96, null::integer,
   'critique'::public.criticality,
   'Ford : « Tous les 160 000 km ou après 8 ans, selon première échéance » (opération 21 567 5). Une facture ne mentionnant que « courroie » sera ambiguë entre celle-ci et la distribution.'),

  ('Purge du liquide de refroidissement',
   'moteur'::public.operation_category, null::integer, 120, null::integer,
   'recommande'::public.criticality,
   'Ford écrit « Tous les 10 ans », sans aucun critère kilométrique. interval_km reste donc NULL.'),

  ('Bougies d''allumage (changement)',
   'moteur'::public.operation_category, 60000, 36, null::integer,
   'recommande'::public.criticality,
   'non prescrit par le calendrier officiel Ford, provient d''une source tierce. Recherche exhaustive dans la réponse officielle du constructeur pour ce VIN : zéro occurrence de « bougie » ou « allumage ». Conservée par asymétrie des conséquences, à afficher comme incertaine et non comme une échéance établie.'),

  ('Filtre à air (changement)',
   'filtration'::public.operation_category, 60000, 36, null::integer,
   'recommande'::public.criticality,
   'non prescrit par le calendrier officiel Ford, provient d''une source tierce. Recherche exhaustive dans la réponse officielle du constructeur pour ce VIN : zéro occurrence de « filtre à air ». Conservée par asymétrie des conséquences, à afficher comme incertaine.'),

  ('Contrôle technique',
   'reglementaire'::public.operation_category, null::integer, 24, 48,
   'critique'::public.criticality,
   'Hors calendrier constructeur. Première échéance 4 ans après la première mise en circulation, puis tous les 2 ans. Règle à revérifier sur service-public.fr avant l''implémentation du moteur d''échéances.')
) as o(name, category, interval_km, interval_months, first_due_months, criticality, notes)
on conflict (maintenance_plan_id, name) do nothing;

-- -------------------------------------------------------------------------
-- 3. Le véhicule
--
-- Valeurs fictives. La plaque est nullable : elle n'a aucune utilité
-- fonctionnelle, elle sert seulement à reconnaître son véhicule dans une
-- liste.
-- -------------------------------------------------------------------------

insert into public.vehicles
  (user_id, maintenance_plan_id, make, model, year, engine, fuel_type,
   first_registration_date, purchase_date, purchase_mileage, purchase_price,
   plate)
select
  c.user_id, p.id, 'Ford', 'Fiesta', 2015, '1.25 Duratec 82 ch',
  'essence'::public.fuel_type,
  date '2015-04-01',   -- première mise en circulation
  date '2019-06-15',   -- achat d'occasion
  62000,               -- compteur au moment de l'achat
  7500.00,             -- prix d'achat TTC
  'AA-123-BB'
from seed_contexte c
join public.maintenance_plans p
  on p.user_id is null and p.name = c.nom_plan
-- Pas de clé naturelle sur vehicles (deux véhicules sans plaque resteraient
-- distincts) : l'idempotence passe par une absence de doublon explicite.
where not exists (
  select 1 from public.vehicles v
  where v.user_id = c.user_id and v.make = 'Ford' and v.model = 'Fiesta'
    and v.first_registration_date = date '2015-04-01'
);

-- -------------------------------------------------------------------------
-- 4. Les relevés kilométriques
--
-- Clé naturelle : (vehicle_id, recorded_at). Un seul relevé par jour et par
-- véhicule, un second relevé le même jour serait une correction.
-- Aucune contrainte n'interdit un compteur qui recule : c'est une alerte
-- d'interface (Phase 4), pas une erreur de base.
-- -------------------------------------------------------------------------

insert into public.mileage_readings (vehicle_id, recorded_at, mileage)
select v.id, r.recorded_at, r.mileage
from seed_contexte c
join public.vehicles v
  on v.user_id = c.user_id and v.first_registration_date = date '2015-04-01'
cross join (values
  (date '2019-06-15',  62000),
  (date '2021-09-04',  84300),
  (date '2023-11-18', 108700),
  (date '2026-08-01', 131400)
) as r(recorded_at, mileage)
on conflict (vehicle_id, recorded_at) do nothing;

-- -------------------------------------------------------------------------
-- 5. Les interventions
--
-- Clé naturelle : (vehicle_id, performed_at, label).
--
-- plan_operation_id est rattaché par le NOM de l'opération : c'est ce lien qui
-- permettra au moteur de la Phase 3 de dire « la dernière révision date de
-- telle date et tel kilométrage ». Une intervention hors plan (une réparation)
-- laisserait ce champ à NULL.
--
-- document_id reste NULL partout : la table documents n'est alimentée qu'à
-- partir de la Phase 4, avec le bucket privé et l'upload de factures.
-- -------------------------------------------------------------------------

insert into public.maintenance_events
  (vehicle_id, plan_operation_id, document_id, label, performed_at, mileage,
   cost, garage, notes)
select
  v.id,
  po.id,
  null,
  e.label,
  e.performed_at,
  e.mileage,
  e.cost,
  e.garage,
  e.notes
from seed_contexte c
join public.vehicles v
  on v.user_id = c.user_id and v.first_registration_date = date '2015-04-01'
join public.maintenance_plans p
  on p.user_id is null and p.name = c.nom_plan
cross join (values
  ('Révision de base',            date '2021-09-04',  84300, 189.00::numeric, 'Garage Exemple', 'Révision de base'),
  ('Purge du liquide de frein',   date '2021-09-04',  84300,  75.00::numeric, 'Garage Exemple', 'Purge du liquide de frein'),
  ('Révision de base',            date '2023-11-18', 108700, 215.00::numeric, 'Garage Exemple', 'Révision de base'),
  ('Filtre d''habitacle (changement)', date '2023-11-18', 108700, 38.00::numeric, 'Garage Exemple', 'Filtre d''habitacle (changement)')
) as e(label, performed_at, mileage, cost, garage, nom_operation)
left join public.plan_operations po
  on po.maintenance_plan_id = p.id and po.name = e.nom_operation
on conflict (vehicle_id, performed_at, label) do nothing;

commit;

-- -------------------------------------------------------------------------
-- Contrôle après exécution : les comptes attendus.
-- Rejouer le script ne doit changer aucun de ces chiffres.
-- -------------------------------------------------------------------------

-- select 'plans partagés' as quoi, count(*) from public.maintenance_plans where user_id is null
-- union all select 'opérations du plan', count(*) from public.plan_operations
-- union all select 'véhicules',          count(*) from public.vehicles
-- union all select 'relevés',            count(*) from public.mileage_readings
-- union all select 'interventions',      count(*) from public.maintenance_events;
