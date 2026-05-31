-- ─────────────────────────────────────────────────────────────────────────────
-- Migration : likes et commentaires communautaires
-- À exécuter dans l'éditeur SQL Supabase (https://supabase.com/dashboard)
-- ─────────────────────────────────────────────────────────────────────────────
-- IMPORTANT : activer Realtime sur community_posts ET community_comments dans
--   Supabase Dashboard > Database > Replication (basculer les deux tables).
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Colonne likes sur community_posts (absente du déploiement initial) ────────
-- La table community_posts existe déjà mais sans la colonne likes.
-- ADD COLUMN IF NOT EXISTS est idempotent.

alter table public.community_posts
  add column if not exists likes int not null default 0;

-- ── Table community_likes ─────────────────────────────────────────────────────
-- Clé primaire composite (post_id, user_id) — un seul like par couple.

create table if not exists public.community_likes (
  post_id    uuid        not null references public.community_posts(id) on delete cascade,
  user_id    uuid        not null references auth.users(id)             on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

alter table public.community_likes enable row level security;

drop policy if exists "likes_select" on public.community_likes;
create policy "likes_select"
  on public.community_likes for select using (true);

drop policy if exists "likes_insert" on public.community_likes;
create policy "likes_insert"
  on public.community_likes for insert
  with check (auth.uid() = user_id);

drop policy if exists "likes_delete" on public.community_likes;
create policy "likes_delete"
  on public.community_likes for delete
  using (auth.uid() = user_id);

-- ── Trigger : maintient community_posts.likes à jour automatiquement ──────────

create or replace function public.sync_post_likes_count()
returns trigger language plpgsql security definer as $$
begin
  if tg_op = 'INSERT' then
    update public.community_posts
       set likes = likes + 1
     where id = new.post_id;
  elsif tg_op = 'DELETE' then
    update public.community_posts
       set likes = greatest(likes - 1, 0)
     where id = old.post_id;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_sync_post_likes on public.community_likes;
create trigger trg_sync_post_likes
  after insert or delete on public.community_likes
  for each row execute function public.sync_post_likes_count();

-- ── Table community_comments ──────────────────────────────────────────────────

create table if not exists public.community_comments (
  id         uuid        primary key default gen_random_uuid(),
  post_id    uuid        not null references public.community_posts(id) on delete cascade,
  user_id    uuid        not null references auth.users(id)             on delete cascade,
  user_name  text        not null,
  content    text        not null,
  created_at timestamptz not null default now()
);

alter table public.community_comments enable row level security;

drop policy if exists "comments_select" on public.community_comments;
create policy "comments_select"
  on public.community_comments for select using (true);

drop policy if exists "comments_insert" on public.community_comments;
create policy "comments_insert"
  on public.community_comments for insert
  with check (auth.uid() = user_id);

drop policy if exists "comments_delete" on public.community_comments;
create policy "comments_delete"
  on public.community_comments for delete
  using (auth.uid() = user_id);
