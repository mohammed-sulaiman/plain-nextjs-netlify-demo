-- Collaborative editing: invite relatives to a tree as editors or viewers.
--
-- Flow: an owner creates an invite (a short code, optionally restricted to
-- one email address, valid for 7 days), shares the code or link, and the
-- relative accepts it after signing in. accept_invite() is the only way to
-- join a tree, so membership can't be self-granted.

-- --------------------------------------------------------------- invites
create table public.tree_invites (
  id           uuid primary key default gen_random_uuid(),
  tree_id      uuid not null references public.trees(id) on delete cascade,
  code         text not null unique
               default upper(substr(encode(gen_random_bytes(8), 'hex'), 1, 10)),
  role         text not null check (role in ('editor', 'viewer')),
  email        text,
  created_by   uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at   timestamptz not null default now(),
  expires_at   timestamptz not null default now() + interval '7 days',
  accepted_by  uuid references auth.users(id) on delete set null,
  accepted_at  timestamptz
);

create index tree_invites_tree_idx on public.tree_invites(tree_id);

alter table public.tree_invites enable row level security;

create policy "owners read invites" on public.tree_invites
  for select using (public.tree_role(tree_id) = 'owner');
create policy "owners create invites" on public.tree_invites
  for insert with check (
    public.tree_role(tree_id) = 'owner' and created_by = auth.uid()
  );
create policy "owners revoke invites" on public.tree_invites
  for delete using (public.tree_role(tree_id) = 'owner');

-- What an invite is for, shown before accepting. Only someone who has the
-- code can look it up.
create or replace function public.invite_info(p_code text)
returns table (tree_name text, role text, invited_by text, expires_at timestamptz, status text)
language sql stable security definer set search_path = public as $$
  select t.name,
         i.role,
         u.email::text,
         i.expires_at,
         case
           when i.accepted_at is not null then 'used'
           when i.expires_at < now() then 'expired'
           else 'valid'
         end
  from public.tree_invites i
  join public.trees t on t.id = i.tree_id
  left join auth.users u on u.id = i.created_by
  where i.code = upper(trim(p_code))
    and auth.uid() is not null
$$;

-- Accepts an invite for the signed-in user and returns the tree id.
-- Errors (in the message): not_authenticated, invite_not_found, invite_used,
-- invite_expired, invite_wrong_email.
create or replace function public.accept_invite(p_code text)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  inv public.tree_invites;
  uid uuid := auth.uid();
  current_role_name text;
begin
  if uid is null then
    raise exception 'not_authenticated';
  end if;

  select * into inv from public.tree_invites
  where code = upper(trim(p_code))
  for update;

  if not found then
    raise exception 'invite_not_found';
  end if;
  if inv.accepted_at is not null then
    raise exception 'invite_used';
  end if;
  if inv.expires_at < now() then
    raise exception 'invite_expired';
  end if;
  if inv.email is not null
     and lower(inv.email) <> lower(coalesce(auth.jwt() ->> 'email', '')) then
    raise exception 'invite_wrong_email';
  end if;

  select tm.role into current_role_name
  from public.tree_members tm
  where tm.tree_id = inv.tree_id and tm.user_id = uid;

  if current_role_name is null then
    insert into public.tree_members (tree_id, user_id, role)
    values (inv.tree_id, uid, inv.role);
  elsif current_role_name = 'viewer' and inv.role = 'editor' then
    update public.tree_members set role = 'editor'
    where tree_id = inv.tree_id and user_id = uid;
  end if;

  update public.tree_invites
  set accepted_by = uid, accepted_at = now()
  where id = inv.id;

  return inv.tree_id;
end $$;

-- ------------------------------------------------------------- members
-- Members of a tree with their email addresses (auth.users is not readable
-- from the client).
create or replace function public.tree_members_with_email(p_tree uuid)
returns table (user_id uuid, email text, role text, joined_at timestamptz)
language sql stable security definer set search_path = public as $$
  select tm.user_id, u.email::text, tm.role, tm.created_at
  from public.tree_members tm
  join auth.users u on u.id = tm.user_id
  where tm.tree_id = p_tree
    and public.can_read_tree(p_tree)
  order by case tm.role when 'owner' then 0 when 'editor' then 1 else 2 end,
           tm.created_at
$$;

-- Replace the broad owner policy from 0001 so that an owner can't remove or
-- demote themselves (a tree must keep its owner), members can leave, and
-- nobody can grant ownership through an update.
drop policy "owners manage membership" on public.tree_members;

create policy "owners add members" on public.tree_members
  for insert with check (
    public.tree_role(tree_id) = 'owner' and role in ('editor', 'viewer')
  );
create policy "owners change roles" on public.tree_members
  for update using (public.tree_role(tree_id) = 'owner' and user_id <> auth.uid())
  with check (role in ('editor', 'viewer') and user_id <> auth.uid());
create policy "owners remove members, members leave" on public.tree_members
  for delete using (
    (public.tree_role(tree_id) = 'owner' and user_id <> auth.uid())
    or (user_id = auth.uid() and role <> 'owner')
  );

-- ------------------------------------------------------------- realtime
-- Collaborators see each other's edits live. Full replica identity lets
-- delete events carry tree_id so they can be filtered per tree.
alter table public.persons replica identity full;
alter table public.unions replica identity full;
alter table public.parent_links replica identity full;

alter publication supabase_realtime
  add table public.persons, public.unions, public.parent_links;
