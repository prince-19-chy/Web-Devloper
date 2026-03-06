-- ═══════════════════════════════════════════════════════════════════════
--  Prince Kumar Chaudhary — Portfolio  |  Supabase Database Setup
--  Run this entire file in: Supabase Dashboard → SQL Editor → New Query
-- ═══════════════════════════════════════════════════════════════════════

-- ─── ENABLE UUID extension ─────────────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ═══════════════════════════════════════════════════════════════════════
--  TABLE: projects
-- ═══════════════════════════════════════════════════════════════════════
create table if not exists public.projects (
  id            serial primary key,
  title         text        not null,
  category      text,
  status        text        not null default 'live'  check (status in ('live','wip','draft')),
  description   text,
  live_url      text,
  github_url    text,
  image_url     text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ─── Seed default projects ─────────────────────────────────────────────
insert into public.projects (title, category, status, description, live_url, github_url) values
  ('Luxewear',             'E-Commerce',   'live', 'A modern fashion e-commerce platform.', '#', '#'),
  ('Grace-light Creation', 'Business',     'live', 'A creative business website.', '#', '#'),
  ('Valentine Day',        'School/Event', 'live', 'A themed school event website.', '#', '#'),
  ('Hotel Website',        'Hospitality',  'live', 'A luxury hotel landing page.', '#', '#'),
  ('The Forgotten Land',   '2D Game',      'live', 'A 2D horror adventure game jam project.', '#', '#'),
  ('Android BT App',       'Android',      'wip',  'Bluetooth controller Android app in progress.', null, null)
on conflict do nothing;

-- ═══════════════════════════════════════════════════════════════════════
--  TABLE: blog_posts
-- ═══════════════════════════════════════════════════════════════════════
create table if not exists public.blog_posts (
  id          serial primary key,
  title       text        not null,
  category    text,
  excerpt     text,
  url         text,
  status      text        not null default 'draft'  check (status in ('draft','published')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ─── Seed blog posts ────────────────────────────────────────────────────
insert into public.blog_posts (title, category, excerpt, status) values
  ('How I Built an AI Automation System as a High Schooler', 'AI',       'From prompt engineering to real-world pipelines.', 'published'),
  ('My First Game Jam: Lessons from The Forgotten Land',     'Game Dev', 'What worked, what broke, and what I would do differently.', 'published'),
  ('Supabase vs Firebase: Which to Pick in 2025?',           'Web Dev',  'A hands-on comparison from someone who has used both.', 'published'),
  ('Building a Bluetooth Controller App: My Dev Log',        'Android',  'Week-by-week notes on my Android Bluetooth project.', 'draft')
on conflict do nothing;

-- ═══════════════════════════════════════════════════════════════════════
--  TABLE: messages  (contact form submissions)
-- ═══════════════════════════════════════════════════════════════════════
create table if not exists public.messages (
  id          serial primary key,
  name        text        not null,
  email       text        not null,
  phone       text,
  subject     text        not null,
  message     text        not null,
  read        boolean     not null default false,
  created_at  timestamptz not null default now()
);

-- ═══════════════════════════════════════════════════════════════════════
--  TABLE: activity_log  (dashboard recent activity feed)
-- ═══════════════════════════════════════════════════════════════════════
create table if not exists public.activity_log (
  id          serial primary key,
  color       text        not null default 'green',  -- green | blue | yellow | red
  title       text        not null,
  description text,
  created_at  timestamptz not null default now()
);

-- ─── Seed some activity ─────────────────────────────────────────────────
insert into public.activity_log (color, title, description) values
  ('green', 'Portfolio launched',    'Site is live!'),
  ('blue',  'Blog post published',   'Supabase vs Firebase article'),
  ('green', 'New project added',     'The Forgotten Land'),
  ('blue',  'Blog post published',   'AI Automation System article')
on conflict do nothing;

-- ═══════════════════════════════════════════════════════════════════════
--  ROW LEVEL SECURITY (RLS)
-- ═══════════════════════════════════════════════════════════════════════

-- Enable RLS on all tables
alter table public.projects     enable row level security;
alter table public.blog_posts   enable row level security;
alter table public.messages     enable row level security;
alter table public.activity_log enable row level security;

-- ─── PUBLIC can read projects and published blog posts ─────────────────
create policy "public_read_projects"
  on public.projects for select
  using (true);

create policy "public_read_published_posts"
  on public.blog_posts for select
  using (status = 'published');

-- ─── PUBLIC can INSERT messages (contact form) ─────────────────────────
create policy "public_insert_messages"
  on public.messages for insert
  with check (true);

-- ─── AUTHENTICATED (admin) can do everything ───────────────────────────
create policy "auth_all_projects"
  on public.projects for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

create policy "auth_all_blog_posts"
  on public.blog_posts for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

create policy "auth_all_messages"
  on public.messages for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

create policy "auth_all_activity"
  on public.activity_log for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- ═══════════════════════════════════════════════════════════════════════
--  AUTO-UPDATE updated_at TRIGGERS
-- ═══════════════════════════════════════════════════════════════════════
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger trg_projects_updated
  before update on public.projects
  for each row execute function public.set_updated_at();

create trigger trg_blog_posts_updated
  before update on public.blog_posts
  for each row execute function public.set_updated_at();

-- ═══════════════════════════════════════════════════════════════════════
--  DONE! Verify by running:
--    select * from public.projects;
--    select * from public.blog_posts;
-- ═══════════════════════════════════════════════════════════════════════
