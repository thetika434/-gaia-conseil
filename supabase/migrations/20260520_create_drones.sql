create table if not exists public.drones (
  id                  text primary key,
  owner_id            uuid not null references public.profiles(id) on delete cascade,
  owner_name          text not null,
  status              text not null default 'offline',
  battery_level       int  not null default 100,
  location            text not null default '',
  last_seen           timestamptz not null default now(),
  modele              text,
  missions_totales    int  not null default 0,
  surface_surveillee  double precision not null default 0.0,
  created_at          timestamptz not null default now()
);

alter table public.drones enable row level security;

-- Admins and the owning user can read drones
create policy "drones_select" on public.drones
  for select using (true);

-- Service role inserts/updates during sync (called server-side or via anon with RLS bypassed)
create policy "drones_insert" on public.drones
  for insert with check (auth.uid() = owner_id);

create policy "drones_update" on public.drones
  for update using (auth.uid() = owner_id);
