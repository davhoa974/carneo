-- Migration : sécurité au niveau des lignes (Phase 2, tâche 2).
--
-- Deux régimes coexistent dans ce schéma.
--
--   1. Données personnelles (vehicles, maintenance_events, mileage_readings,
--      documents) : isolation stricte par auth.uid(). Un utilisateur ne voit
--      et ne touche que ses lignes. Les trois tables filles passent par le
--      user_id de leur véhicule, jamais par une colonne dupliquée.
--
--   2. Plans d'entretien (maintenance_plans, plan_operations) : lecture
--      ouverte à tout utilisateur authentifié, écriture réservée au
--      propriétaire.
--
--      CONSEQUENCE VOULUE : les policies d'écriture sont qualifiées par
--      user_id = auth.uid(). Une ligne partagée porte user_id IS NULL, donc
--      la comparaison rend NULL, donc elle n'est jamais modifiable ni
--      supprimable par qui que ce soit, y compris son créateur. C'est le
--      comportement recherché : le plan constructeur Ford est une référence
--      commune, il ne se corrige que par migration versionnée. Rendre une
--      ligne partagée modifiable demanderait une policy dédiée, écrite
--      exprès, à un rôle explicite.
--
-- auth.uid() est appelé sous la forme (select auth.uid()) : PostgreSQL évalue
-- alors l'expression une seule fois par requête (InitPlan) au lieu d'une fois
-- par ligne examinée.

alter table public.maintenance_plans enable row level security;
alter table public.plan_operations enable row level security;
alter table public.vehicles enable row level security;
alter table public.documents enable row level security;
alter table public.maintenance_events enable row level security;
alter table public.mileage_readings enable row level security;

-- ---------------------------------------------------------------------------
-- maintenance_plans : lecture commune, écriture au propriétaire
-- ---------------------------------------------------------------------------

create policy "maintenance_plans_select_authenticated"
  on public.maintenance_plans for select to authenticated
  using (true);

create policy "maintenance_plans_insert_own"
  on public.maintenance_plans for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy "maintenance_plans_update_own"
  on public.maintenance_plans for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "maintenance_plans_delete_own"
  on public.maintenance_plans for delete to authenticated
  using (user_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- plan_operations : suit la propriété de son plan
-- ---------------------------------------------------------------------------

create policy "plan_operations_select_authenticated"
  on public.plan_operations for select to authenticated
  using (true);

create policy "plan_operations_insert_own_plan"
  on public.plan_operations for insert to authenticated
  with check (
    exists (
      select 1 from public.maintenance_plans p
      where p.id = plan_operations.maintenance_plan_id
        and p.user_id = (select auth.uid())
    )
  );

create policy "plan_operations_update_own_plan"
  on public.plan_operations for update to authenticated
  using (
    exists (
      select 1 from public.maintenance_plans p
      where p.id = plan_operations.maintenance_plan_id
        and p.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.maintenance_plans p
      where p.id = plan_operations.maintenance_plan_id
        and p.user_id = (select auth.uid())
    )
  );

create policy "plan_operations_delete_own_plan"
  on public.plan_operations for delete to authenticated
  using (
    exists (
      select 1 from public.maintenance_plans p
      where p.id = plan_operations.maintenance_plan_id
        and p.user_id = (select auth.uid())
    )
  );

-- ---------------------------------------------------------------------------
-- vehicles : isolation stricte
-- ---------------------------------------------------------------------------

create policy "vehicles_select_own"
  on public.vehicles for select to authenticated
  using (user_id = (select auth.uid()));

create policy "vehicles_insert_own"
  on public.vehicles for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy "vehicles_update_own"
  on public.vehicles for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "vehicles_delete_own"
  on public.vehicles for delete to authenticated
  using (user_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- documents : isolation par le véhicule
-- ---------------------------------------------------------------------------

create policy "documents_select_own_vehicle"
  on public.documents for select to authenticated
  using (
    exists (
      select 1 from public.vehicles v
      where v.id = documents.vehicle_id
        and v.user_id = (select auth.uid())
    )
  );

create policy "documents_insert_own_vehicle"
  on public.documents for insert to authenticated
  with check (
    exists (
      select 1 from public.vehicles v
      where v.id = documents.vehicle_id
        and v.user_id = (select auth.uid())
    )
  );

create policy "documents_update_own_vehicle"
  on public.documents for update to authenticated
  using (
    exists (
      select 1 from public.vehicles v
      where v.id = documents.vehicle_id
        and v.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.vehicles v
      where v.id = documents.vehicle_id
        and v.user_id = (select auth.uid())
    )
  );

create policy "documents_delete_own_vehicle"
  on public.documents for delete to authenticated
  using (
    exists (
      select 1 from public.vehicles v
      where v.id = documents.vehicle_id
        and v.user_id = (select auth.uid())
    )
  );

-- ---------------------------------------------------------------------------
-- maintenance_events : isolation par le véhicule
-- ---------------------------------------------------------------------------

create policy "maintenance_events_select_own_vehicle"
  on public.maintenance_events for select to authenticated
  using (
    exists (
      select 1 from public.vehicles v
      where v.id = maintenance_events.vehicle_id
        and v.user_id = (select auth.uid())
    )
  );

create policy "maintenance_events_insert_own_vehicle"
  on public.maintenance_events for insert to authenticated
  with check (
    exists (
      select 1 from public.vehicles v
      where v.id = maintenance_events.vehicle_id
        and v.user_id = (select auth.uid())
    )
  );

create policy "maintenance_events_update_own_vehicle"
  on public.maintenance_events for update to authenticated
  using (
    exists (
      select 1 from public.vehicles v
      where v.id = maintenance_events.vehicle_id
        and v.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.vehicles v
      where v.id = maintenance_events.vehicle_id
        and v.user_id = (select auth.uid())
    )
  );

create policy "maintenance_events_delete_own_vehicle"
  on public.maintenance_events for delete to authenticated
  using (
    exists (
      select 1 from public.vehicles v
      where v.id = maintenance_events.vehicle_id
        and v.user_id = (select auth.uid())
    )
  );

-- ---------------------------------------------------------------------------
-- mileage_readings : isolation par le véhicule
-- ---------------------------------------------------------------------------

create policy "mileage_readings_select_own_vehicle"
  on public.mileage_readings for select to authenticated
  using (
    exists (
      select 1 from public.vehicles v
      where v.id = mileage_readings.vehicle_id
        and v.user_id = (select auth.uid())
    )
  );

create policy "mileage_readings_insert_own_vehicle"
  on public.mileage_readings for insert to authenticated
  with check (
    exists (
      select 1 from public.vehicles v
      where v.id = mileage_readings.vehicle_id
        and v.user_id = (select auth.uid())
    )
  );

create policy "mileage_readings_update_own_vehicle"
  on public.mileage_readings for update to authenticated
  using (
    exists (
      select 1 from public.vehicles v
      where v.id = mileage_readings.vehicle_id
        and v.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.vehicles v
      where v.id = mileage_readings.vehicle_id
        and v.user_id = (select auth.uid())
    )
  );

create policy "mileage_readings_delete_own_vehicle"
  on public.mileage_readings for delete to authenticated
  using (
    exists (
      select 1 from public.vehicles v
      where v.id = mileage_readings.vehicle_id
        and v.user_id = (select auth.uid())
    )
  );
