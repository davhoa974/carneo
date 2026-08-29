-- Migration corrective (Phase 2, révélée par l'audit sécurité de `/validate`).
--
-- CONSTAT : `information_schema.role_table_grants` montre que le rôle `anon`
-- détient TRUNCATE, REFERENCES et TRIGGER sur les tables du schéma public,
-- alors que la migration 20260829130000 ne lui accordait délibérément rien.
-- Ces privilèges viennent de la configuration par défaut du projet hébergé,
-- appliquée avant nos migrations.
--
-- POURQUOI TRUNCATE EST LE POINT DUR. C'est une opération de TABLE, pas de
-- ligne : PostgreSQL ne lui applique AUCUNE policy. Les 24 policies de la
-- migration 20260828120100 ne protègent rien contre un TRUNCATE. Un rôle qui
-- le détient peut vider une table entière, quelle que soit la RLS.
--
-- La menace n'est pas immédiate, PostgREST n'expose par HTTP ni TRUNCATE ni
-- la création de triggers. Mais un privilège inutile qui neutralise la RLS
-- n'a aucune raison de rester, et le retirer coûte trois lignes.
--
-- PRINCIPE APPLIQUÉ : chaque rôle ne détient QUE ce dont l'application a
-- besoin. On révoque tout, puis on réaccorde explicitement.
--   anon           : rien du tout, aucune donnée de Carneo n'est publique.
--   authenticated  : les quatre opérations de ligne, et rien d'autre. Pas de
--                    TRUNCATE, donc pas de contournement possible de la RLS.
--   service_role   : inchangé. C'est le chemin serveur de confiance, porteur
--                    de BYPASSRLS, utilisé par le cron de la Phase 7 et le
--                    seed de démonstration de la Phase 6.

revoke all on
  public.maintenance_plans,
  public.plan_operations,
  public.vehicles,
  public.documents,
  public.maintenance_events,
  public.mileage_readings
from anon, authenticated;

grant select, insert, update, delete on
  public.maintenance_plans,
  public.plan_operations,
  public.vehicles,
  public.documents,
  public.maintenance_events,
  public.mileage_readings
to authenticated;

-- L'accès au schéma reste nécessaire à `authenticated` pour atteindre les
-- tables. Il est retiré à `anon`, qui n'a plus rien à y faire.
grant usage on schema public to authenticated;
revoke usage on schema public from anon;

-- Les tables futures ne doivent pas hériter du défaut de l'hébergeur.
alter default privileges in schema public revoke all on tables from anon;
alter default privileges in schema public revoke all on tables from authenticated;
alter default privileges in schema public
  grant select, insert, update, delete on tables to authenticated;
