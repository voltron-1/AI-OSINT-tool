# Planned Execution — AI OSINT Tool

Sequenced execution view. Derived from the GitHub issue tracker + merged PR history;
the [issue tracker](https://github.com/voltron-1/AI-OSINT-tool/issues) remains the source of truth for completion state.
Milestone content derives from [`docs/implementation-plan.md`](https://github.com/voltron-1/AI-OSINT-tool/blob/main/docs/implementation-plan.md).

Status: `[ ]` todo · `[~]` in-progress · `[x]` done · `[!]` blocked

Board: [AI OSINT Tool](https://github.com/users/voltron-1/projects/24) · Wiki: [Home](https://github.com/voltron-1/AI-OSINT-tool/wiki) · [Architecture](https://github.com/voltron-1/AI-OSINT-tool/wiki/Architecture)

---

## NEXT UP

**Phase 0 (M1) — Authorization foundation. Next unstarted item: [#2](https://github.com/voltron-1/AI-OSINT-tool/issues/2) — 0.1 Postgres schema + AGE extension** (`app/db/init.sql`, compose init-script mount). Done when `docker compose up db` starts clean and `SELECT * FROM ag_catalog.ag_graph;` shows the graph.

Nothing in the application is implemented yet. `connectors/base.py` is a stub, `app/` holds only a `.gitkeep`, so `docker compose up` cannot build until [#7](https://github.com/voltron-1/AI-OSINT-tool/issues/7) (0.6) lands the Dockerfile and entrypoint.

**Phases are sequential.** No Phase 1 connector (M2) starts before M1's registry and DCV actually reject an unauthorized target. M5 (autonomous mode) does not start until M2 has run against at least one real domain — the plan's own condition.

**Work order inside M1** (one PR per issue, each through implement → parallel security-auditor + code-reviewer review → verify → PR → CI → merge → update this doc → commit+push):
[#2](https://github.com/voltron-1/AI-OSINT-tool/issues/2) → [#3](https://github.com/voltron-1/AI-OSINT-tool/issues/3) → [#4](https://github.com/voltron-1/AI-OSINT-tool/issues/4) → [#5](https://github.com/voltron-1/AI-OSINT-tool/issues/5) → [#6](https://github.com/voltron-1/AI-OSINT-tool/issues/6) → [#7](https://github.com/voltron-1/AI-OSINT-tool/issues/7) → [#8](https://github.com/voltron-1/AI-OSINT-tool/issues/8)

That is the plan's own 0.1 → 0.6 order, with the test harness last. It is not negotiable downward: 0.4's `dcv_verified` guard has nothing to guard until 0.3 lands, and 0.6's wire-up needs 0.5's provenance model.

## LAST SESSION

**2026-09-05** — layout and CI-config corrections. Still no application code.

- [x] **Repo layout flattened** — [PR #63](https://github.com/voltron-1/AI-OSINT-tool/pull/63), merged `c9428cb`. Content sat one level down in `ai-osint-tool/` inside a repo of the same name, contradicting the implementation plan every issue is written against (it uses root-relative paths throughout). README, LICENSE, compose, `.env.example`, `app/`, `connectors/`, `docs/`, `scripts/` moved to the root; the two `.gitignore` files merged; every path rewritten in the workflows, CODEOWNERS, dependabot.yml and this doc. Two references would have broken outright: the compose job's env copy and Trivy's `scan-ref`.
- [x] **Dependabot config fixed, two CI failures resolved** — both were defects in the `dependabot.yml` shipped in PR #55.
  - CodeQL failed on [#56](https://github.com/voltron-1/AI-OSINT-tool/pull/56)/[#57](https://github.com/voltron-1/AI-OSINT-tool/pull/57): with no `groups:` block, Dependabot split `github/codeql-action/init` and `.../analyze` into one PR each, but they are one action at runtime and a version skew fails the job (`Loaded a configuration file for version X, but running version Y`). Grouped in `99f6aa4`; both PRs closed. Dependabot re-proposed the same bump correctly as [PR #62](https://github.com/voltron-1/AI-OSINT-tool/pull/62) — 4.36.2 → 4.37.9 with both SHAs in one commit, 12/12 checks green, merged `758551e`.
  - The weekly `pip` run aborted every time (`Repo must contain a requirements.txt, setup.py, setup.cfg, pyproject.toml, or a Pipfile`). Ecosystem removed and kept as a comment; re-enabling it is now an acceptance criterion on [#7](https://github.com/voltron-1/AI-OSINT-tool/issues/7) (step 0.6).

**2026-09-04** — project scaffolding session. No application code written; everything below is tracker, board, wiki, docs, and CI.

- [x] **CI ported from Suburban_SOC** — [PR #55](https://github.com/voltron-1/AI-OSINT-tool/pull/55), squash-merged as `e4e6baf`. Five workflows (lint, secret-scan, security-scan, codeql, delete-merged-branch) plus CODEOWNERS, dependabot.yml, .gitleaks.toml, .yamllint, .python-version (3.12), root .gitignore. All 12 checks green on the PR and on main. Reviewed by security-auditor + code-reviewer; dispositions in `findings/20260904-ci-workflows-*.md`. Every action re-pinned to a Node 24 major — the source repo's Node 20 pins fail on current runners (Node 20 removed from hosted runners 2026-09-16).
- [x] **Backlog created, then restructured** — 6 milestones, 54 issues (6 `user-story` parents + 48 children), one issue per numbered plan step. The first cut derived from the README; it was rewritten in place once `implementation-plan.md` was committed, so no issue was orphaned or closed as superseded.
- [x] **Project board** — [#24](https://github.com/users/voltron-1/projects/24), copied from the Suburban_SOC board so all nine automations, the five views, and the Status/Priority/Size/Estimate fields carried over. 54 items classified.
- [x] **Wiki** — [Home](https://github.com/voltron-1/AI-OSINT-tool/wiki) and [Architecture](https://github.com/voltron-1/AI-OSINT-tool/wiki/Architecture) written (wiki commit `b1b85fa`), replacing the one-line stub.
- [x] **Guardrail gaps filed** — the four controls from `OSINT_LLM_Guardrails_Framework.docx` that had no backlog item: [#58](https://github.com/voltron-1/AI-OSINT-tool/issues/58) PII masking on ingest and [#59](https://github.com/voltron-1/AI-OSINT-tool/issues/59) proxy/egress tiers under M4, [#60](https://github.com/voltron-1/AI-OSINT-tool/issues/60) entity-correlation hop cap under M5, [#61](https://github.com/voltron-1/AI-OSINT-tool/issues/61) standardized confidence rating under M6. The [Architecture wiki page](https://github.com/voltron-1/AI-OSINT-tool/wiki/Architecture#guardrail-mapping) now maps every pillar to planned work (wiki commit `029cdc0`). Backlog: 58 issues.
- [x] **Docs committed** — `implementation-plan.md` (`4820537`), `OSINT_LLM_Guardrails_Framework.docx` (`a1d536f`).

---

## Milestones

| Milestone | Done | Scope |
|---|---|---|
| [M1 - Phase 0: Scaffold — Registration & DCV Gate Access](https://github.com/voltron-1/AI-OSINT-tool/milestone/1) | 0/8 | Postgres+AGE init, targets table, DCV (DNS TXT / HTTP file / WHOIS email), connector base with the `dcv_verified` guard, Provenance + STIX model, wire-up |
| [M2 - Phase 1: Lane 1 Vertical Slice — First Real Exposure Report](https://github.com/voltron-1/AI-OSINT-tool/milestone/2) | 0/13 | Nine Lane 1 connectors, entity resolution into the graph, Ollama enrichment, analyst UI and one-page exposure report |
| [M3 - Phase 2: Lane 2 — First Lookalike-Domain Alert](https://github.com/voltron-1/AI-OSINT-tool/milestone/3) | 0/7 | Typosquat engine, lookalike-cert alerting, newly-registered-domain and phishing-feed cross-reference, optional visual clone detection, spoofability verdict |
| [M4 - Cross-Cutting Hardening — Before a Second Real Target](https://github.com/voltron-1/AI-OSINT-tool/milestone/4) | 0/9 | Ollama loopback bind, API/UI auth, ToS enforcement, template auto-update, scanner self-identification, human-dispatched remediation packets, PII masking, proxy/egress tiers |
| [M5 - Autonomous Investigation Mode — First Bounded Run](https://github.com/voltron-1/AI-OSINT-tool/milestone/5) | 0/7 | Trigger and context loader, read-only tool wrappers, scope guard against the target's own graph, bounded loop (25 actions / 20 minutes / 3 hops), output re-entry |
| [M6 - Phase 3 + Phase 4: Gap-Driven Hardening & AI GRC](https://github.com/voltron-1/AI-OSINT-tool/milestone/6) | 0/14 | Delta intelligence, campaign clustering, feedback-calibrated triage, Ed25519 authorization ledger, canary tokens; audit trail, model card, accuracy review, NIST AI RMF, roles, prompt isolation, retention, confidence rating |

### M1 - Phase 0: Scaffold — Registration & DCV Gate Access

[Milestone 1](https://github.com/voltron-1/AI-OSINT-tool/milestone/1) · user story [#1](https://github.com/voltron-1/AI-OSINT-tool/issues/1) · P0 · 0/7 child issues done

[ ] **[#1](https://github.com/voltron-1/AI-OSINT-tool/issues/1)** — US: Registration and DCV actually gate access (Phase 0 complete)

- [ ] [#2](https://github.com/voltron-1/AI-OSINT-tool/issues/2) — 0.1 Postgres schema + AGE extension: init.sql and compose init-script mount
- [ ] [#3](https://github.com/voltron-1/AI-OSINT-tool/issues/3) — 0.2 Authorized-targets table + registration endpoint (POST /targets, GET /targets/{id})
- [ ] [#4](https://github.com/voltron-1/AI-OSINT-tool/issues/4) — 0.3 Domain control validation: DNS TXT, HTTP file, and WHOIS-contact email proofs (POST /targets/{id}/verify)
- [ ] [#5](https://github.com/voltron-1/AI-OSINT-tool/issues/5) — 0.4 Connector base class: rate limiter, retry/backoff, ToS metadata, and dcv_verified guard
- [ ] [#6](https://github.com/voltron-1/AI-OSINT-tool/issues/6) — 0.5 Provenance + STIX 2.1 object model (domain-name, ipv4-addr, x509-certificate, indicator)
- [ ] [#7](https://github.com/voltron-1/AI-OSINT-tool/issues/7) — 0.6 Wire it together: FastAPI app boots against Postgres+AGE, exposes /targets, end-to-end register → verify → collect gate
- [ ] [#8](https://github.com/voltron-1/AI-OSINT-tool/issues/8) — Test harness: pytest fixtures for targets, provenance, and a stub connector backing the Phase 0 done-when checks

### M2 - Phase 1: Lane 1 Vertical Slice — First Real Exposure Report

[Milestone 2](https://github.com/voltron-1/AI-OSINT-tool/milestone/2) · user story [#9](https://github.com/voltron-1/AI-OSINT-tool/issues/9) · P1 · 0/12 child issues done

[ ] **[#9](https://github.com/voltron-1/AI-OSINT-tool/issues/9)** — US: First real exposure report on a domain you own (Phase 1 complete)

- [ ] [#10](https://github.com/voltron-1/AI-OSINT-tool/issues/10) — 1.1 Subdomain discovery connector (connectors/subfinder.py wrapping subfinder / amass / assetfinder)
- [ ] [#11](https://github.com/voltron-1/AI-OSINT-tool/issues/11) — 1.2 DNS resolution connector (connectors/dnsx.py)
- [ ] [#12](https://github.com/voltron-1/AI-OSINT-tool/issues/12) — 1.3 Certificate transparency connector (connectors/certstream.py: crt.sh + certstream)
- [ ] [#13](https://github.com/voltron-1/AI-OSINT-tool/issues/13) — 1.4 Port/service scan connector (connectors/naabu.py) — explicitly gated on target.dcv_verified, first active scanner
- [ ] [#14](https://github.com/voltron-1/AI-OSINT-tool/issues/14) — 1.5 Web probing connector (connectors/httpx_probe.py: httpx + whatweb)
- [ ] [#15](https://github.com/voltron-1/AI-OSINT-tool/issues/15) — 1.6 Misconfig/exposure detection connector (connectors/nuclei.py)
- [ ] [#16](https://github.com/voltron-1/AI-OSINT-tool/issues/16) — 1.7 Cloud bucket exposure connector (connectors/cloud_enum.py)
- [ ] [#17](https://github.com/voltron-1/AI-OSINT-tool/issues/17) — 1.8 Secret leak scanning connector (connectors/gitleaks.py)
- [ ] [#18](https://github.com/voltron-1/AI-OSINT-tool/issues/18) — 1.9 Email spoofability connector (connectors/checkdmarc.py)
- [ ] [#19](https://github.com/voltron-1/AI-OSINT-tool/issues/19) — 1.10 Entity resolution into the AGE graph: domain → subdomain → cert → IP → service → finding (app/graph/resolve.py)
- [ ] [#20](https://github.com/voltron-1/AI-OSINT-tool/issues/20) — 1.11 Ollama enrichment: relevance/risk scoring, de-duplication, cluster summaries (app/enrichment/score.py)
- [ ] [#21](https://github.com/voltron-1/AI-OSINT-tool/issues/21) — 1.12 Analyst UI (Cytoscape.js graph view, triage table) and one-page exposure report (app/ui/, app/reports/exposure.py)

### M3 - Phase 2: Lane 2 — First Lookalike-Domain Alert

[Milestone 3](https://github.com/voltron-1/AI-OSINT-tool/milestone/3) · user story [#22](https://github.com/voltron-1/AI-OSINT-tool/issues/22) · P1 · 0/6 child issues done

[ ] **[#22](https://github.com/voltron-1/AI-OSINT-tool/issues/22)** — US: First lookalike-domain alert for a registered brand (Phase 2 complete)

- [ ] [#23](https://github.com/voltron-1/AI-OSINT-tool/issues/23) — 2.1 Typosquat engine (connectors/dnstwist.py): permute → resolve → MX → fuzzy-hash clone check
- [ ] [#24](https://github.com/voltron-1/AI-OSINT-tool/issues/24) — 2.2 Lookalike certificate alerting: brand-keyword filtering in connectors/certstream.py
- [ ] [#25](https://github.com/voltron-1/AI-OSINT-tool/issues/25) — 2.3 Newly-registered-domain cross-reference (connectors/whoisds.py)
- [ ] [#26](https://github.com/voltron-1/AI-OSINT-tool/issues/26) — 2.4 Known-phishing cross-reference (connectors/phishfeeds.py: OpenPhish, PhishTank, abuse.ch)
- [ ] [#27](https://github.com/voltron-1/AI-OSINT-tool/issues/27) — 2.5 Visual clone detection, optional (connectors/screenshot.py: Playwright + imagehash)
- [ ] [#28](https://github.com/voltron-1/AI-OSINT-tool/issues/28) — 2.6 Own-domain spoofability verdict: reuse connectors/checkdmarc.py from Lane 1 in the Lane 2 report

### M4 - Cross-Cutting Hardening — Before a Second Real Target

[Milestone 4](https://github.com/voltron-1/AI-OSINT-tool/milestone/4) · user story [#29](https://github.com/voltron-1/AI-OSINT-tool/issues/29) · P1 · 0/8 child issues done

[ ] **[#29](https://github.com/voltron-1/AI-OSINT-tool/issues/29)** — US: Cross-cutting hardening in place before anything touches a second real target

- [ ] [#30](https://github.com/voltron-1/AI-OSINT-tool/issues/30) — Hardening: bind Ollama to 127.0.0.1 only — verify docker-compose.yml port mapping and assert it in CI
- [ ] [#31](https://github.com/voltron-1/AI-OSINT-tool/issues/31) — Hardening: API/UI authentication — API key first, don't ship it open
- [ ] [#32](https://github.com/voltron-1/AI-OSINT-tool/issues/32) — Hardening: ToS metadata enforced in the connector base class before every outbound call
- [ ] [#33](https://github.com/voltron-1/AI-OSINT-tool/issues/33) — Hardening: scheduled template auto-update for nuclei and subfinder
- [ ] [#34](https://github.com/voltron-1/AI-OSINT-tool/issues/34) — Hardening: scanner self-identification — distinct User-Agent + contact/opt-out URL on all outbound requests, throttled to target size
- [ ] [#35](https://github.com/voltron-1/AI-OSINT-tool/issues/35) — Hardening: remediation packet generation — evidence + disclosure/abuse-report template, human-dispatched only
- [ ] [#58](https://github.com/voltron-1/AI-OSINT-tool/issues/58) — Guardrail: automated PII masking on ingest — NER scrubbing of collateral identifiers before storage
- [ ] [#59](https://github.com/voltron-1/AI-OSINT-tool/issues/59) — Guardrail: route connector egress through configurable proxy tiers to prevent operational IP disclosure

### M5 - Autonomous Investigation Mode — First Bounded Run

[Milestone 5](https://github.com/voltron-1/AI-OSINT-tool/milestone/5) · user story [#36](https://github.com/voltron-1/AI-OSINT-tool/issues/36) · P2 · 0/6 child issues done

[ ] **[#36](https://github.com/voltron-1/AI-OSINT-tool/issues/36)** — US: First bounded autonomous investigative run with stop conditions verified

- [ ] [#37](https://github.com/voltron-1/AI-OSINT-tool/issues/37) — 8.1 Trigger + context loader (app/autonomous/trigger.py): run after baseline, load findings + graph as starting context
- [ ] [#38](https://github.com/voltron-1/AI-OSINT-tool/issues/38) — 8.2 Curated read-only tool wrappers (app/autonomous/tools.py): WHOIS, passive DNS, cert history, paste/search, read-only fetch, reverse-WHOIS/ASN, Wayback — no naabu/nuclei
- [ ] [#39](https://github.com/voltron-1/AI-OSINT-tool/issues/39) — 8.3 Scope enforcement (app/autonomous/scope_guard.py): refuse and log any entity not tied to the target's own AGE graph
- [ ] [#40](https://github.com/voltron-1/AI-OSINT-tool/issues/40) — 8.4 Loop + stop conditions (app/autonomous/loop.py): max_actions=25, max_duration_minutes=20, no-more-leads
- [ ] [#41](https://github.com/voltron-1/AI-OSINT-tool/issues/41) — 8.5 Output handling: route autonomous findings through normalize → STIX → provenance → graph → triage, no separate storage
- [ ] [#60](https://github.com/voltron-1/AI-OSINT-tool/issues/60) — Guardrail: cap entity-correlation depth in the autonomous loop (recursion maximum, e.g. 3 hops)

### M6 - Phase 3 + Phase 4: Gap-Driven Hardening & AI GRC

[Milestone 6](https://github.com/voltron-1/AI-OSINT-tool/milestone/6) · user story [#42](https://github.com/voltron-1/AI-OSINT-tool/issues/42) · P2 · 0/13 child issues done

[ ] **[#42](https://github.com/voltron-1/AI-OSINT-tool/issues/42)** — US: Hardening and governance layered on a working system (Phase 3 + Phase 4)

- [ ] [#43](https://github.com/voltron-1/AI-OSINT-tool/issues/43) — 9.1 Delta-only change intelligence (app/enrichment/delta.py): content-hash per entity, diff vs prior run, rolling posture score
- [ ] [#44](https://github.com/voltron-1/AI-OSINT-tool/issues/44) — 9.2 Campaign clustering (app/graph/cluster.py): fingerprint by ASN / cert issuer / favicon / template into campaign nodes
- [ ] [#45](https://github.com/voltron-1/AI-OSINT-tool/issues/45) — 9.3 Feedback-calibrated triage (app/enrichment/dispositions.py): log analyst TP/FP calls, sample into the scoring prompt
- [ ] [#46](https://github.com/voltron-1/AI-OSINT-tool/issues/46) — 9.4 Signed authorization ledger (app/models/ledger.py): Ed25519-signed record at registration, referenced by every finding's provenance
- [ ] [#47](https://github.com/voltron-1/AI-OSINT-tool/issues/47) — 9.5 Canary-token module (app/canary/): decoy identifiers per target, periodic check against paste/search sources
- [ ] [#48](https://github.com/voltron-1/AI-OSINT-tool/issues/48) — 10.1–10.2 Decision audit trail + human-override log (app/audit/), covering investigative actions as well as scoring
- [ ] [#49](https://github.com/voltron-1/AI-OSINT-tool/issues/49) — 10.3 Model card (docs/model-card.md): plain-language write-up, updated whenever the model or prompts change
- [ ] [#50](https://github.com/voltron-1/AI-OSINT-tool/issues/50) — 10.4 Scheduled accuracy review (app/audit/accuracy_review.py): sample past scores against dispositions
- [ ] [#51](https://github.com/voltron-1/AI-OSINT-tool/issues/51) — 10.5 NIST AI RMF alignment checklist (docs/framework-alignment.md), living document
- [ ] [#52](https://github.com/voltron-1/AI-OSINT-tool/issues/52) — 10.6 Roles and permissions (app/auth/roles.py): register / scan / view / override split
- [ ] [#53](https://github.com/voltron-1/AI-OSINT-tool/issues/53) — 10.7 Prompt-injection isolation at every prompt-construction point in app/enrichment/ and app/autonomous/: untrusted content never mixed into instruction context
- [ ] [#54](https://github.com/voltron-1/AI-OSINT-tool/issues/54) — 10.8 Retention (app/data/retention.py): retention period per finding class, automated purge/archival job
- [ ] [#61](https://github.com/voltron-1/AI-OSINT-tool/issues/61) — Guardrail: standardized confidence rating on every analytical assessment (Admiralty Code or High/Medium/Low)

---

## DEFERRED

Waiting on an external event or a prerequisite outside the current phase — not blocked work.

| Item | Waiting on |
|---|---|
| [M5 — Autonomous Investigation Mode](https://github.com/voltron-1/AI-OSINT-tool/milestone/5) (issues [#36](https://github.com/voltron-1/AI-OSINT-tool/issues/36)–[#41](https://github.com/voltron-1/AI-OSINT-tool/issues/41), [#60](https://github.com/voltron-1/AI-OSINT-tool/issues/60)) | M2 running against at least one real domain. The plan is explicit: the loop needs real findings to be worth building against, not a stub. |
| pip-audit and Trivy image scan doing real work | A requirements file and `app/Dockerfile` (step 0.6, [#7](https://github.com/voltron-1/AI-OSINT-tool/issues/7)). Both jobs currently emit a `::warning::` and skip; the same issue re-enables Dependabot's `pip` ecosystem. |
| Branch protection ruleset on `main` | Owner action. The CI checks exist but none is required, so a direct push to `main` bypasses them. Recommended required checks: `Lint / *`, `Secret Scan / gitleaks`, `Security Scan / *`, `CodeQL Advanced / Analyze (python)`. See `findings/20260904-ci-workflows-security.md`. |
| "Require approval for all external contributors" | Owner action, repo setting. Public repo; a fork PR can execute code via `docker build` and mypy config discovery. |

## BLOCKED

None.

---

## Notes

- **Conventions mirrored from Suburban_SOC**, at the owner's request: milestone naming, `user-story` parents with As-a/I-want/So-that + acceptance criteria, `priority:*` labels, board fields and automations, wiki structure, and the CI workflow set. Project-specific labels added: `authorization`, `connector`, `ai-triage`, `governance`.
- **CI follow-ups not taken** in PR #55, recorded in `findings/20260904-ci-workflows-security.md`: SARIF upload for Trivy findings, `SECURITY.md`, dependency-review action, OpenSSF Scorecard, harden-runner, and the image-scan severity policy (kept at CRITICAL with `ignore-unfixed`, as mirrored).
- **Working files** under `plans/`, `logs/`, and `findings/` are session artifacts, not deliverables.
