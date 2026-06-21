-- User profile metadata for Pokedex Codex Pro.
-- Auth identity remains in auth.users; this table stores app-specific profile data.

create table if not exists public.user_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Entrenador',
  trainer_title text not null default 'Novato',
  favorite_type text,
  avatar_seed text,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  check (length(trim(display_name)) > 0),
  check (length(trim(trainer_title)) > 0)
);

drop trigger if exists set_user_profiles_updated_at on public.user_profiles;
create trigger set_user_profiles_updated_at
before update on public.user_profiles
for each row
execute function public.set_updated_at();

alter table public.user_profiles enable row level security;

drop policy if exists "Users can read their profile" on public.user_profiles;
create policy "Users can read their profile"
on public.user_profiles
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert their profile" on public.user_profiles;
create policy "Users can insert their profile"
on public.user_profiles
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update their profile" on public.user_profiles;
create policy "Users can update their profile"
on public.user_profiles
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete their profile" on public.user_profiles;
create policy "Users can delete their profile"
on public.user_profiles
for delete
to authenticated
using (auth.uid() = user_id);
