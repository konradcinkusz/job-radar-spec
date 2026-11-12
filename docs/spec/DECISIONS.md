# Owner decisions

Status: open

> Fill this file **before** any implementation task starts. Change `Status: open` to `Status: decided` when every row has an
> answer; from then on CI (`scripts/check-spec.sh`) fails on any unfilled placeholder (text in double curly braces) left in `docs/spec/`.
>
> Why this file exists: in the project this template was extracted from, none of these were asked up front. Each one surfaced
> later as a blocked milestone, a red pipeline or a rewritten plan (see [`LESSONS.md`](LESSONS.md)).
> An agent must not guess an answer here. "Not decided yet" is a valid answer only with a date by which it will be.

## 1. Product

| # | Decision | Answer |
|---|---|---|
| D-01 | Repository name and the names derived from it (solution, namespaces, images) | {{repo name}} |
| D-02 | One sentence: who uses it and what they get | {{one sentence}} |
| D-03 | What is explicitly **not** built (scope creep is rejected against this list) | {{non-goals}} |
| D-04 | Data sensitivity: may real user data ever be in a test, a log or a fixture? | {{yes / no; if no, say what fixtures are}} |

## 2. Platforms and gates

| # | Decision | Answer |
|---|---|---|
| D-05 | Platforms a milestone gate must be shown on (Linux, Windows, macOS, WSL). List only those you will actually run | {{platforms}} |
| D-06 | How the system is started for the first gate: Aspire AppHost, `docker compose`, or both. If both, which one is the gate | {{start command}} |
| D-07 | Deployment target (Fly.io, Azure, on-prem compose, none yet) | {{target}} |
| D-08 | Anything that needs hardware or an account you do not have yet, and when it arrives | {{dependency and date, or none}} |

## 3. CI

| # | Decision | Answer |
|---|---|---|
| D-09 | Runners: GitHub-hosted, or self-hosted (then set the repository variable `RUNNER_LABELS`) | {{runners}} |
| D-10 | If self-hosted: what is already installed in the runner image (.NET SDK version, Docker, Node, TeX, ...) | {{installed tools, or n/a}} |
| D-11 | If self-hosted: how many jobs may run at once, and is the Docker daemon shared between runners | {{concurrency, shared daemon yes/no, or n/a}} |
| D-12 | Default branch, and whether merged branches are deleted automatically | {{branch; auto-delete yes/no}} |
| D-13 | Required checks / branch protection | {{checks, or none}} |

## 4. Delegation

| # | Decision | Answer |
|---|---|---|
| D-14 | Model for the supervisor session and for implementer sub-sessions | {{supervisor model}} / {{implementer model}} |
| D-15 | How sub-sessions are started (separate sessions visible to the owner, or in-process agents) | {{mechanism}} |
| D-16 | Maximum sub-sessions at once (start with 2 on self-hosted runners; raise only when CI stays stable) | {{number}} |
| D-17 | Autonomy: may the supervisor merge green PRs without asking? May it archive finished sessions? | {{merge yes/no}} / {{archive yes/no}} |
| D-18 | What the supervisor must always ask about (spend, deleting things, anything outside the repository) | {{list}} |

## 5. Evidence

| # | Decision | Answer |
|---|---|---|
| D-19 | What counts as proof that a gate passed (CI run link on a named commit, a recording, a measured number) | {{proof}} |
| D-20 | First real-world result required before any feature beyond the first vertical slice (e.g. one real model answer, one real customer file, one deploy) | {{first real result}} |

## Decision log

Decisions taken after the start go here, newest first, with the date and the reason. A decision that changes the specification
lands in the same pull request as the change to `SPEC.md`.

| Date | Decision | Reason |
|---|---|---|
