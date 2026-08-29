-- =========================================================================
-- Carneo, audit de la sécurité au niveau des lignes (Phase 2, tâche 7).
--
-- QUESTION POSÉE : un utilisateur authentifié peut-il voir ou modifier les
-- données d'un autre ? Et un visiteur non authentifié peut-il voir quoi que
-- ce soit ?
--
-- LE PIÈGE QUE CE SCRIPT ÉVITE. L'éditeur SQL de Supabase exécute en
-- `postgres`, propriétaire des tables et porteur de BYPASSRLS. Un script
-- écrit naïvement comparerait ce que voit postgres à ce que voit postgres,
-- afficherait des lignes vertes partout et ne prouverait rien. Chaque bloc
-- de vérification bascule donc explicitement d'identité, par
-- `set_config('request.jwt.claims', ...)` puis `set local role`.
--
-- LE TÉMOIN. Le script compte les véhicules trois fois : en propriétaire
-- (attendu strictement positif), sous `authenticated` limité à ses propres
-- lignes, et sous `anon` (attendu zéro). Si ce compte ne bascule pas, le
-- harnais n'applique pas la RLS et le reste de la sortie est sans valeur,
-- quelle que soit sa couleur. Lire le témoin AVANT de lire les verdicts.
--
-- PROTECTION DES DONNÉES RÉELLES. Le script tente de vrais UPDATE et de
-- vrais DELETE. Si la RLS était cassée, ils aboutiraient. Toute écriture
-- vise donc une ligne de test précise par `where id = ...`, jamais une table
-- entière, et les suppressions passent en dernier pour qu'une cascade ne
-- masque pas les vérifications suivantes.
--
-- EXÉCUTION : copier-coller dans l'éditeur SQL du projet Supabase.
-- Le script se nettoie lui-même et le prouve par un compte final à zéro.
-- =========================================================================


-- -------------------------------------------------------------------------
-- 0. Table de résultats et nettoyage d'un éventuel passage précédent
-- -------------------------------------------------------------------------

drop table if exists audit_resultats;

create temporary table audit_resultats (
  moment             timestamptz not null default clock_timestamp(),
  identite           text,   -- qui agit
  utilisateur_pg     text,   -- current_user réellement effectif
  sub_claims         text,   -- le sub des claims JWT actives
  table_cible        text,
  operation          text,
  attendu            text,
  observe            text,
  verdict            text
);

-- Le rôle applicatif doit pouvoir écrire ses constats pendant qu'il est
-- endossé. La table est temporaire et sans RLS : elle disparaît avec la
-- session, elle n'est exposée par aucune API.
grant all on audit_resultats to authenticated, anon;

-- Purge défensive : si un passage précédent s'est interrompu, ses comptes de
-- test existent encore et fausseraient tout.
delete from auth.users
 where id in ('aaaaaaaa-0000-4000-8000-000000000001',
              'bbbbbbbb-0000-4000-8000-000000000002');


-- -------------------------------------------------------------------------
-- 1. Deux utilisateurs de test et leurs données, créés en propriétaire
--
-- Chacun reçoit une ligne dans chacune des 6 tables. Les identifiants sont
-- fixes pour que le nettoyage soit déterministe.
-- -------------------------------------------------------------------------

insert into auth.users
  (instance_id, id, aud, role, email, encrypted_password, created_at, updated_at)
values
  ('00000000-0000-0000-0000-000000000000', 'aaaaaaaa-0000-4000-8000-000000000001',
   'authenticated', 'authenticated', 'audit-a@carneo.invalid', '', now(), now()),
  ('00000000-0000-0000-0000-000000000000', 'bbbbbbbb-0000-4000-8000-000000000002',
   'authenticated', 'authenticated', 'audit-b@carneo.invalid', '', now(), now());

-- Plans personnels (user_id renseigné, donc modifiables par leur seul auteur)
insert into public.maintenance_plans (id, user_id, name, make, model, engine, source)
values
  ('aaaaaaaa-1111-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-000000000001',
   'Plan de test A', 'TestMarque', 'TestModele', 'TestMoteur', 'audit RLS'),
  ('bbbbbbbb-1111-4000-8000-000000000002', 'bbbbbbbb-0000-4000-8000-000000000002',
   'Plan de test B', 'TestMarque', 'TestModele', 'TestMoteur', 'audit RLS');

insert into public.plan_operations
  (id, maintenance_plan_id, name, category, interval_km, interval_months, criticality)
values
  ('aaaaaaaa-2222-4000-8000-000000000001', 'aaaaaaaa-1111-4000-8000-000000000001',
   'Operation de test A', 'moteur', 10000, 12, 'critique'),
  ('bbbbbbbb-2222-4000-8000-000000000002', 'bbbbbbbb-1111-4000-8000-000000000002',
   'Operation de test B', 'moteur', 10000, 12, 'critique');

insert into public.vehicles
  (id, user_id, maintenance_plan_id, make, model, year, fuel_type)
values
  ('aaaaaaaa-3333-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-000000000001',
   'aaaaaaaa-1111-4000-8000-000000000001', 'TestMarque', 'Vehicule A', 2020, 'essence'),
  ('bbbbbbbb-3333-4000-8000-000000000002', 'bbbbbbbb-0000-4000-8000-000000000002',
   'bbbbbbbb-1111-4000-8000-000000000002', 'TestMarque', 'Vehicule B', 2020, 'essence');

insert into public.documents
  (id, vehicle_id, storage_path, file_name, mime_type, size)
values
  ('aaaaaaaa-4444-4000-8000-000000000001', 'aaaaaaaa-3333-4000-8000-000000000001',
   'audit/a.pdf', 'a.pdf', 'application/pdf', 1024),
  ('bbbbbbbb-4444-4000-8000-000000000002', 'bbbbbbbb-3333-4000-8000-000000000002',
   'audit/b.pdf', 'b.pdf', 'application/pdf', 1024);

insert into public.maintenance_events
  (id, vehicle_id, label, performed_at, mileage)
values
  ('aaaaaaaa-5555-4000-8000-000000000001', 'aaaaaaaa-3333-4000-8000-000000000001',
   'Intervention de test A', date '2025-01-01', 10000),
  ('bbbbbbbb-5555-4000-8000-000000000002', 'bbbbbbbb-3333-4000-8000-000000000002',
   'Intervention de test B', date '2025-01-01', 10000);

insert into public.mileage_readings (id, vehicle_id, recorded_at, mileage)
values
  ('aaaaaaaa-6666-4000-8000-000000000001', 'aaaaaaaa-3333-4000-8000-000000000001',
   date '2025-01-01', 10000),
  ('bbbbbbbb-6666-4000-8000-000000000002', 'bbbbbbbb-3333-4000-8000-000000000002',
   date '2025-01-01', 10000);


-- -------------------------------------------------------------------------
-- 2. Témoin, première mesure : en propriétaire des tables
--
-- Attendu strictement positif. Si ce compte est à zéro, il n'y a rien en
-- base et l'audit ne teste rien.
-- -------------------------------------------------------------------------

insert into audit_resultats
  (identite, utilisateur_pg, sub_claims, table_cible, operation, attendu, observe, verdict)
select
  'TEMOIN, proprietaire des tables', current_user, '(aucune claim)',
  'vehicles', 'count(*)', 'strictement positif',
  count(*)::text,
  case when count(*) > 0 then 'OK' else 'ECHEC' end
from public.vehicles;


-- -------------------------------------------------------------------------
-- 3. Utilisateur A tente d'atteindre les données de l'utilisateur B
--
-- Ordre des opérations volontaire : tous les SELECT, puis les INSERT, puis
-- les UPDATE, et les DELETE en dernier (enfants avant parents), pour qu'une
-- suppression réussie ne vide pas les tables des vérifications suivantes.
--
-- Attendu par table :
--   vehicles, documents, maintenance_events, mileage_readings
--       isolation stricte, A ne voit ni ne touche rien de B.
--   maintenance_plans, plan_operations
--       lecture ouverte À DESSEIN (un plan est une référence partagée), donc
--       le SELECT doit RÉUSSIR. Seule l'écriture doit être refusée.
-- -------------------------------------------------------------------------

begin;

-- Bascule d'identité, hors du bloc plpgsql. C'est ce couple de lignes qui rend
-- l'audit crédible : sans lui, tout serait exécuté en postgres, propriétaire
-- des tables et porteur de BYPASSRLS.
select set_config(
  'request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-4000-8000-000000000001","role":"authenticated"}',
  true);
set local role authenticated;

do $$
declare
  v_sub      text;
  v_user     text;
  v_observe  text;
  v_lignes   integer;
begin
  v_user := current_user;
  v_sub  := current_setting('request.jwt.claims', true)::json ->> 'sub';

  -- --- Témoin, deuxième mesure : sous authenticated, A ne voit que son véhicule
  select count(*) into v_lignes from public.vehicles;
  insert into audit_resultats
    (identite, utilisateur_pg, sub_claims, table_cible, operation, attendu, observe, verdict)
  values ('TEMOIN, utilisateur A', v_user, v_sub, 'vehicles', 'count(*)',
          'exactement 1, le sien', v_lignes::text,
          case when v_lignes = 1 then 'OK' else 'ECHEC' end);

  -- ================= SELECT =================

  select count(*) into v_lignes from public.vehicles
    where id = 'bbbbbbbb-3333-4000-8000-000000000002';
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'vehicles', 'select', '0 ligne de B visible', v_lignes::text,
    case when v_lignes = 0 then 'OK' else 'ECHEC' end);

  select count(*) into v_lignes from public.documents
    where id = 'bbbbbbbb-4444-4000-8000-000000000002';
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'documents', 'select', '0 ligne de B visible', v_lignes::text,
    case when v_lignes = 0 then 'OK' else 'ECHEC' end);

  select count(*) into v_lignes from public.maintenance_events
    where id = 'bbbbbbbb-5555-4000-8000-000000000002';
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'maintenance_events', 'select', '0 ligne de B visible', v_lignes::text,
    case when v_lignes = 0 then 'OK' else 'ECHEC' end);

  select count(*) into v_lignes from public.mileage_readings
    where id = 'bbbbbbbb-6666-4000-8000-000000000002';
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'mileage_readings', 'select', '0 ligne de B visible', v_lignes::text,
    case when v_lignes = 0 then 'OK' else 'ECHEC' end);

  select count(*) into v_lignes from public.maintenance_plans
    where id = 'bbbbbbbb-1111-4000-8000-000000000002';
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'maintenance_plans', 'select', '1, lecture ouverte a dessein', v_lignes::text,
    case when v_lignes = 1 then 'OK' else 'ECHEC' end);

  select count(*) into v_lignes from public.plan_operations
    where id = 'bbbbbbbb-2222-4000-8000-000000000002';
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'plan_operations', 'select', '1, lecture ouverte a dessein', v_lignes::text,
    case when v_lignes = 1 then 'OK' else 'ECHEC' end);

  -- ================= INSERT =================
  -- A tente d'insérer des lignes appartenant à B. Une policy correcte lève
  -- « new row violates row-level security policy ».

  begin
    insert into public.vehicles (id, user_id, make, model, year, fuel_type)
    values ('cccccccc-3333-4000-8000-000000000003',
            'bbbbbbbb-0000-4000-8000-000000000002', 'Hack', 'Hack', 2020, 'essence');
    v_observe := 'ACCEPTE';
  exception when others then v_observe := 'bloque (' || sqlstate || ')';
  end;
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'vehicles', 'insert', 'refus', v_observe,
    case when v_observe like 'bloque%' then 'OK' else 'ECHEC' end);

  begin
    insert into public.documents (id, vehicle_id, storage_path, file_name, mime_type, size)
    values ('cccccccc-4444-4000-8000-000000000003',
            'bbbbbbbb-3333-4000-8000-000000000002', 'hack/x.pdf', 'x.pdf', 'application/pdf', 1);
    v_observe := 'ACCEPTE';
  exception when others then v_observe := 'bloque (' || sqlstate || ')';
  end;
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'documents', 'insert', 'refus', v_observe,
    case when v_observe like 'bloque%' then 'OK' else 'ECHEC' end);

  begin
    insert into public.maintenance_events (id, vehicle_id, label, performed_at, mileage)
    values ('cccccccc-5555-4000-8000-000000000003',
            'bbbbbbbb-3333-4000-8000-000000000002', 'Hack', date '2025-06-01', 1);
    v_observe := 'ACCEPTE';
  exception when others then v_observe := 'bloque (' || sqlstate || ')';
  end;
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'maintenance_events', 'insert', 'refus', v_observe,
    case when v_observe like 'bloque%' then 'OK' else 'ECHEC' end);

  begin
    insert into public.mileage_readings (id, vehicle_id, recorded_at, mileage)
    values ('cccccccc-6666-4000-8000-000000000003',
            'bbbbbbbb-3333-4000-8000-000000000002', date '2025-06-01', 1);
    v_observe := 'ACCEPTE';
  exception when others then v_observe := 'bloque (' || sqlstate || ')';
  end;
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'mileage_readings', 'insert', 'refus', v_observe,
    case when v_observe like 'bloque%' then 'OK' else 'ECHEC' end);

  begin
    insert into public.maintenance_plans (id, user_id, name, make, model, source)
    values ('cccccccc-1111-4000-8000-000000000003',
            'bbbbbbbb-0000-4000-8000-000000000002', 'Plan vole', 'Hack', 'Hack', 'audit');
    v_observe := 'ACCEPTE';
  exception when others then v_observe := 'bloque (' || sqlstate || ')';
  end;
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'maintenance_plans', 'insert', 'refus, plan au nom de B', v_observe,
    case when v_observe like 'bloque%' then 'OK' else 'ECHEC' end);

  begin
    insert into public.plan_operations
      (id, maintenance_plan_id, name, category, interval_months, criticality)
    values ('cccccccc-2222-4000-8000-000000000003',
            'bbbbbbbb-1111-4000-8000-000000000002', 'Op volee', 'moteur', 12, 'critique');
    v_observe := 'ACCEPTE';
  exception when others then v_observe := 'bloque (' || sqlstate || ')';
  end;
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'plan_operations', 'insert', 'refus, sur le plan de B', v_observe,
    case when v_observe like 'bloque%' then 'OK' else 'ECHEC' end);

  -- ================= UPDATE =================

  update public.vehicles set model = 'PIRATE'
    where id = 'bbbbbbbb-3333-4000-8000-000000000002';
  get diagnostics v_lignes = row_count;
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'vehicles', 'update', '0 ligne modifiee', v_lignes::text,
    case when v_lignes = 0 then 'OK' else 'ECHEC' end);

  update public.documents set file_name = 'PIRATE'
    where id = 'bbbbbbbb-4444-4000-8000-000000000002';
  get diagnostics v_lignes = row_count;
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'documents', 'update', '0 ligne modifiee', v_lignes::text,
    case when v_lignes = 0 then 'OK' else 'ECHEC' end);

  update public.maintenance_events set label = 'PIRATE'
    where id = 'bbbbbbbb-5555-4000-8000-000000000002';
  get diagnostics v_lignes = row_count;
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'maintenance_events', 'update', '0 ligne modifiee', v_lignes::text,
    case when v_lignes = 0 then 'OK' else 'ECHEC' end);

  update public.mileage_readings set mileage = 999999
    where id = 'bbbbbbbb-6666-4000-8000-000000000002';
  get diagnostics v_lignes = row_count;
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'mileage_readings', 'update', '0 ligne modifiee', v_lignes::text,
    case when v_lignes = 0 then 'OK' else 'ECHEC' end);

  update public.maintenance_plans set name = 'PIRATE'
    where id = 'bbbbbbbb-1111-4000-8000-000000000002';
  get diagnostics v_lignes = row_count;
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'maintenance_plans', 'update', '0 ligne modifiee', v_lignes::text,
    case when v_lignes = 0 then 'OK' else 'ECHEC' end);

  update public.plan_operations set name = 'PIRATE'
    where id = 'bbbbbbbb-2222-4000-8000-000000000002';
  get diagnostics v_lignes = row_count;
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'plan_operations', 'update', '0 ligne modifiee', v_lignes::text,
    case when v_lignes = 0 then 'OK' else 'ECHEC' end);

  -- Cas particulier : le plan PARTAGÉ (user_id NULL) ne doit être modifiable
  -- par personne. C'est la conséquence voulue de la migration RLS.
  update public.maintenance_plans set name = 'PIRATE'
    where user_id is null;
  get diagnostics v_lignes = row_count;
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'maintenance_plans', 'update partage', '0 ligne modifiee', v_lignes::text,
    case when v_lignes = 0 then 'OK' else 'ECHEC' end);

  -- ================= DELETE (en dernier, enfants avant parents) =================

  delete from public.maintenance_events
    where id = 'bbbbbbbb-5555-4000-8000-000000000002';
  get diagnostics v_lignes = row_count;
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'maintenance_events', 'delete', '0 ligne supprimee', v_lignes::text,
    case when v_lignes = 0 then 'OK' else 'ECHEC' end);

  delete from public.mileage_readings
    where id = 'bbbbbbbb-6666-4000-8000-000000000002';
  get diagnostics v_lignes = row_count;
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'mileage_readings', 'delete', '0 ligne supprimee', v_lignes::text,
    case when v_lignes = 0 then 'OK' else 'ECHEC' end);

  delete from public.documents
    where id = 'bbbbbbbb-4444-4000-8000-000000000002';
  get diagnostics v_lignes = row_count;
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'documents', 'delete', '0 ligne supprimee', v_lignes::text,
    case when v_lignes = 0 then 'OK' else 'ECHEC' end);

  delete from public.plan_operations
    where id = 'bbbbbbbb-2222-4000-8000-000000000002';
  get diagnostics v_lignes = row_count;
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'plan_operations', 'delete', '0 ligne supprimee', v_lignes::text,
    case when v_lignes = 0 then 'OK' else 'ECHEC' end);

  delete from public.maintenance_plans
    where id = 'bbbbbbbb-1111-4000-8000-000000000002';
  get diagnostics v_lignes = row_count;
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'maintenance_plans', 'delete', '0 ligne supprimee', v_lignes::text,
    case when v_lignes = 0 then 'OK' else 'ECHEC' end);

  delete from public.vehicles
    where id = 'bbbbbbbb-3333-4000-8000-000000000002';
  get diagnostics v_lignes = row_count;
  insert into audit_resultats values (default, 'utilisateur A', v_user, v_sub,
    'vehicles', 'delete', '0 ligne supprimee', v_lignes::text,
    case when v_lignes = 0 then 'OK' else 'ECHEC' end);
end $$;

reset role;
commit;


-- -------------------------------------------------------------------------
-- 4. Le visiteur non authentifié
--
-- Aucune policy n'accorde quoi que ce soit au rôle `anon`. Il ne doit rien
-- voir et ne rien pouvoir écrire.
-- -------------------------------------------------------------------------

begin;

select set_config('request.jwt.claims', '', true);
set local role anon;

do $$
declare
  v_user    text;
  v_observe text;
  v_verdict text;
  v_lignes  integer;
begin
  v_user := current_user;

  -- Témoin, troisième mesure. C'est LA ligne qui valide tout le harnais :
  -- le propriétaire voit plusieurs véhicules, l'anonyme ne doit en voir aucun.
  --
  -- Deux issues sont acceptables, et la seconde est la plus forte :
  --   0 ligne  : la RLS a filtré, aucune policy n'ouvre quoi que ce soit à anon.
  --   42501    : PostgreSQL a refusé un cran plus tôt, faute de privilège de
  --              table. C'est le choix assumé de la migration
  --              20260829130000 : anon ne reçoit AUCUN droit, ce qui lui
  --              oppose deux barrières indépendantes au lieu d'une.
  -- Toute autre issue (un compte non nul) est un échec.
  begin
    select count(*) into v_lignes from public.vehicles;
    v_observe := v_lignes::text || ' ligne(s) visibles';
    if v_lignes = 0 then v_verdict := 'OK'; else v_verdict := 'ECHEC'; end if;
  exception when insufficient_privilege then
    v_observe := 'acces refuse (42501, aucun privilege)'; v_verdict := 'OK';
  end;
  insert into audit_resultats values (default, 'TEMOIN, anonyme', v_user, '(aucune claim)',
    'vehicles', 'count(*)', '0 ligne ou acces refuse', v_observe, v_verdict);

  begin
    select count(*) into v_lignes from public.maintenance_plans;
    v_observe := v_lignes::text || ' ligne(s) visibles';
    if v_lignes = 0 then v_verdict := 'OK'; else v_verdict := 'ECHEC'; end if;
  exception when insufficient_privilege then
    v_observe := 'acces refuse (42501, aucun privilege)'; v_verdict := 'OK';
  end;
  insert into audit_resultats values (default, 'anonyme', v_user, '(aucune claim)',
    'maintenance_plans', 'select', '0 ligne ou acces refuse, meme les plans partages',
    v_observe, v_verdict);

  begin
    insert into public.vehicles (id, user_id, make, model, year, fuel_type)
    values ('cccccccc-9999-4000-8000-000000000009',
            'aaaaaaaa-0000-4000-8000-000000000001', 'Hack', 'Hack', 2020, 'essence');
    v_observe := 'ACCEPTE';
  exception when others then v_observe := 'bloque (' || sqlstate || ')';
  end;
  insert into audit_resultats values (default, 'anonyme', v_user, '(aucune claim)',
    'vehicles', 'insert', 'refus', v_observe,
    case when v_observe like 'bloque%' then 'OK' else 'ECHEC' end);
end $$;

reset role;
commit;


-- -------------------------------------------------------------------------
-- 5. Nettoyage, et preuve du nettoyage versée aux résultats
--
-- La suppression des deux comptes cascade sur toutes leurs données.
-- Les lignes de sonde `cccccccc-...` sont supprimées explicitement : si la
-- RLS avait cédé, elles existeraient et n'appartiendraient à personne.
--
-- Le nettoyage passe AVANT l'affichage, parce que l'éditeur SQL de Supabase
-- ne rend que le résultat de la dernière requête. Tout doit donc tenir dans
-- un seul tableau final.
-- -------------------------------------------------------------------------

delete from public.vehicles           where id::text like 'cccccccc-%';
delete from public.maintenance_plans  where id::text like 'cccccccc-%';
delete from public.documents          where id::text like 'cccccccc-%';
delete from public.maintenance_events where id::text like 'cccccccc-%';
delete from public.mileage_readings   where id::text like 'cccccccc-%';
delete from public.plan_operations    where id::text like 'cccccccc-%';

delete from auth.users
 where id in ('aaaaaaaa-0000-4000-8000-000000000001',
              'bbbbbbbb-0000-4000-8000-000000000002');

insert into audit_resultats
  (identite, utilisateur_pg, sub_claims, table_cible, operation, attendu, observe, verdict)
select 'NETTOYAGE', current_user, '(aucune claim)', 'auth.users',
       'comptes de test restants', '0', n::text,
       case when n = 0 then 'OK' else 'ECHEC' end
  from (select count(*) as n from auth.users
         where email in ('audit-a@carneo.invalid', 'audit-b@carneo.invalid')) t;

insert into audit_resultats
  (identite, utilisateur_pg, sub_claims, table_cible, operation, attendu, observe, verdict)
select 'NETTOYAGE', current_user, '(aucune claim)', 'vehicles',
       'vehicules de test restants', '0', n::text,
       case when n = 0 then 'OK' else 'ECHEC' end
  from (select count(*) as n from public.vehicles
         where id::text like any (array['aaaaaaaa-%','bbbbbbbb-%','cccccccc-%'])) t;

insert into audit_resultats
  (identite, utilisateur_pg, sub_claims, table_cible, operation, attendu, observe, verdict)
select 'NETTOYAGE', current_user, '(aucune claim)', 'maintenance_plans',
       'plans de test restants', '0', n::text,
       case when n = 0 then 'OK' else 'ECHEC' end
  from (select count(*) as n from public.maintenance_plans
         where id::text like any (array['aaaaaaaa-%','bbbbbbbb-%','cccccccc-%'])) t;

-- Le script tente de vrais DELETE. Cette ligne prouve qu'il n'a rien abîmé
-- des données réelles.
insert into audit_resultats
  (identite, utilisateur_pg, sub_claims, table_cible, operation, attendu, observe, verdict)
select 'NETTOYAGE', current_user, '(aucune claim)', 'vehicles',
       'vehicules reels intacts', 'au moins 1', n::text,
       case when n >= 1 then 'OK' else 'ECHEC' end
  from (select count(*) as n from public.vehicles) t;


-- -------------------------------------------------------------------------
-- 6. Synthèse, versée elle aussi aux résultats pour tenir dans un tableau
--
-- Le témoin est lu AVANT les verdicts : s'il n'a pas basculé, le harnais
-- n'applique pas la RLS et le reste de la sortie ne prouve rien.
-- -------------------------------------------------------------------------

insert into audit_resultats
  (identite, utilisateur_pg, sub_claims, table_cible, operation, attendu, observe, verdict)
select
  'SYNTHESE', current_user, '(aucune claim)', '(toutes)', 'bilan',
  '0 echec, 3 temoins OK',
  verifications::text || ' verifications, ' || echecs::text || ' echec(s), '
    || temoins_ok::text || '/3 temoins OK',
  case
    when temoins_ok < 3 then 'HARNAIS INVALIDE, la sortie ne prouve rien'
    when echecs > 0     then 'RLS EN DEFAUT'
    else 'RLS VALIDEE'
  end
from (
  select
    count(*)                                                          as verifications,
    count(*) filter (where verdict = 'ECHEC')                         as echecs,
    count(*) filter (where identite like 'TEMOIN%' and verdict = 'OK') as temoins_ok
  from audit_resultats
) t;


-- -------------------------------------------------------------------------
-- 7. La sortie complète, en un seul tableau
--
-- La dernière ligne porte le verdict. Lire la colonne `utilisateur_pg` :
-- elle doit afficher `authenticated` puis `anon`, jamais `postgres` sur les
-- lignes de vérification. Si elle affiche `postgres`, le harnais n'a pas
-- basculé d'identité et tout le reste est décoratif.
-- -------------------------------------------------------------------------

select row_number() over (order by moment) as n,
       identite, utilisateur_pg, sub_claims,
       table_cible, operation, attendu, observe, verdict
  from audit_resultats
 order by moment;


-- -------------------------------------------------------------------------
-- 8. Bilan à deux colonnes
--
-- Le tableau détaillé ci-dessus est large et son verdict finit hors champ
-- dans l'éditeur Supabase, qui ne rend de toute façon que la dernière
-- requête. Ce bilan tient en deux colonnes : rien ne peut être coupé.
--
-- Ordre de lecture : les trois témoins d'abord. S'ils n'ont pas basculé, le
-- harnais n'applique pas la RLS et le verdict ne prouve rien.
-- -------------------------------------------------------------------------

select 'temoin 1, proprietaire' as cle,
       observe || '  ->  ' || verdict as valeur
  from audit_resultats where identite = 'TEMOIN, proprietaire des tables'
union all
select 'temoin 2, utilisateur A', observe || '  ->  ' || verdict
  from audit_resultats where identite = 'TEMOIN, utilisateur A'
union all
select 'temoin 3, anonyme', observe || '  ->  ' || verdict
  from audit_resultats where identite = 'TEMOIN, anonyme'
union all
select 'verifications', count(*)::text from audit_resultats
union all
select 'echecs', count(*) filter (where verdict = 'ECHEC')::text from audit_resultats
union all
select 'lignes en echec',
       coalesce(string_agg(table_cible || '/' || operation || ' (' || observe || ')', ' | '),
                'aucune')
  from audit_resultats where verdict = 'ECHEC'
union all
select 'identites effectivement endossees',
       string_agg(distinct utilisateur_pg, ', ')
  from audit_resultats
union all
select 'nettoyage', observe || ' compte(s) de test restant(s)  ->  ' || verdict
  from audit_resultats where operation = 'comptes de test restants'
union all
select 'donnees reelles', observe || ' vehicule(s) reel(s)  ->  ' || verdict
  from audit_resultats where operation = 'vehicules reels intacts'
union all
select 'VERDICT GLOBAL', verdict
  from audit_resultats where identite = 'SYNTHESE';
