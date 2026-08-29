-- Migration : schéma initial de Carneo (Phase 2, tâche 1).
--
-- Structure uniquement : types, tables, clés étrangères, index, trigger de
-- fraîcheur. La sécurité au niveau des lignes est traitée dans la migration
-- suivante, volontairement séparée pour rester relisible et corrigeable.
--
-- Conventions de nullabilité retenues :
--   NOT NULL  ce qui est structurel (identité, rattachement, date et compteur
--             d'un événement) : sans ça la ligne ne veut rien dire.
--   NULL      ce qui est un fait parfois inconnu (motorisation, prix d'achat,
--             notes, coût, garage) ou dont l'absence porte un sens explicite,
--             documenté colonne par colonne ci-dessous.

-- ---------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------

create type public.fuel_type as enum (
  'essence',
  'diesel',
  'hybride',
  'electrique',
  'gpl'
);

-- `reglementaire` couvre ce que l'État impose et que le carnet constructeur
-- ignore, à commencer par le contrôle technique.
create type public.operation_category as enum (
  'moteur',
  'filtration',
  'freinage',
  'pneumatiques',
  'reglementaire'
);

create type public.criticality as enum (
  'critique',
  'recommande',
  'confort'
);

create type public.ocr_status as enum (
  'en_attente',
  'reussi',
  'echec'
);

-- ---------------------------------------------------------------------------
-- Fraîcheur des lignes
-- ---------------------------------------------------------------------------

-- `search_path` vidé : sans ça, un schéma placé en tête du chemin de recherche
-- par un appelant pourrait détourner les fonctions appelées ici.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

comment on function public.set_updated_at() is
  'Trigger partagé : maintient updated_at à la date de la dernière écriture.';

-- ---------------------------------------------------------------------------
-- Plans d'entretien
-- ---------------------------------------------------------------------------

-- Un plan est indépendant du véhicule et réutilisable (PRD §3).
create table public.maintenance_plans (
  id uuid primary key default gen_random_uuid(),
  -- NULL = plan partagé : lisible par tout utilisateur authentifié, modifiable
  -- par personne. Le plan constructeur Ford entre par cette porte.
  user_id uuid references auth.users (id) on delete cascade,
  name text not null,
  make text not null,
  model text not null,
  -- Bornes d'années de la génération couverte. NULL = borne inconnue ou
  -- génération encore produite.
  year_from integer,
  year_to integer,
  engine text,
  -- Provenance de la donnée, pour pouvoir la contester plus tard.
  source text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint maintenance_plans_year_range_check
    check (year_from is null or year_to is null or year_from <= year_to)
);

-- Clé naturelle du plan. `nulls not distinct` (PostgreSQL 15+) fait que deux
-- plans partagés de même nom entrent bien en conflit, alors que la règle par
-- défaut les considérerait comme distincts. C'est ce qui rend le seed
-- rejouable sans dupliquer.
create unique index maintenance_plans_owner_name_key
  on public.maintenance_plans (user_id, name) nulls not distinct;

create trigger maintenance_plans_set_updated_at
  before update on public.maintenance_plans
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Opérations d'un plan
-- ---------------------------------------------------------------------------

create table public.plan_operations (
  id uuid primary key default gen_random_uuid(),
  maintenance_plan_id uuid not null
    references public.maintenance_plans (id) on delete cascade,
  name text not null,
  category public.operation_category not null,
  -- Double critère du moteur d'échéances : la première borne atteinte
  -- déclenche. NULL = ce critère ne s'applique pas à l'opération (le contrôle
  -- technique ne dépend pas du kilométrage).
  interval_km integer,
  interval_months integer,
  -- Cas particulier de la première échéance quand elle ne suit pas
  -- l'intervalle courant : contrôle technique à 4 ans, puis tous les 2 ans.
  -- Comptée depuis first_registration_date du véhicule.
  first_due_months integer,
  criticality public.criticality not null,
  -- Porte le détail d'un forfait et, le cas échéant, la mention d'une
  -- périodicité déduite plutôt que lue dans le carnet.
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- Une opération sans aucune périodicité n'est jamais calculable.
  constraint plan_operations_has_interval_check
    check (interval_km is not null or interval_months is not null),
  constraint plan_operations_interval_km_check
    check (interval_km is null or interval_km > 0),
  constraint plan_operations_interval_months_check
    check (interval_months is null or interval_months > 0),
  -- Une première échéance décalée n'a de sens que sur un cycle en mois.
  constraint plan_operations_first_due_check
    check (first_due_months is null
           or (first_due_months > 0 and interval_months is not null))
);

create unique index plan_operations_plan_name_key
  on public.plan_operations (maintenance_plan_id, name);

create trigger plan_operations_set_updated_at
  before update on public.plan_operations
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Véhicules
-- ---------------------------------------------------------------------------

create table public.vehicles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  -- NULL = aucun plan rattaché. `set null` plutôt que `cascade` : perdre un
  -- plan ne doit jamais effacer le véhicule ni son historique.
  maintenance_plan_id uuid
    references public.maintenance_plans (id) on delete set null,
  make text not null,
  model text not null,
  year integer not null,
  engine text,
  fuel_type public.fuel_type not null,
  -- Ancre des échéances exprimées en âge du véhicule.
  first_registration_date date,
  purchase_date date,
  purchase_mileage integer,
  -- Saisi dès la V1, exploité en v3 (coût de possession).
  purchase_price numeric(10, 2),
  plate text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint vehicles_year_check check (year between 1900 and 2200),
  constraint vehicles_purchase_mileage_check
    check (purchase_mileage is null or purchase_mileage >= 0),
  constraint vehicles_purchase_price_check
    check (purchase_price is null or purchase_price >= 0)
);

create index vehicles_user_id_idx on public.vehicles (user_id);
create index vehicles_maintenance_plan_id_idx
  on public.vehicles (maintenance_plan_id);

create trigger vehicles_set_updated_at
  before update on public.vehicles
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Documents (factures)
-- ---------------------------------------------------------------------------

-- La table existe dès maintenant parce que les interventions la référencent.
-- Elle reste vide jusqu'à la Phase 4, qui apporte le bucket privé et l'upload.
create table public.documents (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references public.vehicles (id) on delete cascade,
  -- Chemin dans le bucket privé. Jamais une URL : les accès passent par une
  -- URL signée, générée à la demande.
  storage_path text not null,
  file_name text not null,
  mime_type text not null,
  size integer not null,
  uploaded_at timestamptz not null default now(),
  ocr_status public.ocr_status not null default 'en_attente',
  -- Extraction brute conservée pour rejouer une correspondance sans rappeler
  -- ni repayer l'API (PRD §3, Technique).
  ocr_data jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint documents_size_check check (size >= 0)
);

create index documents_vehicle_id_uploaded_at_idx
  on public.documents (vehicle_id, uploaded_at desc);

create trigger documents_set_updated_at
  before update on public.documents
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Interventions
-- ---------------------------------------------------------------------------

-- Le lien vers la facture est porté ici (ADR-002) : une visite au garage
-- produit une facture et plusieurs interventions, jamais l'inverse.
create table public.maintenance_events (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references public.vehicles (id) on delete cascade,
  -- NULL = intervention hors plan (une réparation, un pneu crevé), ou pas
  -- encore rattachée à une opération du plan.
  plan_operation_id uuid
    references public.plan_operations (id) on delete set null,
  -- NULL = saisie manuelle sans justificatif. `set null` : supprimer une
  -- facture ne doit pas effacer l'historique d'entretien.
  document_id uuid references public.documents (id) on delete set null,
  -- Libellé tel qu'il apparaît sur la facture, conservé même quand
  -- l'intervention est rattachée à une opération du plan.
  label text not null,
  performed_at date not null,
  mileage integer not null,
  -- Coût TTC de la ligne. NULL = inconnu, ce qui n'est pas 0.
  cost numeric(10, 2),
  garage text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint maintenance_events_mileage_check check (mileage >= 0),
  constraint maintenance_events_cost_check check (cost is null or cost >= 0)
);

-- Clé naturelle : une même prestation, le même jour, sur le même véhicule.
-- Rend le seed rejouable.
create unique index maintenance_events_natural_key
  on public.maintenance_events (vehicle_id, performed_at, label);

-- Index de la requête principale : l'historique d'un véhicule, du plus récent
-- au plus ancien.
create index maintenance_events_vehicle_id_performed_at_idx
  on public.maintenance_events (vehicle_id, performed_at desc);
create index maintenance_events_plan_operation_id_idx
  on public.maintenance_events (plan_operation_id);
create index maintenance_events_document_id_idx
  on public.maintenance_events (document_id);

create trigger maintenance_events_set_updated_at
  before update on public.maintenance_events
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Relevés kilométriques
-- ---------------------------------------------------------------------------

-- Aucune contrainte n'interdit un relevé inférieur au précédent : un compteur
-- qui recule peut être une correction légitime. C'est une alerte d'interface
-- (Phase 4), pas une erreur de base.
create table public.mileage_readings (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references public.vehicles (id) on delete cascade,
  recorded_at date not null,
  mileage integer not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint mileage_readings_mileage_check check (mileage >= 0)
);

-- Un seul relevé par véhicule et par jour : deux valeurs le même jour, c'est
-- une correction, donc une mise à jour. Rend le seed rejouable.
create unique index mileage_readings_natural_key
  on public.mileage_readings (vehicle_id, recorded_at);

-- Index du calcul de rythme : les relevés d'un véhicule, du plus récent au
-- plus ancien.
create index mileage_readings_vehicle_id_recorded_at_idx
  on public.mileage_readings (vehicle_id, recorded_at desc);

create trigger mileage_readings_set_updated_at
  before update on public.mileage_readings
  for each row execute function public.set_updated_at();
