# Plan : Phase 2, schéma et données réelles

> PRD parent : `PRD.md` (section 7, Phase 2)
> Date : 2026-08-28
> Niveau Request Classification : FULL

## Cadrage retenu

Décisions prises au `/plan`, pour ne pas les rediscuter pendant l'exécution.

- **Auth minimale et non stylée.** Email plus mot de passe, une page `/login` brute, session par cookie, déconnexion. Elle existe uniquement pour que la RLS soit testable avec un vrai utilisateur. Les écrans définitifs viendront après `/design`, avant la Phase 3.
- **Pas de stack Supabase locale.** Docker n'est pas démarré sur le poste : `supabase link` puis `supabase db push` appliquent les migrations sur le projet hébergé. Le repo reste la source de vérité du schéma, aucune modification via l'interface Supabase.
- **Deux migrations distinctes**, structure d'abord, sécurité ensuite. Une migration qui mélange `CREATE TABLE` et `CREATE POLICY` est illisible à la relecture et impossible à corriger proprement.
- **Le lien facture vers intervention est porté par `maintenance_events.document_id`** (ADR-002). La table `documents` n'a pas de `maintenance_event_id`, contrairement à la section 4 du brief. Une visite au garage produit une facture et plusieurs interventions.
- **Propriété des plans d'entretien** : `maintenance_plans.user_id` est nullable. `NULL` signifie plan partagé, lisible par tout utilisateur authentifié et modifiable par personne. Le plan Ford entre comme plan partagé. C'est le point le plus discutable du schéma, il est explicitement soumis à `/challenge`.
- **Le plan constructeur est dépouillé et vérifié.** Source et justification des périodicités dans `docs/references/plan-entretien-ford-fiesta-6-1.25-82.md`. Le couple `interval_km` et `interval_months` exprime la totalité du carnet Ford, sans variante usage normal contre usage sévère : le schéma prévu tient, aucune colonne supplémentaire n'est requise pour ce plan. Vérification faite avant d'écrire la migration, comme le prévoyait la mitigation du PRD.
- **« Révision de base » est une seule opération, pas six.** Le carnet la définit comme un forfait (vidange, filtre à huile, contrôle, mise à niveau des fluides, remise à zéro du témoin, diagnostic électronique), le garage la facture sur une ligne unique, et l'extraction de la Phase 5 fera correspondre une ligne de facture à une opération. Le détail va dans `plan_operations.notes`. La découper produirait six lignes à échéance identique sur l'écran principal.
- **Aucune contrainte base sur le compteur qui recule.** Un relevé plus bas que le précédent peut être une correction légitime. C'est une alerte d'interface (Phase 4), pas un `CHECK`.
- **Pas d'user stories Given/When/Then.** La phase est à 90 % du schéma, le seul parcours est la connexion, couvert par le critère de la tâche 5.
- **Pas de Storage.** Le bucket privé des factures arrive en Phase 4 avec l'upload. La table `documents` existe dès maintenant parce que `maintenance_events` la référence, mais elle reste vide.

## Tâches

- [ ] **1. Migration du schéma.** Créer `supabase/migrations/{ts}_schema_initial.sql` : les 4 types enum (`fuel_type`, `operation_category` incluant `reglementaire`, `criticality`, `ocr_status`), les 6 tables, les clés étrangères, les index sur les colonnes de jointure et de tri, et un trigger `set_updated_at` partagé.
  *Fait quand* : le fichier existe et ne contient aucun `CREATE POLICY` ni `ENABLE ROW LEVEL SECURITY` ; `vehicles` porte `first_registration_date` et `purchase_price` (exigés par le PRD, absents du brief) ; `maintenance_events` porte `document_id` et un `grep -c "maintenance_event_id"` sur le fichier renvoie 0.

- [ ] **2. Migration RLS.** Créer `supabase/migrations/{ts}_rls.sql` : activation de la RLS sur les 6 tables et policies. Isolation par `auth.uid()` sur `vehicles`, `maintenance_events`, `mileage_readings`, `documents` (les trois dernières via le `vehicle_id` de leur véhicule). Lecture partagée et écriture interdite sur `maintenance_plans` et `plan_operations` quand `user_id IS NULL`. Dépend de la tâche 1.
  *Fait quand* : le fichier active la RLS sur les 6 tables, et chacune a au moins une policy pour chacune des quatre opérations (`select`, `insert`, `update`, `delete`), sauf les deux tables de plan partagé où l'absence de policy d'écriture sur les lignes `user_id IS NULL` est intentionnelle et commentée dans le fichier.

- [ ] **3. Lier la CLI au projet hébergé et appliquer les migrations.** Dépend des tâches 1 et 2.
  *Fait quand* : `npx supabase migration list` affiche les deux migrations présentes à la fois en `Local` et en `Remote` ; une requête sur `pg_tables` renvoie `rowsecurity = true` pour les 6 tables du schéma `public`.
  *Répartition* : le `project-ref` et le mot de passe de la base sont saisis **par David** dans son terminal, jamais dans la conversation.

- [ ] **4. Générer les types TypeScript.** Produire `src/types/database.ts` depuis le schéma hébergé et ajouter le script `npm run types:gen` au `package.json`. Dépend de la tâche 3.
  *Fait quand* : `src/types/database.ts` contient les 6 noms de tables et les 4 enums ; `npx tsc --noEmit` sort 0 erreur ; les deux clients de `src/lib/supabase/` sont typés avec `Database` et une lecture sur une colonne inexistante est refusée à la compilation (vérifié en introduisant volontairement l'erreur, puis en la retirant).

- [ ] **5. Authentification minimale.** Page `/login` (connexion et inscription), action de déconnexion, `middleware.ts` qui rafraîchit la session et protège les routes applicatives. Non stylée.
  *Fait quand* : depuis un navigateur déconnecté, `localhost:3000/vehicules` redirige vers `/login` ; après inscription puis connexion, la même URL répond 200 et affiche l'email de l'utilisateur ; la déconnexion ramène sur `/login` et la route protégée redirige à nouveau. Verdict OK du sous-agent `browser-verifier` sur ce parcours.

- [ ] **6. Seed des données réelles.** Écrire `supabase/seed.example.sql` (committé, valeurs fictives, sert de documentation du format et de base au compte de démo de la Phase 6) et `supabase/seed.local.sql` (gitignoré, vraies données). Y charger : le plan d'entretien Ford fourni par David, la Fiesta, les relevés kilométriques connus et les interventions récentes. Dépend des tâches 3 et 5.
  *Fait quand* : `git check-ignore supabase/seed.local.sql` renvoie le chemin et `git ls-files` ne le contient pas ; `seed.example.sql` ne contient ni plaque, ni nom de garage, ni montant réels ; après exécution la base contient 1 véhicule, 1 plan portant exactement 8 lignes `plan_operations` (les 7 opérations du carnet Ford plus le contrôle technique, conformément à `docs/references/plan-entretien-ford-fiesta-6-1.25-82.md`), au moins 3 relevés et au moins 3 interventions, toutes rattachées à l'utilisateur créé en tâche 5.
  *Dépendance humaine* : le contenu du carnet Ford (opérations, périodicités km et mois, criticité) est fourni par David au début de cette tâche.

- [ ] **7. Script d'audit RLS.** Écrire `scripts/audit-rls.sql` : deux utilisateurs de test, des données pour chacun, puis vérification table par table et opération par opération que l'un ne voit ni ne touche les données de l'autre, plus un cas anonyme non authentifié. Dépend de la tâche 6.
  *Fait quand* : le script est committé, exécuté dans l'éditeur SQL Supabase, et sa sortie affiche au moins 26 lignes de vérification (6 tables fois 4 opérations, plus les 2 cas anonymes) avec 0 ligne `ECHEC` ; il se termine par la suppression de ses utilisateurs et données de test, vérifiée par un `count` final à 0.

- [ ] **8. Preuve bout en bout depuis Next.js.** Une page serveur `/vehicules` qui liste le véhicule, le nom de son plan, son dernier relevé et ses interventions, en passant par le client serveur soumis à la RLS. Non stylée. Dépend des tâches 4, 5 et 6.
  *Fait quand* : connecté, la page affiche la Fiesta et ses interventions réelles ; `grep -r "SUPABASE_SECRET_KEY" src/` ne renvoie aucun résultat (la lecture passe par la RLS, pas par la clé secrète) ; `npm run lint`, `npx tsc --noEmit` et `npm run build` passent ; verdict OK du sous-agent `browser-verifier`.

## Critère de phase complète

- [ ] Les 8 tâches sont cochées
- [ ] Les 6 tables existent sur le projet hébergé, RLS active, créées uniquement par migration versionnée et committée
- [ ] `scripts/audit-rls.sql` rend 0 `ECHEC`
- [ ] Le modèle a été confronté aux vraies factures : soit aucun champ ne manque, soit une migration corrective a été ajoutée et l'écart est consigné dans les Découvertes
- [ ] Aucune donnée personnelle (plaque, garage, montants) n'est présente dans le dépôt distant

## Points ouverts soumis à `/challenge`

Trois questions restent ouvertes après le dépouillement du carnet constructeur. Aucune ne bloque l'écriture du schéma, toutes méritent d'être tranchées avant `/execute`.

**1. La première échéance du contrôle technique.** Elle tombe 4 ans après la première mise en circulation, les suivantes tous les 2 ans. Un couple `interval_km` et `interval_months` ne sait pas exprimer une première occurrence différente des suivantes. Deux pistes : ajouter une colonne `first_due_months` sur `plan_operations`, ou traiter le cas comme une règle du moteur en Phase 3. La règle elle-même sera revérifiée sur `service-public.fr` avant implémentation (mitigation inscrite au PRD).

**2. Deux périodicités non prouvées par le carnet.** Le kit de courroie de distribution (8 ans, 160 000 km) et la purge du liquide de refroidissement (10 ans, 200 000 km) n'apparaissent qu'une seule fois, mais le tableau constructeur s'arrête à 15 ans et 300 000 km : impossible de savoir si elles sont périodiques ou uniques. Elles sont modélisées comme périodiques par prudence. À confirmer.

**3. L'ancrage des échéances quand aucune intervention n'est connue.** Le moteur prévu calcule une échéance à partir de la dernière intervention. Or le carnet Ford est ancré sur l'âge du véhicule, et la Fiesta a été achetée d'occasion en 2018 avec un historique inconnu : la plupart des opérations n'ont aucune intervention de référence, donc aucune échéance calculable, donc l'état « inconnu ». Avec `first_registration_date`, on pourrait au contraire afficher ce que Ford aurait prescrit à ce jour, ce qui est plus informatif. C'est une question de moteur (Phase 3), mais elle se décide maintenant parce qu'elle peut demander une colonne. Cas concret : la Fiesta a 12 ans, la courroie était due à 8 ans, soit en 2022.

## Hors périmètre de cette phase

Reporté : bucket Storage et upload de factures (Phase 4), formulaires de saisie (Phase 4), `/design` et écrans soignés (avant Phase 3), Vitest et moteur d'échéances (Phase 3), alerte de compteur qui recule (Phase 4), compte de démonstration (Phase 6).

## Prochaine étape

`/challenge docs/plans/phase-2-plan.md` puis `/execute docs/plans/phase-2-plan.md`

## Découvertes (hors plan)

{Remplies par `/execute` au fil de l'eau.}
