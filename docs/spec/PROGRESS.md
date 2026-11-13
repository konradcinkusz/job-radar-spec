# Progress

Measured state, updated by the director after every merge and at every phase checkpoint (SUPERVISOR §9). It lives in this
repository; evidence links point at pull requests and workflow runs in `job-radar`.

Rules, checked by `scripts/check-spec.sh` where a script can check them:

- Statuses: `not-started`, `in-flight`, `open-red`, `open-green`, `merged`, `assumed`, `blocked:<reason>`.
- A row with status `merged` or `open-green` carries a link to the pull request or the CI run it was read from.
- `assumed` means the work was replaced by an unverified assumption (SPEC §12.1). It is never reported as done.
- "Implemented" is not a status. Code on a branch with unit tests green is `open-green`; it says nothing about a gate.
- Every claim has the date it was measured. A claim nobody re-measured is stale, not true.

State of this specification itself (2026-11-13): decisions recorded (DECISIONS `Status: decided`). No endpoint of any source has been called. No Copilot SDK code has been run.

| Task | Status | Evidence (PR or run link) | Measured | Notes |
|---|---|---|---|---|
| T-00.01 | merged | https://github.com/konradcinkusz/job-radar-spec/pull/2 | 2026-11-13 | owner: Owner decisions recorded (owner delegated all decisions to the director on 2026-11-12; D-25, D-29 deferred with dates) |
| T-00.02 | blocked:owner (environment `copilot` and token no longer needed, D-20 amended 2026-11-13) | | 2026-11-13 | owner: Repository, settings and the Copilot token. Not confirmed by the owner; branch protection, environment `copilot`, token and `OWNER_LOGIN` unverified (not readable by the director) |
| T-00.03 | merged | PR https://github.com/konradcinkusz/job-radar/pull/1 (squash `e7cfb45`); CI on one commit `037f890`, three green attempts: https://github.com/konradcinkusz/job-radar/actions/runs/43385096931 (attempts 1-3); CI on main https://github.com/konradcinkusz/job-radar/actions/runs/43398099998; daily.yml dispatch `profile=fake`, five jobs green: https://github.com/konradcinkusz/job-radar/actions/runs/43398113597 | 2026-11-13 | supervisor: Scaffold and empty pipeline green. Merged on the owner's explicit 'merguj' before T-00.02 was confirmed. Not shown: that the Copilot CLI download happened on the runner (log not read) |
| T-00.04 | in-flight | | | supervisor: First vertical slice against the real things |
| T-00.05 | not-started | | | owner: Real Copilot session, run locally (needs the spike program of T-00.04) |
| T-01.01 | not-started | | | supervisor: Contracts frozen |
| T-01.02 | not-started | | | implementer: Core: ids and hashes |
| T-01.03 | not-started | | | implementer: Core: normaliser and canonical key |
| T-01.04 | not-started | | | implementer: Core: lifecycle state machine |
| T-01.05 | not-started | | | implementer: Core: prefilter |
| T-01.06 | not-started | | | implementer: Config: loaders and validation |
| T-01.07 | not-started | | | implementer: Store: schema, first migration, FTS5 |
| T-01.08 | not-started | | | implementer: Store: upsert and change detection |
| T-01.09 | not-started | | | implementer: Store: canonical groups and primary choice |
| T-01.10 | not-started | | | implementer: Store: expiry, archive, runs |
| T-01.11 | not-started | | | implementer: Sources: HTTP policy, fixture replay, robots guard |
| T-01.12 | not-started | | | implementer: Sources: Greenhouse adapter |
| T-01.13 | not-started | | | implementer: Sources: Ashby adapter |
| T-01.14 | not-started | | | implementer: Sources: Remotive adapter |
| T-01.15 | not-started | | | owner: Company lists |
| T-01.16 | not-started | | | implementer: Core: health evaluator |
| T-01.17 | not-started | | | implementer: Cli: ingest |
| T-01.18 | not-started | | | implementer: Cli: scrape |
| T-01.19 | not-started | | | implementer: Core: report composer |
| T-01.20 | not-started | | | implementer: Cli: publish and health |
| T-01.21 | not-started | | | supervisor: daily.yml, Stage 0 |
| T-01.22 | not-started | | | supervisor: AppHost fake profile, run-all, getting started |
| T-01.23 | not-started | | | implementer: Cli: query and the duplicate audit; pipeline test |
| T-01.24 | not-started | | | implementer: Store: size guard |
| T-01.25 | not-started | | | supervisor: Stage 0 gate: seven days |
| T-02.01 | not-started | | | supervisor: Copilot SDK spike, in depth |
| T-02.02 | not-started | | | implementer: Agents: runner contract, fake runner, public-surface test |
| T-02.03 | not-started | | | implementer: Agents: Copilot runner |
| T-02.04 | not-started | | | implementer: Agents: prompt packaging and batching |
| T-02.05 | not-started | | | implementer: Agents: tool arguments and strict reading |
| T-02.06 | not-started | | | implementer: Agents: Extractor |
| T-02.07 | not-started | | | implementer: Core: hard exclusions |
| T-02.08 | not-started | | | implementer: Agents: Scorer |
| T-02.09 | not-started | | | implementer: Store: fields, scores, usage, pending queries |
| T-02.10 | not-started | | | implementer: Cli: enrich and the cost guard |
| T-02.11 | not-started | | | implementer: Agents: Reporter and report integration |
| T-02.12 | not-started | | | implementer: Evals: offline scenario suite |
| T-02.13 | not-started | | | supervisor: eval-live workflow and live runs |
| T-02.14 | not-started | | | implementer: Feedback capture and calibrate |
| T-02.15 | not-started | | | supervisor: daily.yml with enrich, and feedback.yml |
| T-02.16 | not-started | | | implementer: Agents: bring-your-own-key runner |
| T-02.17 | not-started | | | supervisor: Security review |
| T-02.18 | not-started | | | supervisor: Stage 1 gate: two weeks |
| T-03.00 | not-started | | | owner: Adzuna account |
| T-03.01 | not-started | | | implementer: Sources: Lever adapter |
| T-03.02 | not-started | | | implementer: Sources: No Fluff Jobs adapter |
| T-03.03 | not-started | | | implementer: Sources: justjoin.it adapter |
| T-03.04 | not-started | | | implementer: Sources: Adzuna adapter |
| T-03.05 | not-started | | | implementer: Sources: We Work Remotely adapter |
| T-03.06 | not-started | | | implementer: Sources: liveness checker |
| T-03.07 | not-started | | | implementer: Cli: verify |
| T-03.08 | not-started | | | supervisor: daily.yml with verify and the Stage 2 sources |
| T-03.09 | not-started | | | supervisor: Stage 2 gate |
| T-03.10 | not-started | | | owner: Company list growth |
| T-04.00 | not-started | | | owner: Runner decision and InfoJobs account |
| T-04.01 | not-started | | | implementer: Sources: browser context factory |
| T-04.02 | not-started | | | implementer: Sources: Pracuj.pl adapter |
| T-04.03 | not-started | | | implementer: Sources: InfoJobs adapter |
| T-04.04 | not-started | | | supervisor: daily.yml with the browser scrape job |
| T-04.05 | not-started | | | supervisor: Stage 3 gate |
| T-05.01 | not-started | | | implementer: Agents: jailed repair tools |
| T-05.02 | not-started | | | implementer: Agents: Repairer |
| T-05.03 | not-started | | | implementer: Cli: repair and the diff guard |
| T-05.04 | not-started | | | supervisor: repair.yml |
| T-05.05 | not-started | | | supervisor: Repair evals and the Stage 4 gate |
| T-05.06 | not-started | | | supervisor: Final architecture review and documents |

## Gates

One line per gate of SPEC §14: `not claimed`, `claimed <date>` with the proof link and the commit, or `failed <date>` with the
evidence. Say exactly what the proof covers and what it does not (platform, start command, real dependency or stand-in).

- **M0**: not claimed.
- **M1**: not claimed.
- **M2**: not claimed.
- **M3**: not claimed.
- **M4**: not claimed.
- **M5**: not claimed.

## Not shown yet

What is still unproven although the text exists. This list is part of every status report.

- Every source endpoint and its response shape (SPEC §12.1 A-01).
- That `CopilotClientMode.Empty`, the custom-tool allow-list, `SkipPermission` and `IsTerminal` behave as the SDK 1.0.28 documentation says (A-02), that the bundled runtime starts on a hosted runner with only a token (A-03), and what a run costs in AI credits (A-04, A-05).
- That a cheap model suffices and is in the account's model list (A-06).
- A real Copilot session (T-00.05, owner, local): nothing about the SDK has been run.
- The owner settings of T-00.02 (branch protection, `copilot` environment, token, `OWNER_LOGIN`, scanning): not confirmed.
- The Copilot CLI download on a hosted runner: seen in a local build only; not read from a runner log.

## Owner actions outstanding

- Create the private repository `job-radar`, its settings, the environment `copilot` and the fine-grained token with the Copilot Requests permission; set a reminder 7 days before the token's 90-day expiry (T-00.02).
- Name the Greenhouse or Ashby board slugs for the first probe, and 30 slugs for the first company list (T-00.04, T-01.15).
- Complete the sentence that broke off at the end of the analysis ("with all the sources and ...", D-29).
- Define track C, or leave it disabled (D-27).
