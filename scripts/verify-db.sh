#!/usr/bin/env bash
# Checks step 0.1's done-when conditions against a real database:
#   1. the db service starts clean (healthy, no errors in the init log)
#   2. SELECT * FROM ag_catalog.ag_graph; shows the graph
#
# Plus two regression guards on init.sql's persisted session defaults:
#   3. unqualified objects are still created in public, not in ag_catalog
#   4. cypher() resolves in a fresh session with no LOAD and no SET
#
# Runs under its own compose project name, so it creates and destroys its own
# throwaway volume and never touches the default project's db_data.
#
# Usage: scripts/verify-db.sh [--keep]
#   --keep   leave the throwaway stack running for manual poking
set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT="osint-db-verify"
GRAPH="osint"
keep=0

case "${1:-}" in
    "") ;;
    --keep) keep=1 ;;
    *) echo "usage: $0 [--keep]" >&2; exit 2 ;;
esac

compose() { docker compose -p "$PROJECT" -f docker-compose.yml "$@"; }
fail() { echo "FAIL: $*" >&2; exit 1; }

# psql over the container's local socket as the image's superuser, so no
# password ever reaches a host process listing. SQL arrives on stdin to keep
# the nesting to one level of quoting.
sql() {
    compose exec -T db sh -c \
        'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f -'
}
sql_value() {
    compose exec -T db sh -c \
        'psql -v ON_ERROR_STOP=1 -qAt -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f -'
}

[ -f .env ] || fail "no .env — cp .env.example .env and set a real POSTGRES_PASSWORD"
# Absent, Docker bind-mounts a root-owned *directory* over the init script path
# and the database comes up with no AGE and no graph, silently.
[ -f app/db/init.sql ] || fail "app/db/init.sql is missing"

# The teardown below deletes volumes. Compose namespaces bare volumes per
# project, so -p keeps that confined — but fail closed rather than rely on a
# property one edit to docker-compose.yml could remove.
default_project="$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]')"
[ "$PROJECT" != "$default_project" ] \
    || fail "PROJECT matches the default compose project; refusing to run a volume-deleting teardown"
if sed -n '/^volumes:/,$p' docker-compose.yml | grep -qE '^[[:space:]]+(name|external):'; then
    fail "docker-compose.yml names or externalises its volumes; 'down -v' would escape $PROJECT"
fi

cleanup() {
    if [ "$keep" -eq 0 ]; then
        compose down -v >/dev/null || true
    else
        echo "note: '$PROJECT' left running — 'docker compose -p $PROJECT down -v' to clean up"
    fi
}
trap cleanup EXIT

# Always start from a fresh volume: the init script only runs on first init.
compose down -v >/dev/null || true
compose up -d db

# -a so a container that already exited is still found; without it $cid comes
# back empty on a crash-loop and the wait below reports a misleading status.
cid="$(compose ps -aq db)"
[ -n "$cid" ] || fail "no db container was created"

echo "waiting for db to report healthy..."
status=""
for _ in $(seq 1 60); do
    status="$(docker inspect -f '{{.State.Health.Status}}' "$cid" 2>/dev/null || echo unknown)"
    [ "$status" = "healthy" ] && break
    sleep 2
done
if [ "$status" != "healthy" ]; then
    compose logs db >&2
    fail "db never became healthy (last status: ${status:-unknown})"
fi

# Capture before grepping, and assert the capture worked: a log check that
# greps the empty output of a failed command reports PASS on its own failure.
logs="$(compose logs db 2>&1)" || fail "could not read the db startup log"
[ -n "$logs" ] || fail "the db startup log was empty"

# 'FATAL:  the database system is starting up' is the postmaster rejecting a
# probe that landed before recovery finished. With a 5s healthcheck interval
# that is expected, and it is not a startup failure.
if printf '%s\n' "$logs" \
    | grep -v 'the database system is starting up' \
    | grep -Ei '(^|[^a-z])(error|fatal|panic)'; then
    fail "errors in the db startup log (above)"
fi
echo "PASS: db started clean"

echo "querying ag_catalog.ag_graph..."
out="$(sql <<'SQL'
SELECT * FROM ag_catalog.ag_graph;
SQL
)" || fail "the query against ag_catalog.ag_graph failed"
echo "$out"

# Assert server-side rather than substring-matching psql's table output, which
# would also match the namespace column.
count="$(sql_value <<SQL
SELECT count(*) FROM ag_catalog.ag_graph WHERE name::text = '$GRAPH';
SQL
)" || fail "the graph existence query failed"
[ "$count" = "1" ] || fail "graph '$GRAPH' not present in ag_catalog.ag_graph (count=$count)"
echo "PASS: graph '$GRAPH' present"

# init.sql puts ag_catalog last on the persisted search_path precisely so that
# later migrations create their tables in public. Guard the ordering.
schema="$(sql_value <<'SQL'
SELECT current_schema();
SQL
)" || fail "the current_schema() query failed"
[ "$schema" = "public" ] || fail "unqualified objects would be created in '$schema', expected 'public'"
echo "PASS: default creation schema is public"

# The other half of that trade-off: ag_catalog last must still resolve AGE.
sql >/dev/null <<SQL || fail "cypher() does not resolve in a fresh session"
SELECT * FROM cypher('$GRAPH', \$\$ RETURN 1 \$\$) AS (n agtype);
SQL
echo "PASS: cypher() resolves with no LOAD and no SET"
