# {{Project name}} — Phases and atomic tasks

> Companion to [`SPEC.md`](SPEC.md). Execution protocol: [`SUPERVISOR.md`](SUPERVISOR.md).
>
> Every task is sized for **one sub-session, one branch, one pull request** (about 400 changed lines at most, not counting
> generated migrations and fixtures). A task is done when its **Accept** criteria hold and its **Verify** command passes
> in CI, not when the code is written.

## How to read a task

```
### T-PP.NN Title
- Executor: implementer | supervisor | owner     who does it (owner = a person; an agent cannot)
- Milestone: M0 | M1 | M2
- Depends: task ids that must be merged first, or —
- Read: SPEC sections and standards guides to load before editing
- Files: paths it may create or modify (anything else is out of scope)
- Do: the work, as numbered steps
- Accept: observable conditions, each one testable
- Verify: the command CI runs and the sub-session runs before opening the PR
```

`scripts/check-spec.sh` fails when a task block lacks one of these eight fields or when two tasks share an id.

Standards guides are named by skill from `architecture-standards` (for example `reference-architecture`, `repo-baseline`,
`service-api-patterns`, `testing-strategy`, `e2e-acceptance-testing`, `blazor-web-app`, `security-review`,
`init-generic-template`, `implementation-phase`). Every implementation task follows `implementation-phase`.

Common **Verify** for a .NET task unless the task says otherwise:
`dotnet build -warnaserror && dotnet test --filter "tier!=integration"`.

Rules for writing tasks:

- **Executor `owner`** marks what only a person can do (repository settings, accounts, hardware, a signature). These are
  collected early so they do not block a gate at the end.
- **Files are disjoint** between tasks that may run in parallel. Shared files (package versions, the solution, the CI
  workflow, the AppHost, shared contracts) belong to the supervisor.
- **A spike** produces a note under `docs/spikes/` with exact versions and a recommendation. If a spike is skipped, the task
  is not "done": it is replaced by a row in SPEC §12.1 (assumption, not verified).
- **Accept criteria name their proof**: a test name, a command with its expected output, or a CI job.

---

## Phase 0 — Ground truth before code

These four tasks are fixed. They exist because skipping them cost the most in the project this template came from.

### T-00.01 Owner decisions recorded
- Executor: owner · Milestone: M0 · Depends: —
- Read: `DECISIONS.md`
- Files: `docs/spec/DECISIONS.md`
- Do: 1) Answer every row. 2) Set `Status: decided`.
- Accept: no placeholder left in `docs/spec/DECISIONS.md`; status line reads `Status: decided`.
- Verify: `scripts/check-spec.sh`

### T-00.02 Repository settings
- Executor: owner · Milestone: M0 · Depends: T-00.01
- Read: DECISIONS D-09–D-13; `repo-baseline`
- Files: —
- Do: 1) Default branch as in D-12. 2) Automatically delete head branches as in D-12. 3) Repository variable `RUNNER_LABELS` if D-09 says self-hosted. 4) Branch protection as in D-13. 5) Secret scanning and code scanning on.
- Accept: each setting is visible in the repository settings; a manually dispatched workflow on the default branch starts.
- Verify: owner confirms in the PR that closes this task (settings are not readable by CI).

### T-00.03 Empty pipeline green
- Executor: supervisor · Milestone: M0 · Depends: T-00.02
- Read: SPEC §9; DECISIONS D-09–D-11; `self-hosted-runners` if applicable
- Files: `.github/workflows/**`, `scripts/**`
- Do: 1) Scaffold the solution with `init-generic-template` (AppHost, ServiceDefaults, one service, baseline). 2) Make every job of SPEC §9 exist and pass on the scaffold, before any feature code. 3) Record per job: duration, what it downloaded at run time, what it needed from the runner image.
- Accept: every pull-request job is green **three times in a row on one commit**; the recorded table is in `docs/operations/CI.md`; no job installs a toolchain at run time that DECISIONS D-10 says is in the runner image.
- Verify: links to the three runs in the PR description.

### T-00.04 First vertical slice against the real thing
- Executor: supervisor · Milestone: M0 · Depends: T-00.03
- Read: SPEC §7, §14; DECISIONS D-20
- Files: {{paths of the thinnest end-to-end path}}
- Do: 1) Build the thinnest path a user can walk from start to finish. 2) Run it once against the real dependency of DECISIONS D-20, not a stand-in. 3) Write down what the stand-in did not show.
- Accept: {{the first real result, observable}}; the note is in `docs/spikes/first-real-result.md`.
- Verify: {{command}}

---

## Phase 1 — {{name}}

### T-01.01 {{Title}}
- Executor: implementer · Milestone: M0 · Depends: T-00.04
- Read: SPEC §{{n}}; `{{skill}}`
- Files: `{{path}}`
- Do: 1) {{step}}
- Accept: {{observable condition with its proof}}
- Verify: {{command}}

---

## Waves

Which tasks may run at the same time (disjoint `Files:` sets). The supervisor never starts more sub-sessions than
DECISIONS D-16 allows, whatever this table permits.

| Wave | Tasks | Blocked by |
|---|---|---|
| 0 | T-00.01 → T-00.02 → T-00.03 → T-00.04 (in order, never parallel) | — |
| 1 | {{task ids}} | {{task ids}} |
