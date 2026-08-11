-- FinLit India schema
-- Auth: Supabase anonymous auth (auth.users). Each user gets a linked
-- profiles row keyed by the same id. Phone number is stored as a plain
-- identifier field (matches the original app's behavior — it was never
-- OTP-verified there either), not used as a Supabase Auth credential.

create extension if not exists "pgcrypto";

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  phone text not null unique,
  name text,
  language text,
  created_at timestamptz not null default now(),
  streak_count int not null default 0,
  coins int not null default 0,
  last_active_date date,
  streak_freeze_count int not null default 0,
  double_coin_count int not null default 0,
  quiz_shield_count int not null default 0,
  double_coin_active_until timestamptz
);

create table public.lessons (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  content text,
  module_number int,
  section_name text,
  coins_reward int not null default 10,
  order_index int not null default 0
);

create table public.questions (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.lessons (id) on delete cascade,
  question text not null,
  option_1 text not null,
  option_2 text not null,
  option_3 text not null,
  option_4 text not null,
  -- 1-based to match the original Firestore data (correct_option - 1 = index)
  correct_option int not null
);

create table public.progress (
  user_id uuid not null references public.profiles (id) on delete cascade,
  lesson_id uuid not null references public.lessons (id) on delete cascade,
  is_completed boolean not null default false,
  completed_at timestamptz,
  primary key (user_id, lesson_id)
);

create table public.quiz_results (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  lesson_id uuid not null references public.lessons (id) on delete cascade,
  score int not null,
  completed_at timestamptz not null default now()
);

create table public.budgets (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  total_income numeric not null default 0,
  food numeric not null default 0,
  rent numeric not null default 0,
  education numeric not null default 0,
  transport numeric not null default 0,
  savings numeric not null default 0,
  last_updated timestamptz not null default now()
);

-- Row Level Security
alter table public.profiles enable row level security;
alter table public.lessons enable row level security;
alter table public.questions enable row level security;
alter table public.progress enable row level security;
alter table public.quiz_results enable row level security;
alter table public.budgets enable row level security;

-- Content tables: readable by any signed-in user, no direct client writes
-- (writes are seeded by the project owner via the service role key).
create policy "lessons readable by authenticated users"
  on public.lessons for select
  to authenticated
  using (true);

create policy "questions readable by authenticated users"
  on public.questions for select
  to authenticated
  using (true);

-- Profiles: users can only READ their own row directly. All writes —
-- including name/language changes — go through Edge Functions using the
-- service role key. RLS is row-level, not column-level, so a general
-- client-side UPDATE policy here would let a client grant itself coins;
-- routing every mutation through a function avoids that entirely.
create policy "profiles readable by owner"
  on public.profiles for select
  to authenticated
  using (auth.uid() = id);

-- Progress, quiz results, budgets: fully owned by the user.
create policy "progress readable by owner"
  on public.progress for select
  to authenticated
  using (auth.uid() = user_id);

create policy "quiz results readable by owner"
  on public.quiz_results for select
  to authenticated
  using (auth.uid() = user_id);

create policy "budget readable by owner"
  on public.budgets for select
  to authenticated
  using (auth.uid() = user_id);

create policy "budget writable by owner"
  on public.budgets for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
