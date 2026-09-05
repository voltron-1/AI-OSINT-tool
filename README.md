# AI OSINT Tool

A self-hosted, open-source OSINT collector for external attack-surface monitoring and
brand-impersonation detection. Collection is deterministic; a local LLM is used only
for triage, scoring, and report drafting.

## Authorized use only

This tool is for **authorized security research and monitoring only** — assessing a
domain or organization you own, or have explicit, documented authorization to assess.

- Do not run this tool against any domain, network, or individual without prior
  written authorization from the owner.
- The authorized-targets registry and domain control validation (DCV) exist to
  enforce this. Do not attempt to bypass, disable, or work around them.
- This project targets organizational domains and infrastructure. It is not designed,
  intended, or authorized for use against private individuals.
- You are solely responsible for ensuring your use complies with applicable law
  (e.g. the Computer Fraud and Abuse Act in the US, and equivalent laws elsewhere)
  and the terms of service of any data source or scanned target.
- The maintainers assume no liability for misuse.

If you're not sure you're authorized to scan a target, you aren't. Don't run it.

## What it does

- **Lane 1 — Attack Surface / EASM**: subdomains, DNS, certificates, open ports,
  exposed services, misconfigurations, leaked secrets, email spoofability.
- **Lane 2 — Impersonation / Phishing Domains**: typosquat detection, lookalike
  certificate monitoring, known-phishing cross-referencing.
- **Autonomous Investigation Mode**: after baseline collection, a bounded loop
  reviews findings and pursues leads within the target's own data — read-only,
  scope-checked against the target's entity graph, capped per run.

## Design principles

- Deterministic collection, bounded AI — the model never drives collection, only
  triages what's already been gathered.
- Authorized-targets only — a target must pass domain control validation (DCV)
  before any connector or the autonomous loop will touch it.
- Provenance on every finding — source, timestamp, and method.
- Normalized to STIX 2.1 — portable to MISP, OpenCTI, or a SIEM.
- Human-in-the-loop — the system ranks and proposes; a person dispositions.

## Stack

- Docker Compose, single node, three services: PostgreSQL + Apache AGE, Ollama, app
- Python 3.12 / FastAPI
- All open-source, $0 licensing

See `docs/` for the full architecture and build plan.

## Status

Early scaffold. Phase 0 (registry, connector contract, DCV) not yet implemented.

## License

MIT — see LICENSE.
