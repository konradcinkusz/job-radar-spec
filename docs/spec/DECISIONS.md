# Owner decisions

Status: open

> Every row has an answer. A row marked **PROPOSED** was chosen by the author of this specification from the owner's analysis
> (JobRadar, 12 November 2026) and the standards; it is a default, not a decision. The director session asks the owner to
> confirm or change all PROPOSED rows **in one message before the first task** (SUPERVISOR §2), writes the answers here, and
> only then sets `Status: decided`. A row with no mark restates something the owner already said.
>
> An agent must not guess an answer here. "Not decided yet" is a valid answer only with a date by which it will be.

## 1. Product

| # | Decision | Answer |
|---|---|---|
| D-01 | Repository name and the names derived from it | Application repository `job-radar` (private), solution `JobRadar.sln`, namespaces `JobRadar.*`, command-line tool `jobradar`. This repository, `job-radar-spec`, holds the specification only and never holds application code |
| D-02 | One sentence: who uses it and what they get | The owner gets one daily report of new, de-duplicated, link-checked IT job offers from direct employers across Europe that match a written set of criteria, produced by a pipeline in which GitHub Copilot SDK agents extract and judge and plain code does everything else |
| D-03 | What is explicitly **not** built | Applying to offers automatically. Logging in to any portal. Scraping LinkedIn or Indeed (a forbidden source id, enforced in code). Redistributing offers to anyone (the repository is private, the report is for the owner). A web application or any server that stays running. Notifications beyond a GitHub issue. Tailoring a CV. Anything deployed outside GitHub Actions. More than one user |
| D-04 | May real data be in a test, a log or a fixture? | Offers are public business data and may appear in fixtures. Fixtures are real responses from public endpoints, cut down to at most 5 postings per source, and stay only while the repository is private; before any public release they are replaced by synthetic ones (`open-source-release`). No candidate data exists in the system: no CV, no personal profile. Logs never carry a token and never carry more than 200 characters of an offer description |

## 2. Platforms and gates

| # | Decision | Answer |
|---|---|---|
| D-05 | Platforms a gate must be shown on | Linux only: GitHub-hosted `ubuntu-latest`, and from Stage 3 one self-hosted Linux runner for the browser sources. Windows and macOS are not gates |
| D-06 | How the system is started for the first gate | Gate: the `daily.yml` workflow dispatched with `profile=fake` on a hosted runner (five jobs, no credentials). Local development: `dotnet run --project src/JobRadar.AppHost --launch-profile fake`. No `docker compose` |
| D-07 | Deployment target | None. GitHub Actions is the runtime and nothing is deployed (ADR-0002) |
| D-08 | Hardware or accounts not yet available, and when | **PROPOSED dates:** Copilot-enabled GitHub account and a fine-grained personal access token with the Copilot Requests permission (owner, before T-00.04). A list of 30 Greenhouse/Ashby company slugs (owner, before the first live run of T-01.12). Adzuna developer account (owner, before T-03.04). InfoJobs developer account (owner, before T-04.03). A home server for a self-hosted runner (owner, decision at the M3 checkpoint, before T-04.00) |

## 3. CI

| # | Decision | Answer |
|---|---|---|
| D-09 | Runners | GitHub-hosted for every job until Stage 3. The repository variable `RUNNER_LABELS` stays unset. From Stage 3 only the browser scrape job may use the variable `RUNNER_LABELS_BROWSER`; jobs that hold a secret (`enrich`, `repair`, `eval-live`, `publish`) always run on GitHub-hosted runners |
| D-10 | What is installed in a self-hosted runner image | n/a until Stage 3. Then: .NET SDK 10.0.x, Chromium for Playwright, git, `gh`. T-04.00 records the real list |
| D-11 | Concurrency and shared Docker daemon on self-hosted runners | n/a until Stage 3. Then: one job at a time, no Docker used |
| D-12 | Default branch; automatic deletion of merged branches | `main`; delete head branches automatically: yes. The orphan branch `data` holds the database and the reports, is written only by the `publish` job and the `feedback` job, and refuses force pushes |
| D-13 | Required checks | **PROPOSED:** `build-test`, `kernel-size`, `solution-check`, `secret-scan` (names fixed in SPEC §9) on pull requests into `main` |

## 4. Delegation

| # | Decision | Answer |
|---|---|---|
| D-14 | Models | **PROPOSED:** director (the supervisor of SUPERVISOR.md) = Claude Sonnet 5.5 (`claude-sonnet-5-5`); implementer sub-sessions = Claude Haiku 5.5 (`claude-haiku-5-5`), as the owner asked. Tasks are sized for the smaller model (SUPERVISOR §10) |
| D-15 | How sub-sessions are started | **PROPOSED:** separate sessions visible to the owner, created with the session tools (`create_session` with `model` set to `claude-haiku-5-5`, then `send_message`). If those tools are missing, in-process agents with `model: haiku` |
| D-16 | Maximum sub-sessions at once | **PROPOSED:** 3. Hosted runners share no Docker daemon, but three is where review load stays manageable |
| D-17 | May the director merge green pull requests? Archive finished sessions? | **PROPOSED:** merge yes, squash, after the SUPERVISOR §7 checklist and with evidence in `PROGRESS.md`. Archive yes |
| D-18 | What the director must always ask about | Spend beyond `Agents:MaxAiCreditsPerRun` and any paid API key. Enabling the `schedule:` trigger of `daily.yml` for the first time. Creating, rotating or deleting a secret or token. Deleting a branch, a repository or the `data` branch history. Anything outside the two repositories: repository settings, runner hosts, accounts. Turning a source from excluded to enabled |

## 5. Evidence

| # | Decision | Answer |
|---|---|---|
| D-19 | What counts as proof that a gate passed | A workflow run URL on a named commit for anything a pipeline can show. For daily-run gates, the URLs of every run counted. For agent quality, the output of `jobradar calibrate` printed in a run log, with the list of feedback entries it read. For spend, the `agent_usage` block of the run summary. Measured and concluded statements are kept apart (SUPERVISOR §8) |
| D-20 | First real-world results required before any feature beyond the first slice | Two, both in Phase 0. (a) One real Greenhouse board fetched from a GitHub-hosted runner and normalised to at least one valid `RawOffer`, with the raw response saved as a fixture. (b) One real Copilot session in `CopilotClientMode.Empty` with one custom tool, returning a schema-valid tool call, with its AI credits read from the usage event and written to `docs/spikes/first-real-result.md` |

## 6. Product decisions from the analysis

| # | Decision | Answer |
|---|---|---|
| D-21 | Language and stack | .NET 10 and C#, Playwright for .NET, `GitHub.Copilot.SDK`. Decided by the standards (P1–P15 describe .NET systems) and the owner's main stack; Python is recorded as rejected in ADR-0001. **PROPOSED:** confirm |
| D-22 | Agent cost model | **PROPOSED:** the Copilot subscription through the fine-grained token for Stages 1–4, with the `IAgentRunner` abstraction and a bring-your-own-key runner built (T-02.16) but unused. Cost is counted in AI credits (the analysis speaks of premium requests; GitHub moved Copilot to AI credits in June 2026, see ADR-0006). `Agents:MaxAiCreditsPerRun` starts at 20 and is set from the first measured run |
| D-23 | Where the result goes | **PROPOSED:** the orphan branch `data` of `job-radar`, committed directly by the `publish` job (code, never an agent), plus `reports/YYYY-MM-DD.md` and one GitHub issue per day. No pull request for data (ADR-0004) |
| D-24 | Visibility of the application repository | **PROPOSED:** private. Making it public as a portfolio project is out of scope; it would be a separate gate under `open-source-release` and the data would stay private |
| D-25 | Runner for the browser sources | Not decided yet. Decided by the owner at the M3 checkpoint, before T-04.00. Until then no browser source is built |
| D-26 | Starting list of companies | The owner supplies 30 Greenhouse or Ashby board slugs in task T-01.15. The target is 50–150 across Greenhouse, Ashby and Lever by M3 |
| D-27 | Definition of track C | The analysis names tracks A, B and C but defines two criteria sets: Mid AI Engineer, and Senior with .NET as the main stack. **PROPOSED:** A = Mid AI Engineer, B = Senior with .NET main stack, C disabled in `criteria.yaml` until the owner defines it |
| D-28 | Language of the report, and when | **PROPOSED:** column labels and headings in Polish as in the owner's current offer log, everything else English. The cron is 05:00 UTC; the report is therefore ready about 06:00 CET and 07:00 CEST |
| D-29 | The unfinished sentence at the end of the analysis | The message broke off at "with all the sources and". The owner completes it; until then the scope is exactly this specification |
| D-30 | Office presence rule | **PROPOSED reading:** at most one office day a week anywhere is acceptable. More than one regular office day is a hard exclusion unless the office is in Spain, in which case it is not excluded and scores lower (SPEC §6.6 rule `office-presence`) |
| D-31 | Report threshold and calibration | Threshold starts at 70. For the first two weeks of Stage 1 the owner marks each reported offer `fit` or `nofit` in the daily issue (SPEC §6.7); M2 needs agreement of at least 80% |

## Decision log

Decisions taken after the start go here, newest first, with the date and the reason. A decision that changes the specification
lands in the same pull request as the change to `SPEC.md`.

| Date | Decision | Reason |
|---|---|---|
| 2026-11-12 | Specification written from the owner's analysis; PROPOSED rows await confirmation | Starting point |
