-- Migration corrective (Phase 2, tâche 6, confrontation aux vraies factures).
--
-- Constat : une facture réelle du 30/06/2021 (vente de pièces au comptoir,
-- sans main-d'oeuvre) ne porte AUCUN kilométrage. Le champ existe sur le
-- document, il est laissé vide. Ce n'est pas un cas marginal : toutes les
-- factures magasin ont cette forme.
--
-- `maintenance_events.mileage` était NOT NULL, ce qui rendait cette
-- intervention impossible à saisir. Trois issues étaient possibles :
--   1. inventer un kilométrage par interpolation entre deux relevés connus,
--   2. refuser la saisie de l'intervention,
--   3. accepter que le kilométrage soit inconnu.
--
-- La 1 est exclue par le PRD : aucune donnée estimée ne doit être stockée
-- comme un fait. La 2 ferait perdre une intervention réelle, donc fausserait
-- les échéances dans le sens dangereux (une opération faite serait vue comme
-- jamais faite). Reste la 3.
--
-- Conséquence pour le moteur d'échéances (Phase 3) : une intervention sans
-- kilométrage alimente le critère des mois et ne peut pas alimenter celui des
-- kilomètres. C'est un état dégradé légitime, cohérent avec les trois états
-- d'échéance du PRD, et non une donnée cassée.
--
-- `mileage_readings.mileage` reste NOT NULL : un relevé sans compteur ne veut
-- rien dire, c'est sa raison d'être.

alter table public.maintenance_events
  alter column mileage drop not null;

comment on column public.maintenance_events.mileage is
  'Compteur au moment de l''intervention. NULL = inconnu, typiquement une '
  'facture de vente de pièces au comptoir qui ne relève pas le kilométrage. '
  'NULL n''est pas zéro : le moteur d''échéances doit traiter cette '
  'intervention sur le seul critère des mois.';
