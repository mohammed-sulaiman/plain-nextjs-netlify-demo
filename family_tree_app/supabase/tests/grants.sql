-- Supabase grants table access to the API roles and relies on RLS.
grant usage on schema public, auth, storage to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant select, insert, update, delete on storage.objects to authenticated;
grant execute on all functions in schema public, auth, storage to anon, authenticated;
