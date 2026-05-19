-- GAIA-Conseil messaging setup
-- Run this in Supabase Dashboard > SQL Editor.

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_key text not null,
  sender_name text not null,
  sender_role text not null check (sender_role in ('user', 'admin')),
  kind text not null default 'text' check (kind in ('text', 'attachment', 'voice')),
  content text not null,
  file_url text,
  file_name text,
  mime_type text,
  created_at timestamptz not null default now()
);

create index if not exists messages_conversation_created_idx
  on public.messages (conversation_key, created_at);

alter table public.messages enable row level security;

drop policy if exists "Allow public demo read messages" on public.messages;
create policy "Allow public demo read messages"
  on public.messages
  for select
  using (true);

drop policy if exists "Allow public demo insert messages" on public.messages;
create policy "Allow public demo insert messages"
  on public.messages
  for insert
  with check (true);

insert into storage.buckets (id, name, public)
values ('message-attachments', 'message-attachments', true)
on conflict (id) do update set public = true;

drop policy if exists "Allow public demo read attachments" on storage.objects;
create policy "Allow public demo read attachments"
  on storage.objects
  for select
  using (bucket_id = 'message-attachments');

drop policy if exists "Allow public demo upload attachments" on storage.objects;
create policy "Allow public demo upload attachments"
  on storage.objects
  for insert
  with check (bucket_id = 'message-attachments');
