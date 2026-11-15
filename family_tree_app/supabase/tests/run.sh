#!/usr/bin/env bash
# Runs the migrations and the RLS tests against a throwaway database.
# Usage: PGHOST=... PGUSER=... ./run.sh   (needs a superuser connection)
set -euo pipefail
cd "$(dirname "$0")"
DB=family_tree_rls_test
dropdb --if-exists "$DB" >/dev/null
createdb "$DB"
psql_q() { psql -v ON_ERROR_STOP=1 -q -X -d "$DB" "$@"; }
psql_q -c "drop role if exists authenticated; drop role if exists anon;" 2>/dev/null || true
psql_q -f supabase_stub.sql
for m in ../migrations/*.sql; do psql_q -f "$m"; done
psql_q -f grants.sql
psql_q -o /dev/null -f rls_test.sql
echo "All RLS tests passed."
