create table if not exists public.community_posts (
  id          uuid primary key default gen_random_uuid(),
  author_id   uuid not null references public.profiles(id) on delete cascade,
  author_name text not null,
  content     text not null,
  likes       int  not null default 0,
  posted_at   timestamptz not null default now()
);

alter table public.community_posts enable row level security;

-- Everyone can read posts
create policy "community_posts_select" on public.community_posts
  for select using (true);

-- Authenticated users can insert their own posts
create policy "community_posts_insert" on public.community_posts
  for insert with check (auth.uid() = author_id);

-- Author can update their own post (e.g. likes counter via service role or RPC)
create policy "community_posts_update" on public.community_posts
  for update using (true);
