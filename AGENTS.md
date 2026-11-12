# AGENTS.md

JobRadar specification: a daily pipeline of GitHub Actions, Playwright and GitHub Copilot SDK agents that collects, de-duplicates and
checks IT job offers and reports the ones that match written criteria (DECISIONS D-02). This repository holds the specification
only. The code is built in the private repository `konradcinkusz/job-radar`.

- Specification: [`docs/spec/SPEC.md`](docs/spec/SPEC.md), with [`SOURCES.md`](docs/spec/SOURCES.md) and [`COPILOT-SDK.md`](docs/spec/COPILOT-SDK.md). Tasks: [`docs/spec/TASKS.md`](docs/spec/TASKS.md). Protocol: [`docs/spec/SUPERVISOR.md`](docs/spec/SUPERVISOR.md) (the supervisor is called the director here). Owner decisions: [`docs/spec/DECISIONS.md`](docs/spec/DECISIONS.md). Measured progress: [`docs/spec/PROGRESS.md`](docs/spec/PROGRESS.md). Decisions and deviations: [`docs/adr/`](docs/adr/).
- Starting a build: paste [`docs/spec/DIRECTOR-PROMPT.md`](docs/spec/DIRECTOR-PROMPT.md) into a new session.
- Standards: [`konradcinkusz/architecture-standards`](https://github.com/konradcinkusz/architecture-standards) (P1–P15). Declared in `.claude/settings.json`. Read the skills; do not reconstruct the rules from code.
- Do not start implementation while `docs/spec/DECISIONS.md` says `Status: open`: ask the owner the open rows first.
- Fixtures are recorded public responses cut to at most 5 postings, kept only while `job-radar` is private (D-04). No secrets in any file.
- Report what was measured as measured and what was concluded as a conclusion. Nothing in this specification has been run: see `PROGRESS.md` "Not shown yet".
- English for code, comments and docs. Report labels in the product are Polish (D-28).
- Verify this repository: `scripts/check-spec.sh && scripts/check-open-markers.sh`. In `job-radar`: `dotnet build JobRadar.sln -warnaserror && dotnet test JobRadar.sln --filter "tier!=live&tier!=browser"`.
