# AGENTS.md

{{Project name}} — {{one sentence from DECISIONS D-02}}.

- Specification: [`docs/spec/SPEC.md`](docs/spec/SPEC.md). Tasks: [`docs/spec/TASKS.md`](docs/spec/TASKS.md). Protocol: [`docs/spec/SUPERVISOR.md`](docs/spec/SUPERVISOR.md). Owner decisions: [`docs/spec/DECISIONS.md`](docs/spec/DECISIONS.md). Measured progress: [`docs/spec/PROGRESS.md`](docs/spec/PROGRESS.md).
- Standards: [`konradcinkusz/architecture-standards`](https://github.com/konradcinkusz/architecture-standards) (P1–P15). Declared in `.claude/settings.json`.
- Do not start implementation while `docs/spec/DECISIONS.md` says `Status: open`: ask the owner the open rows first.
- Fixtures are synthetic. No secrets in any file.
- Report what was measured as measured and what was concluded as a conclusion.
- English for code, comments and docs.
- Verify: `scripts/check-spec.sh && scripts/check-open-markers.sh`; once code exists also `dotnet build -warnaserror && dotnet test --filter "tier!=integration"`.
