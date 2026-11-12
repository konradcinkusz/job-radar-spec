# ADR-0002: GitHub Actions is the runtime; nothing is deployed

- Status: accepted
- Date: 2026-11-12

## Context
JobRadar is a batch job that runs once a day, writes a SQLite file and a report, and has no user interface and no long-running
process. The standards describe services deployed as containers on Fly.io (P6, P7) by a tag-driven pipeline (P12), with
`/health` endpoints (P8) and a resilience handler on every `HttpClient` (P2).

## Decision
There is no container, no Fly.io app and no tag-driven deploy. The runtime is `daily.yml` on GitHub Actions (`schedule` and
`workflow_dispatch`). CI is a pull-request workflow. State lives on the orphan branch `data` and in workflow artifacts. The
AppHost exists for development only (P1).

Two consequences are recorded as part of this decision:
- The health endpoint is replaced by `jobradar doctor`, which prints the state of every optional integration (P8's visible
  degradation).
- Source requests go through Playwright's `IAPIRequestContext`, not `HttpClient`, so P2's standard resilience handler does not
  apply to them. `SourceHttp` implements the same policy (timeouts, retry with back-off, per-host delay) and is tested.

## Consequences
- No hosting cost and no secrets for a platform; the only runtime secrets are the Copilot token and two source keys.
- No always-on process to monitor; failure shows as a failed workflow run and a source-health issue.
- If a service is ever wanted (a query API, a UI), this ADR is superseded by a new one.

## Alternatives considered
- A container on Fly.io with an internal scheduler: costs money and moves secrets to a platform for a once-a-day job. Rejected.
- Azure Container Apps jobs: same objection. Rejected.
