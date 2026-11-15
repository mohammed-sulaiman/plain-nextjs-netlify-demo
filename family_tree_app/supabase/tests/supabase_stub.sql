-- Minimal stand-ins for the Supabase platform so the migrations and their
-- Row Level Security policies can be tested on a plain PostgreSQL server.
-- NOT for production: Supabase provides the real auth/storage schemas.

create role anon nologin;
create role authenticated nologin;

create schema auth;
create table auth.users (id uuid primary key, email text);

-- auth.uid() / auth.jwt() read the claims set by the test helper below.
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
create function auth.jwt() returns jsonb language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb
$$;

create schema storage;
create table storage.buckets (id text primary key, name text, public boolean);
create table storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text,
  name text
);
alter table storage.objects enable row level security;
create function storage.foldername(name text) returns text[] language sql immutable as $$
  select (string_to_array(name, '/'))[1:array_length(string_to_array(name, '/'), 1) - 1]
$$;

create publication supabase_realtime;
