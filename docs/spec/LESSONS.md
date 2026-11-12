# Lessons this template encodes

Source: the build of `konradcinkusz/inference-polska-core` (8–10 November 2026), one supervisor session delegating to
sub-sessions from three input files (`SPEC.md`, `TASKS.md`, `SUPERVISOR.md`). Read from that session's transcript and
repository. Each row says what happened and which part of this template exists because of it.

Delete this file in a project created from the template, or keep it as background; nothing reads it.

## What worked

| Observation | Kept as |
|---|---|
| Three files were enough to start a full implementation: specification, atomic tasks, delegation protocol | `SPEC.md`, `TASKS.md`, `SUPERVISOR.md` |
| Tasks with `Files`, `Accept` and `Verify` let eight sub-sessions write most of the code within the first day | The eight-field task block, checked by `scripts/check-spec.sh` |
| A pull-request template that asks "criterion, and how it is proven" produced command output instead of claims | `.github/pull_request_template.md` |
| A generated table of every placeholder (`CHANGEME`, `TO-VERIFY`, ...) made hidden gaps countable | `OPEN-MARKERS.md` and `scripts/check-open-markers.sh` |
| Architecture rules lived in one external standard, not in the specification | `SPEC.md` refers to P1–P15 and lists only deviations |

## What cost time

| What happened | Consequence | Encoded as |
|---|---|---|
| The owner said "ask nothing" in the second message; no decision was collected up front. Platforms for the first gate, the default branch, the runners and the sub-session model were all settled later, each after something blocked | A gate that required Windows nobody would run; a workflow that could not be dispatched; rework of the CI configuration | `DECISIONS.md` filled before task one; SUPERVISOR §2 |
| The code was written in about a day; the following two days went almost entirely to the pipeline | Most effort was verification, not implementation | `T-00.03 Empty pipeline green` before any feature |
| The self-hosted runner image had no .NET SDK and no TeX Live; jobs downloaded them on a slow shared line | 6–11 minutes per job in tool set-up; restores timing out | DECISIONS D-10; T-00.03 records what each job downloads |
| Several pull requests ran CI at once on one Docker host | Docker ran out of network address pools; stacks failed to start within seconds | DECISIONS D-11, D-16; SUPERVISOR §4 "CI is a shared resource" |
| Calls between services used a default 10 s timeout with retries, while one call took 16–26 s under load | An end-to-end journey failed intermittently for hours; a non-idempotent write was retried and answered 409 | SPEC §5 note and §6 "Calls out to: time budget, retry yes/no" |
| Tests waited 1 s and 10 s on conditions | Red builds unrelated to the change under test | SPEC §10; SUPERVISOR §6 |
| Every scenario ran against a scripted stand-in; no real model produced an answer | Green results that said nothing about the product's value | DECISIONS D-20; `T-00.04`; SPEC §7 |
| Spikes were replaced by written assumptions and the phase was still counted as done | Unverified claims looked finished | Status `assumed`; SPEC §12.1 |
| `PROGRESS.md` said a job was red long after it was green; the README described steps nobody had run | The owner had to write a separate plan to re-establish the truth | PROGRESS rules (evidence link, measured date); SUPERVISOR §9 checkpoint |
| The supervisor stated a guess about the runners as a fact | Loss of trust, time spent correcting | SUPERVISOR §8 "measured or inferred" |
| A milestone had a calendar date although it depended on hardware that had not arrived | A date nobody could meet | SPEC §14 "arrival of X + N weeks" |
| Failed jobs were re-run and branches re-pushed while the host was the problem | More load on an already failing host | SUPERVISOR §6 pipeline rows |
| There was no run guide: how to start the system, how to sign in, what to click | The owner could not try the product after it was "done" | Add a `GETTING-STARTED.md` task to the first phase that has a user interface |

## What this template does not solve

- It does not write the specification. The quality of `SPEC.md` still decides the outcome.
- It cannot check that a claim is true, only that a claim carries a link and a date.
- Projects created from a template do not receive later changes to it. Rules that should stay current belong in
  `architecture-standards`; this template holds only what is filled in per project.
