# ADR-0004: SQLite file on an orphan `data` branch; migrations at command start

- Status: accepted
- Date: 2026-11-12

## Context
The analysis proposes one SQLite file (tens of thousands of offers, FTS5) kept in Git, in a separate data repository or on a
`data` branch. The standards ask for provider-portable persistence with migrations applied by a hosted service (P4) and a
database per service (P3).

## Decision
- One SQLite database, owned by `JobRadar.Store`, stored as `data/jobradar.db` on the orphan branch `data` of the private
  repository `job-radar`. Only the `publish` job commits it; the `feedback` workflow writes a separate append-only file.
- EF Core migrations remain the only way the schema changes. `jobradar migrate` applies them and every command runs it first,
  because a CLI is not a long-running host (this deviates from "hosted service after Kestrel starts").
- Tests use a real SQLite file, never the InMemory provider.
- Size guard: warn at 40 MB, stop committing at 90 MB (GitHub refuses a file over 100 MB). Archived offers lose their
  description; a weekly `VACUUM` runs on Sundays.

## Consequences
- No database server and no cost; history of the file grows with each commit, so the guard and the archive rule matter.
- A direct commit by code means no pull request for data. The offers are public data, the repository is private, and the branch
  refuses force pushes.
- If the file outgrows Git, the alternatives are Git LFS, a workflow artifact, or external storage; this ADR is then replaced.

## Alternatives considered
- A separate `jobradar-data` repository: needs a token with write access to a second repository. Not needed while the application
  repository is private. Revisit if the application repository is ever made public.
- Data on `main`: mixes a binary that changes daily with code history. Rejected.
