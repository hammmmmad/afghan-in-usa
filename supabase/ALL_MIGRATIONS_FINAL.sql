-- FINAL v2 script: archive old tables, create everything, migrate existing data.

------------------------------------------------------------

-- ============================================================ STEP 0: ARCHIVE
-- Old-schema tables are renamed (data preserved), then rows are copied into
-- the new-schema tables at STEP 2. The whole script runs in one transaction,
-- so any failure rolls everything back and the script can simply be re-run.
do $$
begin
  drop table if exists public.special_notifications cascade;

  if to_regclass('public.documents') is not null
     and to_regclass('public.documents_legacy_v1') is null then
    alter table public.documents rename to documents_legacy_v1;
  end if;

  if to_regclass('public.public_notifications') is not null
     and to_regclass('public.public_notifications_legacy_v1') is null then
    alter table public.public_notifications rename to public_notifications_legacy_v1;
  end if;
end $$;

------------------------------------------------------------
-- Documents, in-app notifications and FCM delivery metadata.
-- This migration is additive: no existing editorial rows or storage objects are
-- removed. Add administrators manually by inserting their auth.users UUID into
-- public.admin_users from the Supabase dashboard/service environment.

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now())
);

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admin_users where user_id = auth.uid()
  );
$$;

create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  title_i18n jsonb not null default '{"fa":"","en":""}'::jsonb
    check (jsonb_typeof(title_i18n) = 'object'),
  description_i18n jsonb not null default '{"fa":"","en":""}'::jsonb
    check (jsonb_typeof(description_i18n) = 'object'),
  storage_path text not null unique check (char_length(trim(storage_path)) > 0),
  file_url text not null default '',
  file_type text not null default 'pdf',
  size_bytes bigint not null default 0 check (size_bytes >= 0 and size_bytes <= 26214400),
  requires_login boolean not null default true,
  downloads integer not null default 0 check (downloads >= 0),
  status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  published_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint published_documents_require_date check (status <> 'published' or published_at is not null)
);

create index if not exists documents_public_feed_idx
  on public.documents (published_at desc) where status = 'published';

drop trigger if exists documents_set_updated_at on public.documents;
create trigger documents_set_updated_at before update on public.documents
for each row execute function public.set_updated_at();

create table if not exists public.public_notifications (
  id uuid primary key default gen_random_uuid(),
  title_i18n jsonb not null check (jsonb_typeof(title_i18n) = 'object'),
  body_i18n jsonb not null check (jsonb_typeof(body_i18n) = 'object'),
  data jsonb not null default '{}'::jsonb check (jsonb_typeof(data) = 'object'),
  status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  published_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint published_public_notifications_require_date check (status <> 'published' or published_at is not null)
);

create index if not exists public_notifications_feed_idx
  on public.public_notifications (published_at desc) where status = 'published';

drop trigger if exists public_notifications_set_updated_at on public.public_notifications;
create trigger public_notifications_set_updated_at before update on public.public_notifications
for each row execute function public.set_updated_at();

-- There is intentionally no anonymous SELECT policy on this table.
create table if not exists public.special_notifications (
  id uuid primary key default gen_random_uuid(),
  case_id text not null check (char_length(trim(case_id)) > 0),
  recipient_user_id uuid not null references auth.users(id) on delete cascade,
  title_i18n jsonb not null check (jsonb_typeof(title_i18n) = 'object'),
  body_i18n jsonb not null check (jsonb_typeof(body_i18n) = 'object'),
  data jsonb not null default '{}'::jsonb check (jsonb_typeof(data) = 'object'),
  created_at timestamptz not null default timezone('utc', now()),
  read_at timestamptz
);

create index if not exists special_notifications_recipient_idx
  on public.special_notifications (recipient_user_id, created_at desc);

-- A special notification is available only while its recipient has the bell
-- enabled for that case. Create this table before the policy below references
-- it, so a fresh `supabase db push` can apply the migration in one pass.
create table if not exists public.case_subscriptions (
  user_id uuid not null references auth.users(id) on delete cascade,
  case_id text not null check (char_length(trim(case_id)) > 0),
  active boolean not null default true,
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, case_id)
);

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  fcm_token text not null unique,
  platform text not null default 'android',
  active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists device_tokens_active_user_idx
  on public.device_tokens (user_id) where active = true;

drop trigger if exists device_tokens_set_updated_at on public.device_tokens;
create trigger device_tokens_set_updated_at before update on public.device_tokens
for each row execute function public.set_updated_at();

alter table public.admin_users enable row level security;
alter table public.documents enable row level security;
alter table public.public_notifications enable row level security;
alter table public.special_notifications enable row level security;
alter table public.device_tokens enable row level security;
alter table public.case_subscriptions enable row level security;

create policy "users can check their admin role" on public.admin_users
  for select to authenticated using (user_id = auth.uid());

create policy "published documents are publicly readable" on public.documents
  for select to anon, authenticated using (status = 'published');
create policy "admins manage documents" on public.documents
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "published public notifications are readable" on public.public_notifications
  for select to anon, authenticated using (status = 'published');
create policy "admins manage public notifications" on public.public_notifications
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "recipients read their special notifications" on public.special_notifications
  for select to authenticated using (
    recipient_user_id = auth.uid() and exists (
      select 1 from public.case_subscriptions s
      where s.user_id = auth.uid() and s.case_id = special_notifications.case_id
        and s.active = true
    )
  );
create policy "admins manage special notifications" on public.special_notifications
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "users manage their own device tokens" on public.device_tokens
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "users manage their own case subscriptions" on public.case_subscriptions
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "admins can inspect device tokens" on public.device_tokens
  for select to authenticated using (public.is_admin());
create policy "admins can inspect case subscriptions" on public.case_subscriptions
  for select to authenticated using (public.is_admin());

-- Private storage: reads are permitted only for paths attached to a published
-- document. This avoids exposing draft uploads via a public bucket URL.
insert into storage.buckets (id, name, public)
values ('documents', 'documents', false)
on conflict (id) do update set public = false;

create policy "published document files are readable" on storage.objects
  for select to authenticated using (
    bucket_id = 'documents' and exists (
      select 1 from public.documents d
      where d.storage_path = name and d.status = 'published'
    )
  );
create policy "admins manage document files" on storage.objects
  for all to authenticated using (bucket_id = 'documents' and public.is_admin())
  with check (bucket_id = 'documents' and public.is_admin());

------------------------------------------------------------

-- ======================================================= STEP 2: MIGRATE DATA
do $$
begin
  if to_regclass('public.documents_legacy_v1') is not null then
    insert into public.documents
      (title_i18n, description_i18n, storage_path, file_url, file_type,
       requires_login, downloads, status, published_at, created_at, updated_at)
    select
      jsonb_build_object('fa', coalesce(title_fa, ''), 'en', coalesce(title_en, '')),
      jsonb_build_object('fa', coalesce(description_fa, ''), 'en', coalesce(description_en, '')),
      'legacy/' || id::text,
      coalesce(file_url, ''),
      coalesce(nullif(trim(file_type), ''), 'pdf'),
      true,
      0,
      case when published then 'published' else 'draft' end,
      case when published then coalesce(updated_at, created_at) end,
      created_at,
      updated_at
    from public.documents_legacy_v1;
  end if;

  if to_regclass('public.public_notifications_legacy_v1') is not null then
    insert into public.public_notifications
      (title_i18n, body_i18n, data, status, published_at, created_at, updated_at)
    select
      jsonb_build_object('fa', coalesce(title_fa, ''), 'en', coalesce(title_en, '')),
      jsonb_build_object('fa', coalesce(body_fa, ''), 'en', coalesce(body_en, '')),
      coalesce(jsonb_strip_nulls(jsonb_build_object('target_url', target_url)), '{}'::jsonb),
      case when published then 'published' else 'draft' end,
      case when published then created_at end,
      created_at,
      created_at
    from public.public_notifications_legacy_v1;
  end if;
end $$;

------------------------------------------------------------
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

drop policy if exists "users manage their own profile" on public.profiles;
create policy "users manage their own profile" on public.profiles
  for all to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- ------------------------------------------------------- admin news management
-- Until now the news/publishers tables had read-only policies, so no admin
-- could create or edit articles through the API.
drop policy if exists "admins manage news" on public.news;
create policy "admins manage news" on public.news
  for all to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "admins manage publishers" on public.publishers;
create policy "admins manage publishers" on public.publishers
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- --------------------------------------------------------------- app assets
-- Public bucket for news/article images (metadata is public by design; the
-- service-role/admin uploads, everyone can read).
insert into storage.buckets (id, name, public)
values ('app-assets', 'app-assets', true)
on conflict (id) do update set public = true;

drop policy if exists "app assets are publicly readable" on storage.objects;
drop policy if exists "app assets are publicly readable" on storage.objects;
create policy "app assets are publicly readable" on storage.objects
  for select to anon, authenticated using (bucket_id = 'app-assets');
drop policy if exists "admins manage app assets" on storage.objects;
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

------------------------------------------------------------
-- Admin-side delivery of special (case) notifications.
-- Strictly additive: no existing table or policy is modified.
--
-- The special_notifications table is recipient-scoped (RLS lets a user read
-- only their own rows while their bell is on). An admin client therefore
-- cannot enumerate recipients, so delivery happens inside this SECURITY
-- DEFINER function which still requires the caller to be an administrator.

create or replace function public.notify_case_subscribers(
  p_case_id text,
  p_case_type text,
  p_title_i18n jsonb,
  p_body_i18n jsonb,
  p_data jsonb default '{}'::jsonb
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recipients int;
begin
  if not public.is_admin() then
    raise exception 'admin privileges required';
  end if;

  if p_case_id is null or char_length(trim(p_case_id)) = 0 then
    raise exception 'case_id is required';
  end if;
  if p_case_type is null or p_case_type not in ('afghan', 'iranian') then
    raise exception 'case_type must be afghan or iranian';
  end if;
  if jsonb_typeof(p_title_i18n) <> 'object' or jsonb_typeof(p_body_i18n) <> 'object'
     or jsonb_typeof(p_data) <> 'object' then
    raise exception 'title, body and data must be JSON objects';
  end if;

  with inserted as (
    insert into public.special_notifications
      (case_id, case_type, recipient_user_id, title_i18n, body_i18n, data)
    select
      trim(p_case_id),
      p_case_type,
      s.user_id,
      p_title_i18n,
      p_body_i18n,
      p_data
    from public.case_subscriptions s
    where s.case_id = trim(p_case_id)
      and s.case_type = p_case_type
      and s.active = true
    on conflict do nothing
    returning 1
  )
  select count(*) into v_recipients from inserted;

  return v_recipients;
end;
$$;

-- Only authenticated administrators ever call this; keep it tight anyway.
revoke all on function public.notify_case_subscribers(text, text, jsonb, jsonb, jsonb)
  from public, anon;
grant execute on function public.notify_case_subscribers(text, text, jsonb, jsonb, jsonb)
  to authenticated;

-- Public announcements join the realtime publication so the app refreshes
-- its notification feed the moment an admin publishes one. RLS keeps drafts
-- out of every subscriber's payload.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public' and tablename = 'public_notifications'
  ) then
    alter publication supabase_realtime add table public.public_notifications;
  end if;
end $$;
