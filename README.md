# spec-driven-template

A GitHub template repository for starting a new product from a specification, built with
[`architecture-standards`](https://github.com/konradcinkusz/architecture-standards) (.NET, Aspire AppHost, P1–P15) and
delivered by a supervisor session that delegates single tasks to sub-sessions.

It holds no application code. It holds the documents you fill in before the code, the protocol the agents follow, and two
checks that keep the documents consistent.

## What is in it

| File | What you do with it |
|---|---|
| [`docs/spec/DECISIONS.md`](docs/spec/DECISIONS.md) | Answer 20 questions first: product, platforms, CI, delegation, evidence. Nothing starts while it says `Status: open` |
| [`docs/spec/SPEC.md`](docs/spec/SPEC.md) | Describe the system: goals, topology, services, rules, gates. Standards are referenced, not repeated |
| [`docs/spec/TASKS.md`](docs/spec/TASKS.md) | Break the work into tasks of one pull request each. Phase 0 is fixed |
| [`docs/spec/SUPERVISOR.md`](docs/spec/SUPERVISOR.md) | The delegation protocol. Usually left as it is |
| [`docs/spec/PROGRESS.md`](docs/spec/PROGRESS.md) | Measured state. Every "merged" has a link, every gate has its proof |
| [`docs/spec/OPEN-MARKERS.md`](docs/spec/OPEN-MARKERS.md) | Generated table of every `TODO`, `CHANGEME`, `TO MEASURE`, `TO-VERIFY` in the repository |
| [`docs/spec/LESSONS.md`](docs/spec/LESSONS.md) | Why each part exists, from the project this template was extracted from |
| [`docs/adr/0000-template.md`](docs/adr/0000-template.md) | Template for decisions and for deviations from the standards |
| [`AGENTS.md`](AGENTS.md), [`.claude/settings.json`](.claude/settings.json) | Agent entry point and the standards plugins |
| [`.github/pull_request_template.md`](.github/pull_request_template.md) | "Criterion, and how it is proven" |
| [`scripts/check-spec.sh`](scripts/check-spec.sh), [`scripts/check-open-markers.sh`](scripts/check-open-markers.sh) | The two checks, run by the `spec-check` workflow |

## From an idea to the first task

1. **Create the repository**: "Use this template" on GitHub.
2. **Decide**: fill `docs/spec/DECISIONS.md`. Set `Status: decided`. From now on CI fails on any placeholder left in the
   specification.
3. **Specify**: fill `docs/spec/SPEC.md`. A section is answered or marked `n/a` with a reason.
4. **Plan**: add your phases to `docs/spec/TASKS.md` after Phase 0. Keep each task to one pull request.
5. **Fill** the two placeholders in `AGENTS.md` and replace this README with one for your product.
6. **Check**:
   ```bash
   scripts/check-spec.sh
   ```
   ```bash
   scripts/check-open-markers.sh
   ```
7. **Start**: open a supervisor session on the repository and give it `docs/spec/SUPERVISOR.md`. It begins with Phase 0:
   owner decisions, repository settings, an empty pipeline that is green three times, and one thin slice run against the
   real dependency. Feature work starts after that.

## What the checks enforce

`scripts/check-spec.sh`:

- the five specification files exist;
- every task has `Executor`, `Milestone`, `Depends`, `Read`, `Files`, `Do`, `Accept`, `Verify`, and a unique id;
- a `PROGRESS.md` row with status `merged` or `open-green` has an evidence link, and a claimed gate has a proof link;
- once `DECISIONS.md` says `Status: decided`, no placeholder (text in double curly braces) is left.

`scripts/check-open-markers.sh`:

- every open marker in `deploy`, `docs` (outside `docs/spec`), `src`, `tools`, `tests`, `evals` and `scripts` has a row in
  `OPEN-MARKERS.md`, and every row still matches a marker. Regenerate with `--write`.

The checks cannot tell whether a claim is true. They make sure a claim has a link and a date, so that a person can.

## Runners

The workflow runs on GitHub-hosted runners by default. To use self-hosted runners set the repository variable
`RUNNER_LABELS` to a JSON array, for example `["self-hosted","linux"]`, and record what the runner image contains in
`DECISIONS.md` (D-10, D-11).

## Scope

This template is for the stack of `architecture-standards`. It does not scaffold code: Phase 0 task `T-00.03` does that
with the `init-generic-template` skill. Projects created from the template do not receive later changes to it; rules that
must stay current belong in the standards repository.
