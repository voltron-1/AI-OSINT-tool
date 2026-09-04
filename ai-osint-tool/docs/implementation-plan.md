# Implementation Plan — AI OSINT Tool

Drop this in `docs/implementation-plan.md` and commit it, so it lives with the code.

## How to use this

Work top to bottom. Each step lists the files it touches, what "done" looks like,
and how to check it. Phases are sequential — don't start Phase 1 connectors before
Phase 0's registry and DCV actually reject an unauthorized target.

## Prerequisites (once)

- Docker + Docker Compose installed
- `cp .env.example .env`, set a real `POSTGRES_PASSWORD`
- `docker compose pull` to fetch base images before writing code

---

## Phase 0 — Scaffold

**0.1 — Postgres schema + AGE extension**
Files: `app/db/init.sql`, `docker-compose.yml` (init script mount)
Create the database, enable the AGE extension, create the initial graph.
Done when: `docker compose up db` starts clean and `SELECT * FROM ag_catalog.ag_graph;` shows the graph.

**0.2 — Authorized-targets table + registration endpoint**
Files: `app/models/target.py`, `app/api/targets.py`
Table: domain, status (`pending`/`active`/`rejected`), created_at, DCV method, DCV proof reference.
`POST /targets` creates a target in `pending`. `GET /targets/{id}` returns status.
Done when: registering a target returns `pending`, and no connector will run against it yet (there are no connectors yet, but the check should already exist as a no-op guard).

**0.3 — Domain control validation (DCV)**
Files: `app/services/dcv.py`, `app/api/targets.py`
Implement the three accepted proofs: DNS TXT record lookup, HTTP file at a defined path, WHOIS-contact confirmation email.
`POST /targets/{id}/verify` checks the chosen method and flips status to `active` on success.
Done when: a target with no TXT record / no file / no WHOIS confirmation stays `pending`, and one with a correct TXT record flips to `active`.

**0.4 — Connector base class**
Files: `connectors/base.py` (already stubbed — extend it)
Add: rate limiter (per-connector, token bucket is enough), retry/backoff wrapper, ToS metadata field, a guard that raises if `target.dcv_verified` is `False`.
Done when: calling `.collect()` on a stub connector with an unverified target raises before making any request.

**0.5 — Provenance + STIX object model**
Files: `app/models/provenance.py`, `app/models/stix.py`
Provenance record: source tool, method, captured_at, authorization_ref (placeholder until 9.4's ledger exists).
STIX mapping: define the object types you'll actually use in Phase 1 (domain-name, ipv4-addr, x509-certificate, indicator) — don't build the whole STIX spec, just what's needed.
Done when: a hand-built test artifact serializes to valid STIX 2.1 JSON.

**0.6 — Wire it together**
Files: `docker-compose.yml`, `app/main.py`
FastAPI app boots, connects to Postgres+AGE, exposes `/targets`.
Done when: `docker compose up` brings up all three services, and the sequence "register → verify → attempt collect on unverified target fails, verified target doesn't" works end to end.

---

## Phase 1 — Lane 1 vertical slice (Attack Surface / EASM)

Build connectors in this order — each is independently testable against a real domain you control.

**1.1 Subdomain discovery** — `connectors/subfinder.py` (wraps subfinder/amass/assetfinder)
**1.2 DNS resolution** — `connectors/dnsx.py`
**1.3 Certificate transparency** — `connectors/certstream.py` (crt.sh + certstream)
**1.4 Port/service scan** — `connectors/naabu.py` — **gate this one explicitly on `target.dcv_verified`, it's the first active scanner**
**1.5 Web probing** — `connectors/httpx_probe.py` (httpx + whatweb)
**1.6 Misconfig/exposure detection** — `connectors/nuclei.py`
**1.7 Cloud bucket exposure** — `connectors/cloud_enum.py`
**1.8 Secret leak scanning** — `connectors/gitleaks.py`
**1.9 Email spoofability** — `connectors/checkdmarc.py`

For each: implement `.collect()`, map output to the STIX objects from 0.5, attach provenance, write one test against a domain you own.

**1.10 — Entity resolution into the graph**
Files: `app/graph/resolve.py`
Build the chain: domain → subdomain → cert → IP → service → finding, as AGE graph edges.
Done when: querying the graph for a target returns a connected structure, not isolated nodes.

**1.11 — Ollama enrichment**
Files: `app/enrichment/score.py`
Relevance/risk scoring, de-duplication, cluster summaries. Model reads only from the findings table — no tool access yet.
Done when: running enrichment on a batch of findings returns a score and a short summary for each.

**1.12 — Analyst UI**
Files: `app/ui/` (graph view via Cytoscape.js, triage table), `app/reports/exposure.py` (one-page report generator)
Done when: one authorized domain run end-to-end produces an asset inventory, a ranked exposure list, and a report a human can read without touching the database.

**Phase 1 done when:** a registered, DCV-verified domain runs through every connector above and produces a real report.

---

## Phase 2 — Lane 2 (Impersonation / Phishing Domains)

**2.1 Typosquat engine** — `connectors/dnstwist.py` (permute → resolve → MX → fuzzy-hash clone check)
**2.2 Lookalike cert alerting** — extend `connectors/certstream.py` with brand-keyword filtering
**2.3 Newly-registered-domain cross-ref** — `connectors/whoisds.py`
**2.4 Known-phishing cross-ref** — `connectors/phishfeeds.py` (OpenPhish, PhishTank, abuse.ch)
**2.5 Visual clone detection (optional)** — `connectors/screenshot.py` (Playwright + imagehash)
**2.6 Own-domain spoofability** — reuse `connectors/checkdmarc.py` from Lane 1

**Phase 2 done when:** a registered brand yields live-lookalike alerts and a spoofability verdict, using Lane 1's DNS/cert collectors underneath.

---

## Cross-cutting hardening (build alongside Phases 1–2, don't defer)

- Bind Ollama to `127.0.0.1` only — check `docker-compose.yml` port mapping
- Auth on the UI/API — pick something simple first (API key), don't ship it open
- ToS metadata enforced in the connector base class before every call (should already exist from 0.4)
- Scheduled template auto-update for nuclei/subfinder
- Scanner self-identification: distinct User-Agent + contact/opt-out URL on all outbound requests, throttled to target size
- Remediation packet generation: evidence + template for disclosure/abuse reporting, human-dispatched only

---

## Autonomous Investigation Mode

Build this after Phase 1–2 are solid — it depends on there being real baseline data to investigate.

**8.1 — Trigger + context loader**
Files: `app/autonomous/trigger.py`
Runs after a baseline collection completes. Loads the target's existing findings + graph as starting context.

**8.2 — Curated read-only tool wrappers**
Files: `app/autonomous/tools.py`
WHOIS lookup, passive DNS lookup, cert history lookup, paste-site/search query, read-only page fetch. Add reverse-WHOIS/ASN lookup and Wayback snapshot as the two extra tools discussed. Do **not** wire naabu or nuclei into this module — active scanning stays out of the loop by design.

**8.3 — Scope enforcement**
Files: `app/autonomous/scope_guard.py`
Before any tool call executes, check the proposed entity against the target's own AGE graph. Refuse and log if it doesn't resolve to something already tied to the authorized target.
Done when: a hand-crafted "investigate this unrelated domain" attempt is refused, not executed.

**8.4 — Loop + stop conditions**
Files: `app/autonomous/loop.py`
Config: `max_actions=25`, `max_duration_minutes=20`. Loop: propose lead → scope check → call tool → integrate result → decide continue/stop.
Done when: a run against a real target stops at one of the three conditions (no more leads / action cap / time cap) and logs which one.

**8.5 — Output handling**
Route findings through the same normalize → STIX → provenance → graph → triage path as Phases 1–2. No separate storage path.

---

## Phase 3 — Gap-driven hardening features

**9.1 Delta-only change intelligence** — `app/enrichment/delta.py` — content-hash per entity, diff against prior run, rolling posture score
**9.2 Campaign clustering** — `app/graph/cluster.py` — fingerprint by ASN/cert issuer/favicon/template, cluster into campaign nodes
**9.3 Feedback-calibrated triage** — `app/enrichment/dispositions.py` — log analyst true/false-positive calls, sample recent ones into the scoring prompt
**9.4 Signed authorization ledger** — `app/models/ledger.py` — Ed25519-signed record at registration, referenced by every finding's provenance
**9.5 Canary-token module** — `app/canary/` — generate decoy identifiers per target, periodic check against paste/search sources

---

## Phase 4 — Governance & AI GRC

Mostly schema + process, not new detection logic:

- **10.1/10.2** — `app/audit/` — decision audit trail + human-override log (extend to cover Section 8's investigative actions, not just scoring)
- **10.3** — `docs/model-card.md` — plain-language write-up, update whenever the model or prompts change
- **10.4** — `app/audit/accuracy_review.py` — scheduled job sampling past scores against dispositions
- **10.5** — `docs/framework-alignment.md` — living checklist against NIST AI RMF
- **10.6** — `app/auth/roles.py` — role/permission split (register, scan, view, override)
- **10.7** — apply to every prompt-construction point in `app/enrichment/` and `app/autonomous/` — untrusted content never mixed into instruction context
- **10.8** — `app/data/retention.py` — retention period per finding class, automated purge/archival job

---

## Suggested milestones

1. Phase 0 complete — registration and DCV actually gate access
2. Phase 1 complete — first real exposure report on a domain you own
3. Phase 2 complete — first lookalike-domain alert
4. Cross-cutting hardening in place before anything touches a second real target
5. Autonomous mode — first bounded investigative run, verify stop conditions actually fire
6. Phase 3 + Phase 4 — hardening and governance layered on top of a working system

Don't start milestone 5 until milestone 2 has run against at least one real domain — the autonomous loop needs real findings to be worth building against, not a stub.
