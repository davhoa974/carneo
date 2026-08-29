-- Migration corrective (Phase 2, tâche 7, révélée par l'audit RLS).
--
-- CONSTAT : `select count(*) from public.vehicles` sous le rôle
-- `authenticated` échoue en 42501, « permission denied for table vehicles ».
-- Les deux premières migrations créent les tables et posent 24 policies, mais
-- n'accordent aucun PRIVILÈGE de table aux rôles applicatifs. PostgreSQL
-- refuse donc un cran avant la RLS, qui n'a jamais l'occasion de s'exprimer.
--
-- Ce n'était pas encore visible : aucune ligne de l'application ne lisait de
-- table jusqu'ici, la page /vehicules de la tâche 5 n'appelle que getUser().
-- La tâche 8 aurait échoué exactement de la même façon.
--
-- POURQUOI EXPLICITEMENT, ET PAS EN COMPTANT SUR LES DÉFAUTS. Supabase
-- configure des privilèges par défaut sur le schéma public, mais ils ne
-- s'appliquent qu'aux objets créés par le rôle qui les a déclarés. Un schéma
-- versionné ne doit pas dépendre d'un réglage implicite de l'hébergeur : les
-- droits font partie du schéma, ils sont donc écrits ici.
--
-- CE QUI N'EST DÉLIBÉRÉMENT PAS ACCORDÉ : le rôle `anon`. Aucune donnée de
-- Carneo n'a vocation à être lue sans authentification. Un visiteur non
-- connecté rencontre ainsi DEUX barrières indépendantes plutôt qu'une seule :
-- aucun privilège de table, et aucune policy. Le compte de démonstration de
-- la Phase 6 sera un utilisateur authentifié en lecture seule, pas un
-- anonyme. Si ce choix change, une ligne suffira, et elle devra être
-- accompagnée de policies dédiées.

grant usage on schema public to authenticated, service_role;

grant select, insert, update, delete on
  public.maintenance_plans,
  public.plan_operations,
  public.vehicles,
  public.documents,
  public.maintenance_events,
  public.mileage_readings
to authenticated;

-- `service_role` porte BYPASSRLS et sert au serveur : cron de la Phase 7,
-- seed du compte de démonstration de la Phase 6. Les privilèges lui sont
-- accordés maintenant pour ne pas rejouer la même surprise dans deux phases.
grant select, insert, update, delete on
  public.maintenance_plans,
  public.plan_operations,
  public.vehicles,
  public.documents,
  public.maintenance_events,
  public.mileage_readings
to service_role;

-- Toute table future créée par le rôle qui joue les migrations héritera de
-- ces droits, pour que l'oubli ne se reproduise pas à la prochaine table.
alter default privileges in schema public
  grant select, insert, update, delete on tables to authenticated, service_role;
