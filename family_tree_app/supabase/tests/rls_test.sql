-- Row Level Security tests for tree sharing. Run through ./run.sh.
-- Every check runs as the API role "authenticated", exactly like the app.

\set ON_ERROR_STOP 1
\set alice '00000000-0000-0000-0000-00000000000a'
\set bob   '00000000-0000-0000-0000-00000000000b'
\set carol '00000000-0000-0000-0000-00000000000c'
\set dave  '00000000-0000-0000-0000-00000000000d'
\set eve   '00000000-0000-0000-0000-00000000000e'

insert into auth.users values
  (:'alice', 'alice@example.com'),
  (:'bob',   'bob@example.com'),
  (:'carol', 'carol@example.com'),
  (:'dave',  'dave@example.com'),
  (:'eve',   'eve@example.com');

-- Sign in as a user (JWT claims), like PostgREST does per request.
create function public.test_login(uid uuid) returns void
language plpgsql security definer as $$
begin
  perform set_config('request.jwt.claim.sub', uid::text, false);
  perform set_config('request.jwt.claims',
    json_build_object('sub', uid, 'email',
      (select email from auth.users where id = uid))::text, false);
end $$;

create function public.check(ok boolean, msg text) returns void
language plpgsql as $$
begin
  if ok is not true then
    raise exception 'CHECK FAILED: %', msg;
  end if;
end $$;

-- Expect a statement to fail; optionally with a message containing `expected`.
create function public.expect_error(stmt text, expected text default null)
returns void language plpgsql as $$
begin
  begin
    execute stmt;
  exception when others then
    if expected is not null and position(expected in sqlerrm) = 0 then
      raise exception 'CHECK FAILED: expected error "%" but got "%" for: %',
        expected, sqlerrm, stmt;
    end if;
    return;
  end;
  raise exception 'CHECK FAILED: expected an error but it succeeded: %', stmt;
end $$;

-- Expect a statement to run but change no rows (filtered out by RLS).
create function public.expect_no_rows(stmt text) returns void
language plpgsql as $$
declare n int;
begin
  execute stmt;
  get diagnostics n = row_count;
  if n <> 0 then
    raise exception 'CHECK FAILED: expected 0 rows, % changed: %', n, stmt;
  end if;
end $$;

grant execute on function public.test_login(uuid), public.check(boolean, text),
  public.expect_error(text, text), public.expect_no_rows(text) to authenticated;

set role authenticated;

\echo '1. Alice creates a tree and becomes its owner'
select public.test_login(:'alice');
insert into public.trees (name) values ('Al-Hasani') returning id as tree \gset
insert into public.persons (id, tree_id, data)
values ('10000000-0000-0000-0000-000000000001', :'tree', '{"givenName":"Ali"}');
select public.check(
  (select role from public.tree_members where tree_id = :'tree' and user_id = :'alice') = 'owner',
  'creator must be owner');

\echo '2. Outsiders see nothing and cannot join or write on their own'
select public.test_login(:'bob');
select public.check((select count(*) from public.trees) = 0, 'bob sees no trees');
select public.check((select count(*) from public.persons) = 0, 'bob sees no persons');
select public.check((select count(*) from public.tree_members_with_email(:'tree')) = 0,
  'bob sees no members');
select public.expect_error(format(
  'insert into public.tree_members (tree_id, user_id, role) values (%L, %L, %L)',
  :'tree', :'bob', 'editor'));
select public.expect_error(format(
  'insert into public.tree_invites (tree_id, role) values (%L, %L)', :'tree', 'editor'));
select public.expect_error(format(
  'insert into public.persons (id, tree_id, data) values (gen_random_uuid(), %L, %L)',
  :'tree', '{}'));

\echo '3. Alice creates invites'
select public.test_login(:'alice');
insert into public.tree_invites (tree_id, role) values (:'tree', 'editor')
returning code as code_editor \gset
insert into public.tree_invites (tree_id, role, email)
values (:'tree', 'viewer', 'Carol@Example.com')
returning code as code_viewer \gset
insert into public.tree_invites (tree_id, role, expires_at)
values (:'tree', 'editor', now() - interval '1 day')
returning code as code_expired \gset
insert into public.tree_invites (tree_id, role) values (:'tree', 'viewer')
returning id as revoke_id, code as code_revoked \gset
select public.check(length(:'code_editor') = 10, 'code has 10 characters');
select public.expect_error(format(
  'insert into public.tree_invites (tree_id, role) values (%L, %L)', :'tree', 'owner'));

\echo '4. Bob previews and accepts the editor invite (code is case-insensitive)'
select public.test_login(:'bob');
select public.check(
  (select status = 'valid' and tree_name = 'Al-Hasani' and invited_by = 'alice@example.com'
   from public.invite_info(:'code_editor')), 'invite preview');
select public.check(public.accept_invite(lower(' ' || :'code_editor' || ' ')) = :'tree',
  'accept returns tree id');
select public.check((select count(*) from public.persons) = 1, 'bob now sees persons');
insert into public.persons (id, tree_id, data)
values ('10000000-0000-0000-0000-000000000002', :'tree', '{"givenName":"Fatima"}');
update public.persons set data = '{"givenName":"Ali bin Hasan"}'
where id = '10000000-0000-0000-0000-000000000001';
select public.check((select updated_by from public.persons
  where id = '10000000-0000-0000-0000-000000000001') = :'bob', 'updated_by tracks editor');
select public.check((select count(*) from public.tree_invites) = 0, 'editors cannot list invites');
select public.expect_error(format(
  'insert into public.tree_invites (tree_id, role) values (%L, %L)', :'tree', 'viewer'));
select public.expect_no_rows(format(
  'update public.tree_members set role = %L where tree_id = %L and user_id = %L',
  'viewer', :'tree', :'alice'));

\echo '5. Invites cannot be reused, expired invites fail, email-bound invites check the email'
select public.expect_error(format('select public.accept_invite(%L)', :'code_editor'), 'invite_used');
select public.expect_error(format('select public.accept_invite(%L)', :'code_expired'), 'invite_expired');
select public.expect_error('select public.accept_invite(''NOPE000000'')', 'invite_not_found');
select public.test_login(:'eve');
select public.expect_error(format('select public.accept_invite(%L)', :'code_viewer'), 'invite_wrong_email');
select public.check((select count(*) from public.persons) = 0, 'eve still sees nothing');

\echo '6. Carol joins as viewer: read-only'
select public.test_login(:'carol');
select public.accept_invite(:'code_viewer');
select public.check((select count(*) from public.persons) = 2, 'viewer reads persons');
select public.check((select count(*) from public.tree_members_with_email(:'tree')) = 3,
  'viewer lists members');
select public.check(
  (select string_agg(role, ',') from public.tree_members_with_email(:'tree')) = 'owner,editor,viewer',
  'members ordered by role');
select public.expect_error(format(
  'insert into public.persons (id, tree_id, data) values (gen_random_uuid(), %L, %L)',
  :'tree', '{}'));
select public.expect_no_rows(
  'update public.persons set data = ''{}'' where id = ''10000000-0000-0000-0000-000000000001''');
select public.expect_no_rows(
  'delete from public.persons where id = ''10000000-0000-0000-0000-000000000001''');

\echo '7. Owner manages roles but cannot demote or remove themselves, or grant ownership'
select public.test_login(:'alice');
select public.check((select count(*) from public.tree_invites where accepted_at is not null) = 2,
  'owner sees accepted invites');
update public.tree_members set role = 'editor' where tree_id = :'tree' and user_id = :'carol';
select public.check((select role from public.tree_members
  where tree_id = :'tree' and user_id = :'carol') = 'editor', 'carol promoted');
select public.expect_error(format(
  'update public.tree_members set role = %L where tree_id = %L and user_id = %L',
  'owner', :'tree', :'bob'));
select public.expect_no_rows(format(
  'update public.tree_members set role = %L where tree_id = %L and user_id = %L',
  'viewer', :'tree', :'alice'));
select public.expect_no_rows(format(
  'delete from public.tree_members where tree_id = %L and user_id = %L', :'tree', :'alice'));

\echo '8. Revoked invites stop working; outsiders cannot revoke'
select public.test_login(:'dave');
select public.expect_no_rows(format('delete from public.tree_invites where id = %L', :'revoke_id'));
select public.test_login(:'alice');
delete from public.tree_invites where id = :'revoke_id';
select public.test_login(:'dave');
select public.expect_error(format('select public.accept_invite(%L)', :'code_revoked'), 'invite_not_found');

\echo '9. Members can leave; the owner removes members'
select public.test_login(:'carol');
delete from public.tree_members where tree_id = :'tree' and user_id = :'carol';
select public.check((select count(*) from public.persons) = 0, 'carol left');
select public.test_login(:'alice');
delete from public.tree_members where tree_id = :'tree' and user_id = :'bob';
select public.check((select count(*) from public.tree_members where tree_id = :'tree') = 1,
  'only owner remains');
select public.test_login(:'bob');
select public.check((select count(*) from public.persons) = 0, 'removed member loses access');

\echo '10. Anonymous users cannot preview or accept invites'
select set_config('request.jwt.claim.sub', '', false);
select public.check((select count(*) from public.invite_info(:'code_viewer')) = 0, 'anon preview');
select public.expect_error(format('select public.accept_invite(%L)', :'code_viewer'), 'not_authenticated');

reset role;
