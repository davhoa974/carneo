# Plan : Phase 2, schéma et données réelles

> PRD parent : `PRD.md` (section 7, Phase 2)
> Date : 2026-08-28
> Niveau Request Classification : FULL
> Révisé le 2026-08-28 après `/challenge` (verdict REWORK). Les modifications sont tracées en fin de fichier.

## Cadrage retenu

Décisions prises au `/plan`, pour ne pas les rediscuter pendant l'exécution.

- **Auth minimale et non stylée.** Email plus mot de passe, une page `/login` brute, session par cookie, déconnexion. Elle existe uniquement pour que la RLS soit testable avec un vrai utilisateur. Les écrans définitifs viendront après `/design`, avant la Phase 3.
- **Pas de stack Supabase locale.** Docker n'est pas démarré sur le poste : `supabase link` puis `supabase db push` appliquent les migrations sur le projet hébergé. Le repo reste la source de vérité du schéma, aucune modification via l'interface Supabase.
- **Deux migrations distinctes**, structure d'abord, sécurité ensuite. Une migration qui mélange `CREATE TABLE` et `CREATE POLICY` est illisible à la relecture et impossible à corriger proprement.
- **Le lien facture vers intervention est porté par `maintenance_events.document_id`** (ADR-002). La table `documents` n'a pas de `maintenance_event_id`, contrairement à la section 4 du brief. Une visite au garage produit une facture et plusieurs interventions.
- **Propriété des plans d'entretien** : `maintenance_plans.user_id` est nullable. `NULL` signifie plan partagé, lisible par tout utilisateur authentifié et modifiable par personne. Le plan Ford entre comme plan partagé. Un utilisateur peut en revanche créer et modifier ses propres plans, ceux dont il porte le `user_id` (tranché au `/challenge`, voir tâche 2).
- **Le plan constructeur est dépouillé et vérifié.** Source et justification des périodicités dans `docs/references/plan-entretien-ford-fiesta-6-1.25-82.md`. Le couple `interval_km` et `interval_months` exprime la quasi-totalité du carnet Ford. Seule exception, la première échéance du contrôle technique, qui reçoit une colonne dédiée `first_due_months` (tranché au `/challenge`).
- **Les périodicités déduites sont marquées comme telles.** Le kit de courroie et la purge du liquide de refroidissement n'apparaissent qu'une fois dans le carnet. Ils restent modélisés comme périodiques, et `plan_operations.notes` porte la mention « périodicité déduite, non confirmée par le carnet » pour que la Phase 3 puisse l'afficher au lieu de la présenter comme une certitude.
- **« Révision de base » est une seule opération, pas six.** Le carnet la définit comme un forfait (vidange, filtre à huile, contrôle, mise à niveau des fluides, remise à zéro du témoin, diagnostic électronique), le garage la facture sur une ligne unique, et l'extraction de la Phase 5 fera correspondre une ligne de facture à une opération. Le détail va dans `plan_operations.notes`. La découper produirait six lignes à échéance identique sur l'écran principal.
- **Aucune contrainte base sur le compteur qui recule.** Un relevé plus bas que le précédent peut être une correction légitime. C'est une alerte d'interface (Phase 4), pas un `CHECK`.
- **Pas d'user stories Given/When/Then.** La phase est à 90 % du schéma, le seul parcours est la connexion, couvert par le critère de la tâche 5.
- **Pas de Storage.** Le bucket privé des factures arrive en Phase 4 avec l'upload. La table `documents` existe dès maintenant parce que `maintenance_events` la référence, mais elle reste vide.

## Prérequis à vérifier avant `/execute`

Trois hypothèses relevées par `/challenge`. Aucune ne demande de code, toutes bloquent une tâche si elles sont fausses. À faire dans l'ordre, comptez 10 minutes.

- [ ] **P1. Confirmation d'email désactivée sur le projet hébergé.** Elle est active par défaut : `signUp` ne rendrait alors aucune session et la connexion échouerait sur `Email not confirmed`, ce qui bloque les tâches 5, 6 et 8. Dashboard Supabase, Authentication, Sign In / Providers, Email, interrupteur « Confirm email ». La désactiver pour la Phase 2, la réactiver avant la mise en démo publique de la Phase 6.
- [ ] **P2. Un `INSERT` dans `auth.users` passe depuis l'éditeur SQL.** La table appartient à `supabase_auth_admin` et porte des colonnes `NOT NULL` sans défaut. Tester un `INSERT` minimal suivi de son `DELETE` avant d'écrire la tâche 7. Si ça bloque, créer les deux comptes de test via l'interface Auth du dashboard et ne mettre que leurs UUID dans le script.
- [ ] **P3. Les données réelles de la tâche 6 sont disponibles.** Compter les factures et les photos de compteur en main. Le critère de la tâche 6 exige au moins 3 relevés datés et au moins 3 interventions avec date et kilométrage. En dessous, revoir le seuil du critère plutôt que de le laisser incochable.

## Tâches

- [ ] **1. Migration du schéma.** Créer `supabase/migrations/{ts}_schema_initial.sql` : les 4 types enum (`fuel_type`, `operation_category` incluant `reglementaire`, `criticality`, `ocr_status`), les 6 tables, les clés étrangères, les index sur les colonnes de jointure et de tri, et un trigger `set_updated_at` partagé.
  *Fait quand* : le fichier existe et ne contient aucun `CREATE POLICY` ni `ENABLE ROW LEVEL SECURITY` ; un `grep -c "maintenance_event_id"` sur le fichier renvoie 0 ; et chacune des colonnes du tableau ci-dessous est retrouvée dans le fichier, table par table.

  | Table | Colonnes attendues |
  |---|---|
  | `vehicles` | `id`, `user_id`, `maintenance_plan_id` (nullable), `make`, `model`, `year`, `engine`, `fuel_type`, `first_registration_date`, `purchase_date`, `purchase_mileage`, `purchase_price`, `plate` (nullable), `created_at`, `updated_at` |
  | `maintenance_plans` | `id`, `user_id` (nullable), `name`, `make`, `model`, `year_from`, `year_to`, `engine`, `source`, `created_at`, `updated_at` |
  | `plan_operations` | `id`, `maintenance_plan_id`, `name`, `category`, `interval_km` (nullable), `interval_months` (nullable), `first_due_months` (nullable), `criticality`, `notes`, `created_at`, `updated_at` |
  | `maintenance_events` | `id`, `vehicle_id`, `plan_operation_id` (nullable), `document_id` (nullable), `label`, `performed_at`, `mileage`, `cost`, `garage`, `notes`, `created_at`, `updated_at` |
  | `mileage_readings` | `id`, `vehicle_id`, `recorded_at`, `mileage`, `created_at`, `updated_at` |
  | `documents` | `id`, `vehicle_id`, `storage_path`, `file_name`, `mime_type`, `size`, `uploaded_at`, `ocr_status`, `ocr_data`, `created_at`, `updated_at` |

  Le contrôle sur deux colonnes seulement (`first_registration_date` et `purchase_price`) laissait passer une table amputée de `purchase_mileage` ou `purchase_date`. Le tableau ferme ce trou.

- [ ] **2. Migration RLS.** Créer `supabase/migrations/{ts}_rls.sql` : activation de la RLS sur les 6 tables et policies. Isolation par `auth.uid()` sur `vehicles`, `maintenance_events`, `mileage_readings`, `documents` (les trois dernières via le `vehicle_id` de leur véhicule). Sur `maintenance_plans` et `plan_operations`, deux régimes coexistent : lecture ouverte à tout utilisateur authentifié, écriture réservée au propriétaire, donc jamais possible sur les lignes `user_id IS NULL`. Dépend de la tâche 1.
  *Fait quand* : le fichier active la RLS sur les 6 tables, et chacune porte au moins une policy pour chacune des quatre opérations (`select`, `insert`, `update`, `delete`), y compris les deux tables de plan dont les policies d'écriture sont qualifiées par `user_id = auth.uid()` (`plan_operations` via le `maintenance_plan_id` de son plan). Un commentaire dans le fichier explique que cette qualification rend les lignes partagées non modifiables sans policy dédiée.
  *Pourquoi* : la version précédente du critère excusait les deux tables de plan de toute policy d'écriture. Lue au pied de la lettre, elle interdisait à un utilisateur de jamais créer son propre plan, alors que le PRD le prévoit. Trois policies écrites maintenant valent une migration corrective plus tard.

- [ ] **3. Lier la CLI au projet hébergé et appliquer les migrations.** Dépend des tâches 1 et 2.
  *Fait quand* : `npx supabase migration list` affiche les deux migrations présentes à la fois en `Local` et en `Remote` ; une requête sur `pg_tables` renvoie `rowsecurity = true` pour les 6 tables du schéma `public`.
  *Répartition* : le `project-ref` et le mot de passe de la base sont saisis **par David** dans son terminal, jamais dans la conversation.

- [ ] **4. Générer les types TypeScript.** Produire `src/types/database.ts` depuis le schéma hébergé et ajouter le script `npm run types:gen` au `package.json`. Dépend de la tâche 3.
  *Fait quand* : `src/types/database.ts` contient les 6 noms de tables et les 4 enums ; `npx tsc --noEmit` sort 0 erreur ; les deux clients de `src/lib/supabase/` sont typés avec `Database` et une lecture sur une colonne inexistante est refusée à la compilation (vérifié en introduisant volontairement l'erreur, puis en la retirant).

- [ ] **5. Authentification minimale.** Page `/login` (connexion et inscription), action de déconnexion, et `proxy.ts` à la racine de `src/` qui rafraîchit la session et redirige les routes applicatives. Non stylée. Suppose P1 vérifié.
  *Convention Next 16* : le fichier s'appelle `proxy.ts` et exporte une fonction `proxy`, pas `middleware.ts` / `middleware`. Vérifié dans `node_modules/next/dist/docs/01-app/02-guides/upgrading/version-16.md` : le nom `middleware` est déprécié depuis Next 16, le projet est en `next@16.3.3`. Les guides `@supabase/ssr` en circulation sont encore écrits sur l'ancien nom, il faut les transposer.
  *Le proxy ne fait pas autorité* : la même page `node_modules/next/dist/docs/01-app/01-getting-started/16-proxy.md` précise que cette couche n'est pas une solution de gestion de session ni d'autorisation. La redirection qu'elle opère est un confort d'affichage. La garantie tient à deux autres endroits : l'appel `supabase.auth.getUser()` dans la page serveur elle-même, et la RLS.
  *Fait quand* : depuis un navigateur déconnecté, `localhost:3000/vehicules` redirige vers `/login` ; après inscription puis connexion, la même URL répond 200 et affiche l'email de l'utilisateur ; la déconnexion ramène sur `/login` et la route protégée redirige à nouveau ; la page `/vehicules` appelle elle-même `getUser()` et redirige vers `/login` si la session est absente, ce qui est vérifié en désactivant temporairement le `proxy.ts` (le comportement doit être inchangé, puis le proxy est remis). Verdict OK du sous-agent `browser-verifier` sur ce parcours.

- [ ] **6. Seed des données réelles.** Écrire `supabase/seed.example.sql` (committé, valeurs fictives, sert de documentation du format et de base au compte de démo de la Phase 6) et `supabase/seed.local.sql` (gitignoré, vraies données). Y charger : le plan d'entretien Ford, la Fiesta, les relevés kilométriques connus et les interventions récentes. Dépend des tâches 3 et 5. Suppose P3 vérifié.
  *Exécution* : il n'y a pas de stack locale, donc pas de `supabase db reset`, et `supabase db push` ne joue pas les seeds. Les deux fichiers sont exécutés **par David, par copier-coller dans l'éditeur SQL du projet hébergé**. Ce sont des scripts idempotents (`on conflict do nothing` sur les clés naturelles), pour pouvoir être rejoués sans dupliquer.
  *Sous-étape préalable* : récupérer l'UUID de l'utilisateur créé en tâche 5 (`select id, email from auth.users;`) et le déclarer une seule fois en tête de `seed.local.sql`, dans un `\set` ou une CTE, jamais recopié à chaque `INSERT`.
  *Statut de `seed.example.sql`* : il ne peut pas être joué tel quel puisqu'il ne connaît aucun UUID réel. Il porte en tête un commentaire disant explicitement qu'il documente le format et sert de matrice au seed de démo de la Phase 6, et qu'il attend un `user_id` à substituer. Sa validité est vérifiée par relecture, pas par exécution.
  *Fait quand* : `git check-ignore supabase/seed.local.sql` renvoie le chemin et `git ls-files` ne le contient pas ; `seed.example.sql` ne contient ni plaque, ni nom de garage, ni montant réels ; après exécution de `seed.local.sql` la base contient 1 véhicule, 1 plan portant exactement 8 lignes `plan_operations` (les 7 opérations du carnet Ford plus le contrôle technique, conformément à `docs/references/plan-entretien-ford-fiesta-6-1.25-82.md`), au moins 3 relevés et au moins 3 interventions, toutes rattachées à l'utilisateur de la tâche 5 ; la ligne du contrôle technique porte `first_due_months = 48`, `interval_months = 24` et `interval_km IS NULL` ; les lignes du kit de courroie et de la purge du liquide de refroidissement portent en `notes` la mention « périodicité déduite, non confirmée par le carnet » ; un second passage du script ne change aucun compte.

- [ ] **7. Script d'audit RLS.** Écrire `scripts/audit-rls.sql` : deux utilisateurs de test, des données pour chacun, puis vérification table par table et opération par opération que l'un ne voit ni ne touche les données de l'autre, plus un cas anonyme non authentifié. Dépend de la tâche 6. Suppose P2 vérifié.
  *Le piège à éviter* : l'éditeur SQL de Supabase exécute en `postgres`, propriétaire des tables et porteur de `BYPASSRLS`. Un script écrit naïvement compare ce que voit `postgres` à ce que voit `postgres`, rend 26 lignes vertes et ne prouve rien. Chaque bloc de vérification doit donc être encadré par `select set_config('request.jwt.claims', '{"sub":"<uuid>","role":"authenticated"}', true);` puis `set local role authenticated;`, et le cas anonyme par `set local role anon;`, le tout dans une transaction dont le rôle est rendu ensuite.
  *Fait quand* : le script est committé, exécuté dans l'éditeur SQL Supabase, et sa sortie affiche au moins 26 lignes de vérification (6 tables fois 4 opérations, plus les 2 cas anonymes) avec 0 ligne `ECHEC`. Chaque bloc affiche en tête le `current_user` effectif et le `sub` des claims actives, pour qu'on lise dans la sortie sous quelle identité la vérification a tourné. Le script porte en plus un **témoin** : `select count(*) from vehicles` compté avant tout `set role` doit être strictement positif, et le même count sous rôle `anon` doit valoir 0. Si ce témoin ne bascule pas, le harnais n'applique pas la RLS et le reste de la sortie est sans valeur, quelle que soit sa couleur. Le script se termine par la suppression de ses utilisateurs et données de test, vérifiée par un `count` final à 0.

- [ ] **8. Preuve bout en bout depuis Next.js.** Une page serveur `/vehicules` qui liste le véhicule, le nom de son plan, son dernier relevé et ses interventions, en passant par le client serveur soumis à la RLS. Non stylée. Dépend des tâches 4, 5 et 6.
  *Fait quand* : connecté, la page affiche la Fiesta et ses interventions réelles ; `grep -r "SUPABASE_SECRET_KEY" src/` ne renvoie aucun résultat (la lecture passe par la RLS, pas par la clé secrète) ; `npm run lint`, `npx tsc --noEmit` et `npm run build` passent sans avertissement de dépréciation sur le nom du fichier proxy ; verdict OK du sous-agent `browser-verifier`.

## Critère de phase complète

- [ ] Les 3 prérequis P1 à P3 sont cochés
- [ ] Les 8 tâches sont cochées
- [ ] Les 6 tables existent sur le projet hébergé, RLS active, créées uniquement par migration versionnée et committée
- [ ] `scripts/audit-rls.sql` rend 0 `ECHEC` **et** son témoin bascule (count positif en propriétaire, 0 en `anon`)
- [ ] Le modèle a été confronté aux vraies factures : soit aucun champ ne manque, soit une migration corrective a été ajoutée et l'écart est consigné dans les Découvertes
- [ ] Aucune donnée personnelle (plaque, garage, montants) n'est présente dans le dépôt distant

## Points tranchés au `/challenge`

Les trois questions ouvertes du plan initial, fermées le 2026-08-28.

**1. La première échéance du contrôle technique : une colonne `first_due_months`, pas une règle codée.** Elle tombe 4 ans après la première mise en circulation, les suivantes tous les 2 ans. Coût de la colonne aujourd'hui : un mot dans une migration pas encore écrite. Coût du report en Phase 3 : une migration corrective plus une exception codée pour un seul cas, non testable en donnée. Le PRD avait déjà tranché le principe en §8 (« périodicité stockée en donnée, pas en code »). Sémantique retenue : sans intervention connue et avec `first_due_months` non NULL, la première échéance vaut `first_registration_date + first_due_months`, puis `interval_months` prend le relais. La règle des 4 ans sera revérifiée sur `service-public.fr` avant l'implémentation du moteur.

**2. Les deux périodicités non prouvées restent périodiques, et le disent.** Le kit de courroie (8 ans, 160 000 km) et la purge du liquide de refroidissement (10 ans, 200 000 km) n'apparaissent qu'une fois, le tableau constructeur s'arrêtant à 15 ans et 300 000 km. L'asymétrie des conséquences tranche seule : sur la courroie, un faux « à faire » coûte une vérification au garage, un faux « à jour » coûte un moteur. Elles restent modélisées comme périodiques, avec la mention « périodicité déduite, non confirmée par le carnet » dans `notes`, que la Phase 3 affichera plutôt que de présenter l'échéance comme une certitude.

**3. L'ancrage sur l'âge du véhicule : rien à faire en Phase 2, le point est clos côté schéma.** Il restait ouvert parce qu'il pouvait demander une colonne. Vérification faite, non : `first_registration_date` est déjà au schéma et `first_due_months` couvre le cas particulier du contrôle technique. Calculer ce que Ford aurait prescrit à ce jour, par exemple la courroie due en 2022 sur une Fiesta de 12 ans, ne demande que ces deux colonnes et `interval_months`. C'est une décision de moteur, elle se prend en Phase 3 avec les tests sous les yeux.

## Hors périmètre de cette phase

Reporté : bucket Storage et upload de factures (Phase 4), formulaires de saisie (Phase 4), `/design` et écrans soignés (avant Phase 3), Vitest et moteur d'échéances (Phase 3), alerte de compteur qui recule (Phase 4), compte de démonstration (Phase 6).

## Révisions

- **2026-08-28, après `/challenge` (REWORK)** : ajout des prérequis P1 à P3 ; tâche 1, liste de colonnes attendues par table ; tâche 2, policies d'écriture sur les tables de plan qualifiées par `user_id = auth.uid()` ; tâche 5, `middleware.ts` remplacé par `proxy.ts` (Next 16) et garantie déplacée dans la page serveur ; tâche 6, canal d'exécution du seed et statut de `seed.example.sql` explicités ; tâche 7, harnais `set local role` et témoin de bascule rendus obligatoires ; les trois points ouverts tranchés.

## Prochaine étape

`/execute docs/plans/phase-2-plan.md`

## Découvertes (hors plan)

{Remplies par `/execute` au fil de l'eau.}
