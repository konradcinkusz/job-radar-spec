# {{Project name}} — System specification

> Normative description of what is built. Tasks are in [`TASKS.md`](TASKS.md), the execution protocol in
> [`SUPERVISOR.md`](SUPERVISOR.md), measured state in [`PROGRESS.md`](PROGRESS.md), owner decisions in [`DECISIONS.md`](DECISIONS.md).
>
> Rules for writing this file:
> - Every section answers its questions or says `n/a` with a reason. An empty heading is not an answer.
> - Architecture rules are **not** restated here. They live in
>   [`architecture-standards`](https://github.com/konradcinkusz/architecture-standards) (P1–P15); this file says only what is
>   specific to this system and where it deviates.
> - A statement an agent could not check ("fast", "secure", "simple") is replaced by a number or an observable condition.
> - Anything assumed and not verified is written as an assumption and listed in §12.

## 0. Glossary

| Term | Meaning in this system |
|---|---|
| {{term}} | {{meaning}} |

## 1. Goals and non-goals

### 1.1 Goals
{{Numbered list. Each goal is observable: a user can do X and sees Y.}}

### 1.2 Non-goals
{{Copied from DECISIONS D-03 and extended. A task that serves a non-goal is rejected.}}

## 2. System context

{{Who and what talks to the system: users and their roles, external systems, data that enters and leaves. One diagram or one table.}}

## 3. Repository

### 3.1 Name and derived names
| Thing | Name |
|---|---|
| Repository | {{repo}} |
| Solution | {{Solution}}.sln |
| AppHost / ServiceDefaults | {{Solution}}.AppHost / {{Solution}}.ServiceDefaults |
| Image prefix | {{prefix}} |

### 3.2 Tree
{{The intended top-level tree: src/, tests/, tools/, deploy/, docs/, scripts/. One line per project with its role.}}

## 4. Runtime topology

### 4.1 Development (P1: Aspire AppHost is the composition root)
{{Resources the AppHost starts, in a table: name, kind (project/container), depends on, health endpoint.
State the default profile that needs no credentials, no paid service and no special hardware.}}

### 4.2 Without Aspire
{{The `docker compose` file that starts the same system, if DECISIONS D-06 asks for it. State which of 4.1 / 4.2 is the gate.}}

### 4.3 Deployed
{{Target from DECISIONS D-07: apps or containers, their sizes, what scales to zero, what holds state.}}

## 5. Cross-cutting rules (apply to every task)

{{Numbered rules every task must keep, specific to this system. Examples of the kind of rule that belongs here:
language of code and of user-facing text; what may never reach a log; who owns which database (P3); how long an outbound call
may take and whether it may be retried; what an optional dependency does when it is down (P8).}}

> Timeouts are a rule, not a detail. For every call between two services write the longest time the callee may take
> under load and whether the caller may retry it. A write that is not idempotent is never retried.

## 6. Services

One subsection per service or library. Copy this block.

### 6.N {{Service name}} (`{{Project}}`, owns `{{database}}` or stateless)

- **Responsibilities:** {{what it owns; what it must not do}}
- **Data model:** {{tables/aggregates, or n/a}}
- **API:** {{method, path, auth, request, response, errors — a table}}
- **Calls out to:** {{service, operation, time budget, retry yes/no}}
- **Degrades how:** {{behaviour when each dependency is down}}
- **Extension points (P10):** {{interfaces others implement, or none}}

## 7. Test doubles and profiles

{{Every stub, fake or scripted stand-in (for a model, a payment provider, a device): what it replaces, in which profile it runs,
and which claims it can and cannot support. A result obtained against a stand-in is reported as such.}}

## 8. Observability and privacy

{{What is logged, traced and measured; what is redacted; where it goes. Metric labels and their cardinality.}}

## 9. CI/CD

{{Jobs of the pull-request workflow, in a table: job, what it proves, expected duration, what it needs on the runner.
Keep the count low: each job pays a start-up cost, and every job that starts containers uses shared resources of the Docker host.
Copy the runner facts from DECISIONS D-09–D-11.}}

## 10. Testing

{{Layers and their time budgets (testing-strategy). Which behaviours get an end-to-end test (the charter). Waits in tests are
waits on a condition with a generous limit, never a short fixed timeout.}}

## 11. Security

{{Authentication and authorisation model, secrets handling, the threat that matters most for this system.}}

## 12. Assumptions and deviations

### 12.1 Assumptions (not verified)
| # | Assumption | How and when it will be verified | Task |
|---|---|---|---|
| A-01 | {{assumption}} | {{check}} | {{T-..}} |

### 12.2 Deviations from the standards
Each needs an ADR in `docs/adr/` before the code that deviates is merged.

| Principle | Deviation | ADR |
|---|---|---|
| {{P..}} | {{what and why}} | {{ADR-....}} |

## 13. Performance targets

| Target | Number | Measured where | Task |
|---|---|---|---|
| {{e.g. p95 of X}} | {{value}} | {{environment}} | {{T-..}} |

## 14. Release plan

| Gate | Passes when (observable, on the platforms of DECISIONS D-05) | Proof (DECISIONS D-19) |
|---|---|---|
| **M0** | {{the whole system starts in the default profile with zero credentials; all CI jobs green on one commit}} | {{CI run link on a named commit}} |
| **M1** | {{the first real result of DECISIONS D-20}} | {{proof}} |
| **M2** | {{...}} | {{...}} |

A gate is claimed in `PROGRESS.md` only with its proof. A date depends on what it depends on: write
"arrival of X + N weeks", not a calendar date, when X is not in your hands.
