-- ──────────────────────────────────────────────────────────────────────────────
-- Migration : création de la table public.profiles
-- À exécuter dans l'éditeur SQL de Supabase (https://supabase.com/dashboard)
-- ou via la CLI Supabase : supabase db push
--
-- Prérequis : désactiver la confirmation d'email dans
--   Authentication > Providers > Email > "Confirm email" = OFF
-- ──────────────────────────────────────────────────────────────────────────────

create table if not exists public.profiles (
  id          uuid        primary key references auth.users on delete cascade,
  email       text        unique not null,
  full_name   text        not null,
  role        text        not null default 'planteur'
                          check (role in ('planteur', 'administrateur')),
  region      text,
  plot_count  integer          not null default 0,
  total_area  double precision not null default 0.0,
  is_banned   boolean          not null default false,
  created_at  timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- SELECT : tout utilisateur authentifié peut lire tous les profils
--   (nécessaire pour que l'admin voie la liste des planteurs)
create policy "profiles_select"
  on public.profiles for select
  to authenticated
  using (true);

-- INSERT : chaque utilisateur crée uniquement son propre profil au moment
--   de l'inscription (auth.uid() correspond au nouvel id)
create policy "profiles_insert"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

-- UPDATE : tout utilisateur authentifié peut modifier un profil
--   (bannissement / mise à jour gérés côté admin ; l'accès UI est restreint
--   par rôle dans l'application Flutter)
create policy "profiles_update"
  on public.profiles for update
  to authenticated
  using (true);

-- DELETE : tout utilisateur authentifié peut supprimer un profil
--   (suppression réservée à l'écran admin dans l'application)
create policy "profiles_delete"
  on public.profiles for delete
  to authenticated
  using (true);

-- ──────────────────────────────────────────────────────────────────────────────
-- Compte administrateur par défaut
-- Étape 1 : créer le compte dans Authentication > Users > "Add user"
--   Email    : admin@gaia-ci.com
--   Password : admin123
-- Étape 2 : récupérer l'UUID généré, puis exécuter le bloc ci-dessous
--   en remplaçant '<UUID_ADMIN>' par la vraie valeur.
-- ──────────────────────────────────────────────────────────────────────────────

-- insert into public.profiles (id, email, full_name, role)
-- values (
--   '<UUID_ADMIN>',          -- UUID copié depuis Authentication > Users
--   'admin@gaia-ci.com',
--   'Administrateur GAÏA',
--   'administrateur'
-- );
