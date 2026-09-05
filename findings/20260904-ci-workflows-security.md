# CI Workflow Security Audit — 2026-09-04

Source: security-auditor sub-agent, run against branch `ci/github-actions-port` (uncommitted). Persisted by the main session; the agent is read-only.

**Totals:** 0 CRITICAL · 4 HIGH · 14 MEDIUM · 10 LOW · 5 INFO. Script injection and `pull_request_target` misuse explicitly verified absent.

## Scope checked
`.github/workflows/{codeql,lint,secret-scan,security-scan,delete-merged-branch}.yml`, `.github/CODEOWNERS`, `.gitleaks.toml`, `.yamllint`, `.python-version`; context: `ai-osint-tool/docker-compose.yml`, `.env.example`, `.gitignore`, `connectors/base.py`. Not run: gitleaks, Trivy (regex behaviour derived by reading). Suburban_SOC originals not available to the agent; SHA pins not resolvable offline (verified separately by the main session, see Disposition).

## Findings

| Sev | File:line | Finding | Recommendation |
|---|---|---|---|
| HIGH | repo settings; security-scan.yml:9-19 | No branch protection on `main`; security-scan has no `push` trigger and a narrow `paths:` filter, so all gates are advisory and a direct push is unscanned until the Monday cron. A path-filtered workflow can never satisfy a required check on PRs that skip the filter. | Add a ruleset on `main` (PR + required checks + code-owner review, block force-push). Add `push: branches: [main]`; drop the `paths:` filter (lint.yml's own #168 rationale). |
| HIGH | lint.yml:24-27 | shellcheck installed from the mutable `stable` release tag via curl-pipe-tar, no checksum, `sudo mv` into PATH. | Pin to an immutable release, download to a file, verify `sha256sum -c`, `set -euo pipefail`, `curl --fail`. |
| HIGH | security-scan.yml:72; lint.yml:59-63 | Fork PRs can execute code: `docker build` runs attacker-controlled Dockerfile `RUN` steps; mypy auto-discovers `pyproject.toml`/`mypy.ini` `plugins=` from cwd. Capped by `pull_request` (read-only token, no secrets). | Repo setting "Require approval for all external contributors"; explicit trusted mypy config; `timeout-minutes` on all jobs. |
| HIGH | .gitleaks.toml:15-16 | Custom rule only matches the `POSTGRES_PASSWORD=` identifier form; a DSN `postgresql://<user>:<pass>@<host>` (what the app will construct) is invisible to it and unreliably caught by defaults. Public repo. | Add a `postgres-dsn-credential` rule (`postgres(?:ql)?://[^:\s]+:[^@\s/'"]{4,}@`) with `change_me`/`$` allowlists; consider `PGPASSWORD`, `DATABASE_URL`. Test with fixtures. |
| MED | .gitleaks.toml:15 | Leading-character class excludes `$ { } [ ] ~ ? / \ < > , ; : \| ' "` and space, so any password starting with one of them is missed. | Match `\S{6,}` and move the `$`-prefixed variable forms into the rule allowlist instead. |
| MED | .gitleaks.toml:22 | `change_me` allowlist is an unanchored prefix: `change_me_<suffix>` is exempted. | Anchor the terminator; scope to `.env.example` if possible. |
| MED | .gitleaks.toml:28-30 | Global path allowlist `\.gitleaks\.toml` is an unanchored substring match applying to every rule: `docs/.gitleaks.toml.md` becomes a blind spot. | `^\.gitleaks\.toml$`. |
| MED | security-scan.yml:34,52,63 | Two silent-pass paths: only `requirements*.txt` audited (pyproject/lock files ignored though pyproject is a trigger); Dockerfile check hardcoded to `app/` while trigger is `**/Dockerfile`. Both exit 0 with a notice. | Fail closed or `::warning::` once past step 0.6; broaden discovery. |
| MED | security-scan.yml:79-81 vs 99-100 | Image scan `CRITICAL` + `ignore-unfixed`; IaC scan `CRITICAL,HIGH`. Fixed HIGH CVEs in the image merge silently. | Align to `CRITICAL,HIGH` or document the exception. |
| MED | security-scan.yml (absent) | No SARIF upload; Trivy/pip-audit findings live only in job logs. | Add `format: sarif` + `upload-sarif` with job-level `security-events: write`. |
| MED | .github/ (absent dependabot.yml) | SHA pins with no update channel become permanently frozen actions; same for `ruff==0.15.15`. | Add `dependabot.yml` for `github-actions` and `pip`, weekly. |
| MED | lint.yml:59,75; security-scan.yml:48 | mypy, yamllint, pip-audit installed unpinned. | Pin with `==`; let Dependabot bump. |
| MED | lint.yml (absent) | No workflow linter in CI; nothing enforces pinned `uses:`/no-injection properties going forward. | Add actionlint (and/or zizmor) job. |
| MED | CODEOWNERS:5-8 | Root `.gitleaks.toml`, `.yamllint`, `.python-version`, `.env.example` unowned; no `*` catch-all. Single-maintainer cannot give separation of duties (accepted risk). | Add `* @voltron-1` first, then specific paths incl. root configs. |
| MED | all workflows | No `timeout-minutes` (360 default) and no `concurrency`; public repo → compute abuse via fork PRs. | `timeout-minutes` on every job; `concurrency` with `cancel-in-progress` (not on delete-merged-branch). |
| MED | repo root (absent .gitignore) | Only `ai-osint-tool/.gitignore` exists; a root-level `.env` is stageable. | Root `.gitignore` with `.env`, `.env.*`, `!.env.example`, caches; consider `gitleaks protect --staged` pre-commit. |
| MED | all `uses:` lines | SHA pins unverified against claimed tags (agent offline). | Verify each SHA is reachable from its tag. |
| MED | secret-scan.yml:24-27 | Third-party action receives `GITHUB_TOKEN` and downloads gitleaks at run time (pin covers the action, not the binary). Mitigated by `contents: read`. | Keep token scoped; optionally run a digest-pinned gitleaks container instead. |
| MED | security-scan.yml:11-16 | `paths:` filter semantically mismatched with the jobs (depth-specific pyproject, no lock files); GitHub glob vs git pathspec semantics differ. | Drop the filter or broaden to `ai-osint-tool/**`. |
| LOW | delete-merged-branch.yml:24 | Hardcoded protected list ignores `repository.default_branch`; currently the only guard against deleting `main`. | Check `context.payload.repository.default_branch`. |
| LOW | delete-merged-branch.yml:45-46 | Comment wrong: GitHub does not refuse deleting a ref with other open PRs (it closes them); protection returns 403 not 422. | Fix comment; optionally skip when another open PR shares the head. |
| LOW | delete-merged-branch.yml:10-11; codeql.yml | Workflow-level `contents: write`; codeql has no top-level `permissions:`. Future jobs inherit. | `permissions: {}` at workflow level, grant per job. |
| LOW | codeql.yml:19 | `packages: read` unused with `build-mode: none`. | Remove. |
| LOW | secret-scan.yml:7-8 | Unfiltered `push:` → double runs on PR branches, full-history scan on every tag push. | `push: branches: [main]`. |
| LOW | lint.yml:32,62-63; security-scan.yml:52 | `git ls-files \| xargs` without `-z/-0`; `*.sh` misses extensionless/`.bash` scripts. Fail-closed. | `git ls-files -z … \| xargs -0 -r`; broaden patterns. |
| LOW | lint.yml:92,95 | `-q` on `docker compose config` is load-bearing: without it the resolved `POSTGRES_PASSWORD` prints to a public log. | Keep `-q`; add a comment saying so. |
| LOW | .gitleaks.toml:19-24 | `[rules.allowlist]` has no `regexTarget`; works by accident because the rule has no capture group. | `regexTarget = "match"` explicitly. |
| LOW | .gitleaks.toml:23 | `<[A-Za-z]` allowlist entry unreachable with the current character class. | Remove or make the rule permissive so it becomes load-bearing. |
| LOW | repo root (absent) | No `SECURITY.md`, `dependency-review-action`, OpenSSF Scorecard, `harden-runner`. | Add `SECURITY.md` first; others as follow-ups. |
| LOW | .yamllint; lint.yml:77 | yamllint scoped to two paths; future root YAML unlinted. `truthy: check-keys: false` is correct. | `yamllint -c .yamllint .` with an `ignore:` block. |
| INFO | all workflows | Verified clean: no `${{ }}` inside any `run:`; only matrix/secrets/steps contexts in safe positions. | Preserve via actionlint. |
| INFO | delete-merged-branch.yml:21-35 | Verified clean: no `pull_request_target`; untrusted data read via `context.payload`, fork check uses optional chaining. | Document as the required pattern. |
| INFO | all workflows | Verified: only `secrets.GITHUB_TOKEN` referenced; `contents: read` at workflow level in lint/secret-scan/security-scan. | — |
| INFO | secret-scan.yml:25 | gitleaks-action needs `GITLEAKS_LICENSE` only for org-owned repos; user-owned today. | Add a comment noting the org-transfer dependency. |
| INFO | scope | Gap-vs-original could not be diffed by the agent; the `paths:` filter on security-scan contradicts lint.yml's cited #168 rationale. | Main session holds the originals: the filter, unpinned installs, and absent timeouts are faithful to Suburban_SOC, not port regressions. |

## Disposition (main session, 2026-09-04)
See `logs/session-20260904.md` Phase 4 for what was applied before the PR. Repo-settings items (branch protection, external-contributor approval) and out-of-scope additions (SARIF upload, SECURITY.md, scorecard, harden-runner) are left for the owner / backlog.
