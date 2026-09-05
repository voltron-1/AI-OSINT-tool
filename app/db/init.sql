-- 0.1 — Postgres schema + Apache AGE extension bootstrap.
--
-- The image entrypoint creates the role and database from POSTGRES_USER /
-- POSTGRES_DB; this script only layers AGE on top. It runs once, from the
-- compose init-script mount, the first time the db volume is initialised.
-- Everything here is idempotent so it can also be replayed by hand against an
-- existing database.

CREATE EXTENSION IF NOT EXISTS age;

-- CREATE EXTENSION does not run the library's _PG_init() in this backend, and
-- AGE's parser hooks only activate once it is loaded. Required for this session.
LOAD 'age';
SET search_path = public, ag_catalog;

-- Every later session needs the same two things — the AGE library loaded and
-- ag_catalog on the search_path — or cypher() does not resolve. Pin both on the
-- database so connectors and psql sessions inherit them without boilerplate.
--
-- Two deliberate choices in this path, both verified by scripts/verify-db.sh:
--
-- ag_catalog goes LAST. Postgres creates unqualified objects in the first
-- *existing* schema on the path, so listing ag_catalog first would silently land
-- every later migration's tables inside AGE's extension schema — invisible in a
-- schema dump and destroyed by a DROP EXTENSION. Last still resolves cypher()
-- and agtype, because resolution searches the whole path.
--
-- "$user" is omitted. It normally resolves to nothing, but create_graph('osint')
-- creates a schema named after the graph, and the default role is also 'osint'
-- (POSTGRES_USER), so "$user" would resolve to the graph's own schema and put
-- application tables inside it, where drop_graph('osint', true) removes them.
-- This is a single-application database with no per-user schema convention.
--
-- session_preload_libraries fails the *connection* when the library cannot load,
-- so if an AGE upgrade ever moves the .so, every session is locked out. Unlock
-- from the maintenance database:
--   psql -d postgres -c 'ALTER DATABASE osint RESET session_preload_libraries'
DO $$
BEGIN
    EXECUTE format(
        'ALTER DATABASE %I SET search_path = public, ag_catalog',
        current_database()
    );
    EXECUTE format(
        'ALTER DATABASE %I SET session_preload_libraries = %L',
        current_database(), 'age'
    );
END
$$;

-- The single graph Phase 1 resolves entities into:
-- domain -> subdomain -> cert -> IP -> service -> finding.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ag_catalog.ag_graph WHERE name::text = 'osint'
    ) THEN
        PERFORM ag_catalog.create_graph('osint');
    END IF;
END
$$;
