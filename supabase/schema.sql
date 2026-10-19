-- Veckomat schema. Run in Supabase SQL Editor as project owner.
create extension if not exists pgcrypto;

create table if not exists public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'Vår matplan',
  invite_code text not null unique,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  household_id uuid references public.households(id) on delete set null,
  created_at timestamptz not null default now()
);
create table if not exists public.recipes (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  title text not null,
  description text not null default '',
  ingredients jsonb not null default '[]'::jsonb,
  instructions jsonb not null default '[]'::jsonb,
  prep_minutes integer not null default 0,
  servings integer not null default 2,
  category text not null default 'Vegetariskt',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.meal_plans (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  date date not null,
  meal_type text not null check (meal_type in ('breakfast','lunch','dinner')),
  recipe_id uuid references public.recipes(id) on delete set null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  unique(household_id, date, meal_type)
);
create table if not exists public.shopping_items (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null,
  checked boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

-- Keep a profile row for each newly registered user.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id) values (new.id) on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace function public.current_household_id()
returns uuid language sql stable security definer set search_path = '' as $$
  select household_id from public.profiles where id = (select auth.uid())
$$;

-- RLS: members can only access data in their household. Joining uses the invite code RPC below.
alter table public.households enable row level security;
alter table public.profiles enable row level security;
alter table public.recipes enable row level security;
alter table public.meal_plans enable row level security;
alter table public.shopping_items enable row level security;

drop policy if exists "read own household" on public.households;
create policy "read own household" on public.households for select to authenticated using (id = public.current_household_id() or created_by = auth.uid());
drop policy if exists "create household" on public.households;
create policy "create household" on public.households for insert to authenticated with check (created_by = auth.uid());
drop policy if exists "update own household" on public.households;
create policy "update own household" on public.households for update to authenticated using (id = public.current_household_id()) with check (id = public.current_household_id());

drop policy if exists "read own profile" on public.profiles;
create policy "read own profile" on public.profiles for select to authenticated using (id = auth.uid());
drop policy if exists "insert own profile" on public.profiles;
create policy "insert own profile" on public.profiles for insert to authenticated with check (id = auth.uid());
drop policy if exists "update own profile" on public.profiles;
create policy "update own profile" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- A security-definer RPC verifies the invite code and adds the current user to that household.
create or replace function public.join_household_by_code(code text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare target_id uuid;
begin
  select id into target_id from public.households where invite_code = upper(trim(code));
  if target_id is null then raise exception 'Invalid invite code'; end if;
  insert into public.profiles (id, household_id) values (auth.uid(), target_id)
    on conflict (id) do update set household_id = excluded.household_id;
  return target_id;
end;
$$;
grant execute on function public.join_household_by_code(text) to authenticated;

drop policy if exists "household recipes access" on public.recipes;
create policy "household recipes access" on public.recipes for all to authenticated using (household_id = public.current_household_id()) with check (household_id = public.current_household_id());
drop policy if exists "household meal plans access" on public.meal_plans;
create policy "household meal plans access" on public.meal_plans for all to authenticated using (household_id = public.current_household_id()) with check (household_id = public.current_household_id());
drop policy if exists "household shopping access" on public.shopping_items;
create policy "household shopping access" on public.shopping_items for all to authenticated using (household_id = public.current_household_id()) with check (household_id = public.current_household_id());

-- Invite-code lookup is intentionally performed via RPC so household rows are not publicly enumerable.
-- Enable Realtime for shared updates.
alter publication supabase_realtime add table public.recipes;
alter publication supabase_realtime add table public.meal_plans;
alter publication supabase_realtime add table public.shopping_items;
