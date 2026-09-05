# Plan — Agile project board, wiki, and CI for AI-OSINT-tool

Date: 2026-09-04
Reference conventions: voltron-1/Suburban_SOC (board #17, labels, milestone/issue format, wiki layout, GitHub Actions).
Target: voltron-1/AI-OSINT-tool (repo content lives under `ai-osint-tool/`).

Gating: one phase per pass; stop and report after each; show the diff before any push, commit, or PR.

## Phase 1 — Repo setup (labels, milestones, issues)  [x] done 2026-09-04 (superseded by 1b)
- Labels (Suburban_SOC set minus Zeek/Sigma-specific ones, plus domain equivalents):
  user-story, security, priority:critical, priority:medium, priority:low, tech-debt,
  dependencies, python, authorization, connector, ai-triage.
  Skipped: "Good second/third/fourth issue", detection, nist-compliance.
- Milestones (M1–M6, "M{N} - Title", description carries the README phase number):
  M1 Authorization Foundation: Target Registry, Connector Contract & DCV (Phase 0)
  M2 Lane 1: Attack-Surface (EASM) Connectors (Phase 1)
  M3 Lane 2: Impersonation & Phishing-Domain Connectors (Phase 2)
  M4 Normalization: Provenance, STIX 2.1 & Entity Graph (Phase 3)
  M5 Bounded AI Triage: Scoring, Dedup & Report Drafting (Phase 4)
  M6 Autonomous Investigation Mode & Analyst Disposition (Phase 5)
- Issues: one `user-story` parent per milestone ("US: ...", As-a/I-want/So-that + acceptance
  criteria), children attached as GitHub sub-issues. 6 parents + 21 children = 27.
  M1 children: registry + signed authorization record; DCV challenge flow; connector-contract
  enforcement; app image + compose bootstrap; pytest harness proving unverified targets are refused.
- Priority labels: M1 critical, M2/M3 medium, M4–M6 low.
- Exit gate: `gh issue list` shows 27 issues, each with exactly one milestone; sub-issue links verified.

## Phase 1b — Restructure backlog to docs/implementation-plan.md  [x] done 2026-09-04
- Trigger: user committed `ai-osint-tool/docs/implementation-plan.md` (4820537) after Phase 1; its
  "Suggested milestones" and numbered steps superseded the README-derived M1–M6.
- Milestones 1–6 renamed in place to the plan's six suggested milestones (Phase 0 / Phase 1 / Phase 2 /
  cross-cutting hardening / autonomous mode / Phase 3+4).
- One issue per numbered plan step + one user story per milestone; test-harness issue kept as an M1 extra.
  27 existing issues rewritten in place (#1–#27), 27 created (#28–#54). Sub-issues re-parented.
  User stories: #1 (M1), #9 (M2), #22 (M3), #29 (M4), #36 (M5), #42 (M6).
- Board #24: 54 items; P0 = M1, P1 = M2–M4, P2 = M5–M6; Ready = #1, #2; Size/Estimate set.
- Also committed on user request: `docs/OSINT_LLM_Guardrails_Framework.docx` — candidate inputs for the
  backlog not yet filed: PII masking, egress proxy tiers, confidence schema (Admiralty), 3-hop correlation cap.

## Phase 2 — Project board (copy of Suburban_SOC board #17)  [x] done 2026-09-04 → board #24
- `copyProjectV2` from project #17 → new user project; retitle "AI OSINT Tool"; set short
  description + README (Suburban_SOC/UIW-IDS style: how to use the board, resources).
- Link to the repo; add all 27 issues; set Status (Backlog; first M1 child Ready),
  Priority (P0 M1 / P1 M2–M3 / P2 M4–M6), Size.
- Verify via GraphQL that the nine workflows copied: Item added, Item closed, Item reopened,
  PR linked, PR merged, Code review approved, Code changes requested, Auto-close issue,
  Auto-add sub-issues. Report any that need a UI toggle (Auto-add to project has no API).
- Exit gate: board item count == 27; workflows list matches; views = Backlog, Priority board,
  Team items, Roadmap, My items.

## Phase 3 — Wiki (Home + Architecture)  [x] done 2026-09-04 → wiki commit b1b85fa
- Home: project status mirroring the milestones, table of contents, authorized-use notice.
- Architecture: pipeline flow, component breakdown (db / ollama / app), authorization model,
  connector contract, data flow detail, related files.
- Show both pages locally, then push to the wiki repo on approval.

## Phase 4 — GitHub Actions CI (portable subset of Suburban_SOC)  [x] done 2026-09-04 → PR #55, merged e4e6baf
- Port: codeql.yml (python), lint.yml (shellcheck, ruff, mypy, yamllint, compose-config;
  drop suricata-syntax), secret-scan.yml (gitleaks + .gitleaks.toml), security-scan.yml
  (pip-audit + Trivy IaC; image job gated on a Dockerfile existing), delete-merged-branch.yml.
- Adapt paths to `ai-osint-tool/`; Python 3.12 (README), not 3.11; CODEOWNERS = @voltron-1 only.
- Skip: detections.yml, soar-tests.yml, reporting-coverage.yml (stack-specific).
- Land on a feature branch; show the diff; open a PR on approval.

## Phase 5 — planned_execution.md  [x] done 2026-09-04 → d75ea01
- Generate at repo root from the M1–M6 milestones/issues (Suburban_SOC shape: NEXT UP, LAST
  SESSION, status markers, DEFERRED). Present for approval; commit only after approval.
