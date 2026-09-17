-- Iranian cases support, user profiles, admin news management, Realtime and
-- the public app-assets image bucket. Strictly additive: no table is dropped
-- and no existing row is modified.

-- ---------------------------------------------------------------- case type
-- Afghan and Iranian case subscriptions live in the same table but never
-- collide: Iranian guides use the `ir_` id prefix and carry case_type.
alter table public.case_subscriptions
  add column if not exists case_type text not null default 'afghan'
  check (case_type in ('afghan', 'iranian'));

alter table public.special_notifications
  add column if not exists case_type text not null default 'afghan'
  check (case_type in ('afghan', 'iranian'));

-- ------------------------------------------------------------------ profiles
-- One row per authenticated user, written by the client after Google sign-in.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null default '',
  display_name text not null default '',
  avatar_url text not null default '',
  last_login timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.profiles enable row level security;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

create policy "users manage their own profile" on public.profiles
  for all to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- ------------------------------------------------------- admin news management
-- Until now the news/publishers tables had read-only policies, so no admin
-- could create or edit articles through the API.
create policy "admins manage news" on public.news
  for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admins manage publishers" on public.publishers
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- --------------------------------------------------------------- app assets
-- Public bucket for news/article images (metadata is public by design; the
-- service-role/admin uploads, everyone can read).
insert into storage.buckets (id, name, public)
values ('app-assets', 'app-assets', true)
on conflict (id) do update set public = true;

drop policy if exists "app assets are publicly readable" on storage.objects;
create policy "app assets are publicly readable" on storage.objects
  for select to anon, authenticated using (bucket_id = 'app-assets');
drop policy if exists "admins manage app assets" on storage.objects;
create policy "admins manage app assets" on storage.objects
  for all to authenticated
  using (bucket_id = 'app-assets' and public.is_admin())
  with check (bucket_id = 'app-assets' and public.is_admin());

-- ------------------------------------------------------------------ realtime
-- News changes are broadcast so the app can refresh without pull-to-refresh.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'news'
  ) then
    alter publication supabase_realtime add table public.news;
  end if;
end $$;
