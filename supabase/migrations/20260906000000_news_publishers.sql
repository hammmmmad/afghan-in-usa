-- Afghan in USA: editorial news and publisher domain.
-- Run with `supabase db push` or paste into the Supabase SQL editor.

create extension if not exists pgcrypto;

create type public.news_status as enum ('draft', 'published', 'archived');

create table public.publishers (
  id uuid primary key default gen_random_uuid(),
  display_name text not null check (char_length(trim(display_name)) > 0),
  avatar_url text not null default '',
  bio_fa text not null default '',
  bio_en text not null default '',
  website_url text not null default '',
  verified boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.news (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  publisher_id uuid not null references public.publishers(id) on delete restrict,
  category_id text not null check (char_length(trim(category_id)) > 0),
  category_fa text not null default '',
  category_en text not null default '',
  date_iso date not null,
  date_fa text not null default '',
  date_en text not null default '',
  title_fa text not null,
  title_en text not null default '',
  summary_fa text not null,
  summary_en text not null default '',
  content_fa jsonb not null default '[]'::jsonb check (jsonb_typeof(content_fa) = 'array'),
  content_en jsonb not null default '[]'::jsonb check (jsonb_typeof(content_en) = 'array'),
  image_url text not null default '',
  source text not null default '',
  source_url text not null default '',
  featured boolean not null default false,
  status public.news_status not null default 'draft',
  published_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint published_news_requires_date check (
    status <> 'published' or published_at is not null
  )
);

create index news_public_feed_idx
  on public.news (featured desc, published_at desc)
  where status = 'published';
create index news_category_feed_idx
  on public.news (category_id, published_at desc)
  where status = 'published';
create index news_publisher_idx on public.news (publisher_id);

create or replace function public.set_updated_at()
returns trigger language plpgsql security invoker set search_path = public as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create trigger publishers_set_updated_at
before update on public.publishers
for each row execute function public.set_updated_at();

create trigger news_set_updated_at
before update on public.news
for each row execute function public.set_updated_at();

alter table public.publishers enable row level security;
alter table public.news enable row level security;

-- Anonymous users can only see active publishers and published articles.
create policy "published news is publicly readable"
on public.news for select
to anon, authenticated
using (status = 'published');

create policy "active publishers are publicly readable"
on public.publishers for select
to anon, authenticated
using (is_active = true);

-- No client-side insert/update/delete policy is created. Manage editorial data
-- from the dashboard or a trusted server using the service-role key.

insert into storage.buckets (id, name, public)
values ('news-media', 'news-media', true)
on conflict (id) do nothing;

create policy "news media is publicly readable"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'news-media');
