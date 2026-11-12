# job-radar-spec

The specification of **JobRadar**: a local-first database of IT job offers, fed once a day by a GitHub Actions workflow in which
Playwright collects offers from ATS APIs, portals and feeds, plain code normalises, de-duplicates and link-checks them, and
GitHub Copilot SDK agents extract fields, score fit against written criteria and write a short summary. The result is a SQLite
file, a Markdown report and one GitHub issue per day.

This repository holds **no application code**. It holds what a director session and its Claude Haiku 5.5 implementers need to
build it in the private repository `job-radar`, following
[`architecture-standards`](https://github.com/konradcinkusz/architecture-standards) (.NET, Aspire AppHost, P1–P15). It was made
from the spec-driven template of that estate, from the owner's analysis of 12 November 2026, and from
[`llm-multi-agent-chess`](https://github.com/konradcinkusz/llm-multi-agent-chess) as the worked example of the Copilot SDK.

## Read in this order

| File | What it is |
|---|---|
| [`docs/spec/DECISIONS.md`](docs/spec/DECISIONS.md) | 31 owner decisions. Rows marked PROPOSED are the author's defaults; the owner confirms them first |
| [`docs/spec/SPEC.md`](docs/spec/SPEC.md) | The system: goals, topology, data model, lifecycle, agents, rules, workflows, tests, security, assumptions, gates |
| [`docs/spec/SOURCES.md`](docs/spec/SOURCES.md) | Every source, its access method, its status (confirmed or indirect) and the acceptance every adapter meets |
| [`docs/spec/COPILOT-SDK.md`](docs/spec/COPILOT-SDK.md) | How the Copilot SDK is used here, what comes from the chess arena, what comes only from the package documentation, and the questions the first spike answers |
| [`docs/spec/TASKS.md`](docs/spec/TASKS.md) | 70 tasks in 6 phases, each one pull request, sized for a small model, with the waves that may run together |
| [`docs/spec/SUPERVISOR.md`](docs/spec/SUPERVISOR.md) | The director's protocol, including how to work with Haiku 5.5 implementers (§10) |
| [`docs/spec/DIRECTOR-PROMPT.md`](docs/spec/DIRECTOR-PROMPT.md) | The first message for the director session |
| [`docs/spec/PROGRESS.md`](docs/spec/PROGRESS.md) | Measured state: every task and gate, what is not shown yet, owner actions outstanding |
| [`docs/adr/`](docs/adr/) | Six ADRs: the deviations from the standards and the decisions that shape the agents |
| [`docs/spec/LESSONS.md`](docs/spec/LESSONS.md) | Why the process is shaped as it is |

## What the specification changes from the analysis

The analysis is followed; these points differ, each with its reason in the specification.

| Analysis | Specification | Where |
|---|---|---|
| Language open (Python or .NET) | .NET 10, because the standards and the SDK example are .NET | ADR-0001 |
| Cost in premium requests | Cost in AI credits with a per-run budget; Copilot has billed per token since June 2026 | ADR-0006, SPEC R14 |
| "Agents have an explicit tool list" | `CopilotClientMode.Empty`, one tool per agent, nonce-delimited offer text, closed schemas | ADR-0003, SPEC §6.5 |
| The Scorer applies hard exclusions | Code applies them after the model, so injected text cannot lift them | ADR-0005 |
| Offers missing three runs expire | Only on runs where the source was healthy, and only for sources whose listing is complete | SPEC §6.4, R8 |
| Tracks A, B, C | Two are defined by the analysis; C is disabled until the owner defines it | DECISIONS D-27 |
| One PR or direct commit for data | Direct commit by code to an orphan `data` branch; feedback in a separate append-only file so two writers never touch one binary | ADR-0004, SPEC R13 |
| Reporter agent writes the report | Code composes the report; the Reporter writes only a short summary, optional | SPEC §6.8 |

## What has not been verified

Nothing here has been run. No source endpoint has been called (the author's sandbox could not reach them), and no Copilot SDK
code has been executed. The first phase exists to change that: tasks T-00.03 and T-00.04 produce the real Greenhouse response
and the real Copilot session, and the specification is amended where they differ. The list is in
[`PROGRESS.md`](docs/spec/PROGRESS.md) under "Not shown yet" and in SPEC §12.1.

## Starting the build

1. Open `docs/spec/DECISIONS.md` and read the PROPOSED rows.
2. Start a new Claude Code session attached to this repository and to `architecture-standards`.
3. Paste the prompt in [`docs/spec/DIRECTOR-PROMPT.md`](docs/spec/DIRECTOR-PROMPT.md).
4. The director asks you the PROPOSED rows in one message, then raises the owner tasks of Phase 0: the private repository
   `job-radar`, its settings, and the fine-grained token with the Copilot Requests permission.

## Checks

```bash
scripts/check-spec.sh
```

```bash
scripts/check-open-markers.sh
```

`check-spec.sh` verifies that the five specification files exist, that every task has its eight fields and a unique id, that a
`merged` or `open-green` row of `PROGRESS.md` has an evidence link, and that, once `DECISIONS.md` says `Status: decided`, no
placeholder is left. It cannot tell whether a claim is true, only that a claim has a link and a date.

## Runners

The `spec-check` workflow runs on GitHub-hosted runners by default; set the repository variable `RUNNER_LABELS` to a JSON array to
change that (DECISIONS D-09).
