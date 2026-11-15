-- Family tree schema for Supabase.
-- Run with `supabase db push` or paste into the SQL editor.
--
-- Every record belongs to a tree; access is granted through tree_members
-- (owner / editor / viewer) and enforced with Row Level Security, so the
-- anon key shipped in the app can never read someone else's family.

create extension if not exists pgcrypto;

-- ------------------------------------------------------------------ trees
create table public.trees (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name        text not null default 'My family',
  created_at  timestamptz not null default now()
);

create table public.tree_members (
  tree_id     uuid not null references public.trees(id) on delete cascade,
  user_id     uuid not null references auth.users(id) on delete cascade,
  role        text not null check (role in ('owner', 'editor', 'viewer')),
  created_at  timestamptz not null default now(),
  primary key (tree_id, user_id)
);

-- The creator of a tree automatically becomes its owner.
create or replace function public.add_tree_owner()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.tree_members (tree_id, user_id, role)
  values (new.id, new.owner_id, 'owner');
  return new;
end $$;

create trigger trees_add_owner
after insert on public.trees
for each row execute function public.add_tree_owner();

-- Membership helpers (security definer avoids recursive RLS checks).
create or replace function public.tree_role(t uuid)
returns text language sql stable security definer set search_path = public as $$
  select role from public.tree_members where tree_id = t and user_id = auth.uid()
$$;

create or replace function public.can_read_tree(t uuid)
returns boolean language sql stable as $$
  select public.tree_role(t) is not null
$$;

create or replace function public.can_edit_tree(t uuid)
returns boolean language sql stable as $$
  select public.tree_role(t) in ('owner', 'editor')
$$;

-- ------------------------------------------------------- tree records
-- Each record keeps the app model as JSON (see lib/models/models.dart), which
-- lets the model evolve without migrations.
create table public.persons (
  id          uuid primary key,
  tree_id     uuid not null references public.trees(id) on delete cascade,
  data        jsonb not null,
  updated_at  timestamptz not null default now(),
  updated_by  uuid default auth.uid()
);

create table public.unions (
  id          uuid primary key,
  tree_id     uuid not null references public.trees(id) on delete cascade,
  data        jsonb not null,
  updated_at  timestamptz not null default now(),
  updated_by  uuid default auth.uid()
);

create table public.parent_links (
  id          uuid primary key,
  tree_id     uuid not null references public.trees(id) on delete cascade,
  data        jsonb not null,
  updated_at  timestamptz not null default now(),
  updated_by  uuid default auth.uid()
);

create index persons_tree_idx on public.persons(tree_id);
create index unions_tree_idx on public.unions(tree_id);
create index parent_links_tree_idx on public.parent_links(tree_id);

create or replace function public.touch_updated()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  new.updated_by = auth.uid();
  return new;
end $$;

create trigger persons_touch before update on public.persons
for each row execute function public.touch_updated();
create trigger unions_touch before update on public.unions
for each row execute function public.touch_updated();
create trigger parent_links_touch before update on public.parent_links
for each row execute function public.touch_updated();

-- ------------------------------------------------------------------ RLS
alter table public.trees enable row level security;
alter table public.tree_members enable row level security;
alter table public.persons enable row level security;
alter table public.unions enable row level security;
alter table public.parent_links enable row level security;

-- owner_id check lets INSERT ... RETURNING see the row before the
-- membership trigger has run.
create policy "members read trees" on public.trees
  for select using (owner_id = auth.uid() or public.can_read_tree(id));
create policy "users create trees" on public.trees
  for insert with check (owner_id = auth.uid());
create policy "owners update trees" on public.trees
  for update using (public.tree_role(id) = 'owner');
create policy "owners delete trees" on public.trees
  for delete using (public.tree_role(id) = 'owner');

create policy "members read membership" on public.tree_members
  for select using (user_id = auth.uid() or public.can_read_tree(tree_id));
create policy "owners manage membership" on public.tree_members
  for all using (public.tree_role(tree_id) = 'owner')
  with check (public.tree_role(tree_id) = 'owner');

do $$
declare t text;
begin
  foreach t in array array['persons', 'unions', 'parent_links'] loop
    execute format('create policy "members read" on public.%I for select using (public.can_read_tree(tree_id))', t);
    execute format('create policy "editors insert" on public.%I for insert with check (public.can_edit_tree(tree_id))', t);
    execute format('create policy "editors update" on public.%I for update using (public.can_edit_tree(tree_id)) with check (public.can_edit_tree(tree_id))', t);
    execute format('create policy "editors delete" on public.%I for delete using (public.can_edit_tree(tree_id))', t);
  end loop;
end $$;

-- --------------------------------------------------------------- photos
-- Private bucket; objects live under "<tree_id>/<file>" and the app reads
-- them through short-lived signed URLs.
insert into storage.buckets (id, name, public)
values ('photos', 'photos', false)
on conflict (id) do nothing;

create policy "members read photos" on storage.objects
  for select using (
    bucket_id = 'photos'
    and public.can_read_tree(((storage.foldername(name))[1])::uuid)
  );
create policy "editors upload photos" on storage.objects
  for insert with check (
    bucket_id = 'photos'
    and public.can_edit_tree(((storage.foldername(name))[1])::uuid)
  );
create policy "editors update photos" on storage.objects
  for update using (
    bucket_id = 'photos'
    and public.can_edit_tree(((storage.foldername(name))[1])::uuid)
  );
create policy "editors delete photos" on storage.objects
  for delete using (
    bucket_id = 'photos'
    and public.can_edit_tree(((storage.foldername(name))[1])::uuid)
  );
