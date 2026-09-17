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
