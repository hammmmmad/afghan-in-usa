-- Safe upgrade for projects that already have public.news.
-- This migration never drops or overwrites existing columns or rows.

create extension if not exists pgcrypto;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'news_status') then
    create type public.news_status as enum ('draft', 'published', 'archived');
  end if;
end;
$$;

create table if not exists public.publishers (
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

-- A stable fallback publisher lets existing rows receive the new required FK.
insert into public.publishers (id, display_name, verified)
values ('00000000-0000-0000-0000-000000000001', 'Afghan in USA', true)
on conflict (id) do nothing;

alter table public.news add column if not exists slug text;
alter table public.news add column if not exists publisher_id uuid;
alter table public.news add column if not exists category_id text not null default 'general';
alter table public.news add column if not exists category_fa text not null default '';
alter table public.news add column if not exists category_en text not null default '';
alter table public.news add column if not exists date_iso date not null default current_date;
alter table public.news add column if not exists date_fa text not null default '';
alter table public.news add column if not exists date_en text not null default '';
alter table public.news add column if not exists title_fa text not null default '';
alter table public.news add column if not exists title_en text not null default '';
alter table public.news add column if not exists summary_fa text not null default '';
alter table public.news add column if not exists summary_en text not null default '';
alter table public.news add column if not exists content_fa jsonb not null default '[]'::jsonb;
alter table public.news add column if not exists content_en jsonb not null default '[]'::jsonb;
alter table public.news add column if not exists image_url text not null default '';
alter table public.news add column if not exists source text not null default '';
alter table public.news add column if not exists source_url text not null default '';
alter table public.news add column if not exists featured boolean not null default false;
alter table public.news add column if not exists status public.news_status not null default 'draft';
alter table public.news add column if not exists published_at timestamptz;
alter table public.news add column if not exists created_at timestamptz not null default timezone('utc', now());
alter table public.news add column if not exists updated_at timestamptz not null default timezone('utc', now());

update public.news
set slug = 'news-' || id::text
where slug is null or trim(slug) = '';

update public.news
set publisher_id = '00000000-0000-0000-0000-000000000001'
where publisher_id is null;

alter table public.news alter column slug set not null;
alter table public.news alter column publisher_id set not null;

create unique index if not exists news_slug_unique_idx on public.news (slug);
create index if not exists news_public_feed_idx
  on public.news (featured desc, published_at desc)
  where status = 'published';
create index if not exists news_category_feed_idx
  on public.news (category_id, published_at desc)
  where status = 'published';
create index if not exists news_publisher_idx on public.news (publisher_id);

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'news_publisher_id_fkey'
  ) then
    alter table public.news add constraint news_publisher_id_fkey
      foreign key (publisher_id) references public.publishers(id) on delete restrict;
  end if;
end;
$$;

create or replace function public.set_updated_at()
returns trigger language plpgsql security invoker set search_path = public as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists publishers_set_updated_at on public.publishers;
create trigger publishers_set_updated_at
before update on public.publishers
for each row execute function public.set_updated_at();

drop trigger if exists news_set_updated_at on public.news;
create trigger news_set_updated_at
before update on public.news
for each row execute function public.set_updated_at();

alter table public.publishers enable row level security;
alter table public.news enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'news'
      and policyname = 'published news is publicly readable'
  ) then
    create policy "published news is publicly readable"
      on public.news for select to anon, authenticated
      using (status = 'published');
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'publishers'
      and policyname = 'active publishers are publicly readable'
  ) then
    create policy "active publishers are publicly readable"
      on public.publishers for select to anon, authenticated
      using (is_active = true);
  end if;
end;
$$;

insert into storage.buckets (id, name, public)
values ('news-media', 'news-media', true)
on conflict (id) do nothing;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'news media is publicly readable'
  ) then
    create policy "news media is publicly readable"
      on storage.objects for select to anon, authenticated
      using (bucket_id = 'news-media');
  end if;
end;
$$;
