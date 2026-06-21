-- User-owned Pokemon data for Pokedex Codex Pro.
-- Run this in Supabase SQL editor or with the Supabase CLI.

create table if not exists public.favorite_pokemon (
  user_id uuid not null references auth.users(id) on delete cascade,
  pokemon_id integer not null check (pokemon_id > 0),
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  primary key (user_id, pokemon_id)
);

create table if not exists public.pokemon_notes (
  user_id uuid not null references auth.users(id) on delete cascade,
  pokemon_id integer not null check (pokemon_id > 0),
  note text not null default '',
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  primary key (user_id, pokemon_id)
);

create or replace function public.has_only_positive_integers(pokemon_ids_input integer[])
returns boolean
language sql
immutable
as $$
  select coalesce(bool_and(value > 0), true)
  from unnest(pokemon_ids_input) as value;
$$;

create table if not exists public.pokemon_teams (
  id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  pokemon_ids integer[] not null default '{}',
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  primary key (user_id, id),
  check (cardinality(pokemon_ids) <= 6),
  check (public.has_only_positive_integers(pokemon_ids))
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_favorite_pokemon_updated_at on public.favorite_pokemon;
create trigger set_favorite_pokemon_updated_at
before update on public.favorite_pokemon
for each row
execute function public.set_updated_at();

drop trigger if exists set_pokemon_notes_updated_at on public.pokemon_notes;
create trigger set_pokemon_notes_updated_at
before update on public.pokemon_notes
for each row
execute function public.set_updated_at();

drop trigger if exists set_pokemon_teams_updated_at on public.pokemon_teams;
create trigger set_pokemon_teams_updated_at
before update on public.pokemon_teams
for each row
execute function public.set_updated_at();

alter table public.favorite_pokemon enable row level security;
alter table public.pokemon_notes enable row level security;
alter table public.pokemon_teams enable row level security;

drop policy if exists "Users can read favorite Pokemon" on public.favorite_pokemon;
create policy "Users can read favorite Pokemon"
on public.favorite_pokemon
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert favorite Pokemon" on public.favorite_pokemon;
create policy "Users can insert favorite Pokemon"
on public.favorite_pokemon
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update favorite Pokemon" on public.favorite_pokemon;
create policy "Users can update favorite Pokemon"
on public.favorite_pokemon
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete favorite Pokemon" on public.favorite_pokemon;
create policy "Users can delete favorite Pokemon"
on public.favorite_pokemon
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can read Pokemon notes" on public.pokemon_notes;
create policy "Users can read Pokemon notes"
on public.pokemon_notes
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert Pokemon notes" on public.pokemon_notes;
create policy "Users can insert Pokemon notes"
on public.pokemon_notes
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update Pokemon notes" on public.pokemon_notes;
create policy "Users can update Pokemon notes"
on public.pokemon_notes
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete Pokemon notes" on public.pokemon_notes;
create policy "Users can delete Pokemon notes"
on public.pokemon_notes
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can read Pokemon teams" on public.pokemon_teams;
create policy "Users can read Pokemon teams"
on public.pokemon_teams
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert Pokemon teams" on public.pokemon_teams;
create policy "Users can insert Pokemon teams"
on public.pokemon_teams
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update Pokemon teams" on public.pokemon_teams;
create policy "Users can update Pokemon teams"
on public.pokemon_teams
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete Pokemon teams" on public.pokemon_teams;
create policy "Users can delete Pokemon teams"
on public.pokemon_teams
for delete
to authenticated
using (auth.uid() = user_id);

create index if not exists favorite_pokemon_user_id_idx
on public.favorite_pokemon(user_id);

create index if not exists pokemon_notes_user_id_idx
on public.pokemon_notes(user_id);

create index if not exists pokemon_teams_user_id_idx
on public.pokemon_teams(user_id);
