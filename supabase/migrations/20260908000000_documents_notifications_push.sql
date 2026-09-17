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
