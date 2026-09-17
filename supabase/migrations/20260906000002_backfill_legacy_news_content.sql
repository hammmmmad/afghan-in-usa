-- Preserve content from the older dashboard schema after the news upgrade.
-- `to_jsonb(n)` makes this safe whether or not a legacy column existed.
with legacy as (
  select
    n.id,
    to_jsonb(n) as row_data
  from public.news as n
)
update public.news as n
set
  title_fa = coalesce(nullif(n.title_fa, ''), nullif(legacy.row_data ->> 'title', ''), ''),
  title_en = coalesce(nullif(n.title_en, ''), nullif(legacy.row_data ->> 'title_en', ''), ''),
  summary_fa = coalesce(nullif(n.summary_fa, ''), nullif(legacy.row_data ->> 'summary', ''), ''),
  summary_en = coalesce(nullif(n.summary_en, ''), nullif(legacy.row_data ->> 'summary_en', ''), ''),
  content_fa = case
    when jsonb_array_length(n.content_fa) > 0 then n.content_fa
    when jsonb_typeof(legacy.row_data -> 'body') = 'array' then legacy.row_data -> 'body'
    when nullif(legacy.row_data ->> 'body', '') is not null
      then jsonb_build_array(legacy.row_data ->> 'body')
    when jsonb_typeof(legacy.row_data -> 'content') = 'array' then legacy.row_data -> 'content'
    when nullif(legacy.row_data ->> 'content', '') is not null
      then jsonb_build_array(legacy.row_data ->> 'content')
    when nullif(legacy.row_data ->> 'summary', '') is not null
      then jsonb_build_array(legacy.row_data ->> 'summary')
    else n.content_fa
  end,
  content_en = case
    when jsonb_array_length(n.content_en) > 0 then n.content_en
    when jsonb_typeof(legacy.row_data -> 'body_en') = 'array' then legacy.row_data -> 'body_en'
    when nullif(legacy.row_data ->> 'body_en', '') is not null
      then jsonb_build_array(legacy.row_data ->> 'body_en')
    when nullif(legacy.row_data ->> 'summary_en', '') is not null
      then jsonb_build_array(legacy.row_data ->> 'summary_en')
    else n.content_en
  end
from legacy
where n.id = legacy.id;
