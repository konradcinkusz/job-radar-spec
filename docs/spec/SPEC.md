# JobRadar — System specification

> Normative description of what is built. Tasks are in [`TASKS.md`](TASKS.md), the execution protocol in
> [`SUPERVISOR.md`](SUPERVISOR.md), measured state in [`PROGRESS.md`](PROGRESS.md), owner decisions in [`DECISIONS.md`](DECISIONS.md).
> Per-source detail is in [`SOURCES.md`](SOURCES.md) and the exact use of the Copilot SDK in [`COPILOT-SDK.md`](COPILOT-SDK.md);
> both are part of this specification.
>
> Rules for reading this file:
> - Architecture rules are **not** restated here. They live in
>   [`architecture-standards`](https://github.com/konradcinkusz/architecture-standards) (P1–P15); this file says only what is
>   specific to JobRadar and where it deviates (§12.2).
> - What a stand-in can and cannot prove is in §7. A result obtained against a stand-in is reported as such.
> - Everything assumed and not verified is in §12.1. No endpoint of any source has been called yet (§12.1 A-01).

## 0. Glossary

| Term | Meaning in this system |
|---|---|
| Director | The supervisor session of `SUPERVISOR.md`. It selects tasks, writes briefs, reviews and merges. "Director" and "supervisor" are the same role |
| Implementer | A Claude Haiku 5.5 sub-session that does exactly one task |
| Offer | One job posting from one source, stored as a row of `offers` |
| Source | One place offers come from: an ATS (Greenhouse, Ashby, Lever), a portal, or an aggregator. Identified by a lowercase id such as `greenhouse` |
| Adapter | The code of one source: `IJobSource` (§6.3) |
| Raw offer | `RawOffer`: the common record an adapter produces from deterministic fields, with no model involved. One line of `raw/<source>.jsonl` |
| Run | One execution of the daily workflow. `run_id` is the workflow run id plus attempt |
| Run date | The UTC date on which the run started. All "today" logic uses it |
| Prefilter | Stage 1: cheap rules in code that reject obvious misses before any agent sees an offer |
| Extractor, Scorer, Reporter, Repairer | The four agents (§6.5). Each is a Copilot SDK session with a closed tool list |
| Track | A named criteria set an offer is scored against: `A`, `B`, `C` or `none` (D-27) |
| Lifecycle | `new → active → expired → archived` (§6.4) |
| Liveness | Whether the offer link still works: `unknown`, `alive`, `dead`, `unverified` (§6.4). Independent of lifecycle |
| Hard exclusion | A rule in `criteria.yaml` that forces score 0. Applied by code after the model answers (ADR-0005) |
| Canonical key | `normalised company | normalised title | country`; offers with the same key are one offer across sources |
| AI credits | The unit GitHub Copilot bills model use in since June 2026, metered per token. One credit is 0.01 US dollars, configurable as `Cost:UsdPerAiCredit` (§5 R14, ADR-0006) |
| Data branch | The orphan branch `data` of `job-radar`: the SQLite file, the reports, the feedback log |
| Profile | `fake` (fixtures, scripted agents, temporary database, no credentials) or `live` |

## 1. Goals and non-goals

### 1.1 Goals

1. Once a day the owner can open one GitHub issue and one file `reports/YYYY-MM-DD.md` and see every offer that appeared since
   the previous run, passes the criteria, and scored at or above the threshold (start 70). Each row shows date, company, role,
   link, work mode, track, salary range and status.
2. An offer appears in the report **once**, however many sources carry it. The owner sees the copy from the source closest to the
   employer (ATS, then portal, then aggregator). Proof: the duplicate audit of §13 returns zero.
3. An offer whose link was confirmed alive today is shown as `alive`. An offer whose liveness could not be checked is shown and
   marked `unverified`. The system never shows a dead link as alive and never guesses.
4. One failing source never stops the others. A source that returns zero offers, or more than 80% fewer than its 7-run median,
   appears in the report's source-health section and as an open issue labelled `source-health`.
5. The cost of agents depends on the number of new offers, not on the size of the database, and is printed per run in AI credits
   with its dollar figure. A run stops spending at `Agents:MaxAiCreditsPerRun`; offers left unevaluated are reported as such and
   are picked up the next day.
6. An agent that reads offer text cannot run a shell, reach the network, touch Git or write a file. Proof: the allow-list tests
   of §10 and the live tool-surface check of T-02.01.
7. Every judgement can be compared with the owner's own: the owner marks reported offers `fit` or `nofit` and `jobradar calibrate`
   prints agreement. M2 requires at least 80%.
8. When a source's layout changes, a Repairer agent proposes the fix as a pull request that the owner reviews; it never pushes
   to `main` (Stage 4).

### 1.2 Non-goals

Copied from DECISIONS D-03 and extended. A task that serves one of these is rejected.

- Applying automatically; logging in to any portal; scraping LinkedIn or Indeed.
- Redistributing offers. Himalayas terms forbid passing offers on; Remotive requires a link back and a mention of the source.
- A running web service, an API, a front end, a mobile app. The only outputs are the SQLite file, Markdown reports, GitHub issues
  and a CLI (`jobradar query`).
- Learning from feedback automatically. Feedback is a test set for prompts and thresholds (§6.7); a person changes the criteria.
- Any LLM judgement about chess-like "quality" of a company. The Scorer applies written criteria and nothing else.
- Salary normalisation across currencies. Salaries are shown as the source gives them.

## 2. System context

```
                       ┌──────────────────────────── GitHub Actions (the only runtime) ────────────────────────────┐
 ATS APIs ────────────▶│ scrape ─▶ ingest ─▶ enrich ─▶ verify ─▶ publish                                           │
 (Greenhouse, Ashby,   │ code      code      agents    code      code + Reporter agent                            │
  Lever, Adzuna, WWR,  │ raw/*.jsonl  SQLite   Extractor  link      commit to `data`, issue                       │
  Remotive, portals)   │ artifact     artifact Scorer     checks                                                   │
                       └───────────────────────┬────────────────────────────────────────┬──────────────────────────┘
 Copilot service ◀─────── Copilot runtime ◀────┘ (enrich, repair, eval-live only)       ▼
                                                                          `data` branch: data/jobradar.db, reports/, feedback/
 Owner ───────────────────────── reads the daily issue, comments `fit` / `nofit`, reviews repair pull requests
```

| Actor or system | Direction | What crosses |
|---|---|---|
| Owner | in | Criteria (`config/*.yaml` through pull requests), company lists, `fit`/`nofit` comments, secrets |
| Owner | out | Daily issue, `reports/YYYY-MM-DD.md`, source-health issues, repair pull requests |
| Source sites and APIs | out (requests), in (offers) | HTTP GET only. Adzuna and InfoJobs need keys (`ADZUNA_APP_ID`, `ADZUNA_APP_KEY`, InfoJobs `client_id:secret`) |
| GitHub Copilot service | out (offer text in prompts), in (tool calls) | Only from jobs that hold `COPILOT_GITHUB_TOKEN`. Offer text leaves the runner here; it is public data (D-04) |
| GitHub API | out | Issues, pull requests, branch push, via `GITHUB_TOKEN` and `gh` in workflow steps, never from an agent |

## 3. Repository

### 3.1 Name and derived names

| Thing | Name |
|---|---|
| Specification repository | `job-radar-spec` (this one) |
| Application repository | `job-radar` (private) |
| Solution | `JobRadar.sln` |
| AppHost / ServiceDefaults | `JobRadar.AppHost` / `JobRadar.ServiceDefaults` |
| CLI project and tool | `JobRadar.Cli`, executable `jobradar` |
| Data branch | `data` (orphan) |
| Image prefix | none: nothing is containerised (ADR-0002) |

### 3.2 Tree of `job-radar`

```
global.json  Directory.Build.props  Directory.Packages.props  .editorconfig  JobRadar.sln  AGENTS.md  README.md
src/
  JobRadar.AppHost/         Aspire composition root for development. Starts the CLI with `run-all --profile fake` and the dashboard
  JobRadar.ServiceDefaults/ kernel: OpenTelemetry, logging format, `doctor` health model (<= 400 lines, no domain)
  JobRadar.Core/            pure domain: models, enums, text normalisation, ids, canonical key, lifecycle machine, prefilter,
                            hard exclusions, report composer, health evaluator. No I/O, no clock, no packages
  JobRadar.Config/          YAML loaders and validation for config/*.yaml. Package: YamlDotNet
  JobRadar.Sources/         IJobSource adapters, SourceHttp, robots guard, fixture replay. Packages: Microsoft.Playwright,
                            Microsoft.Extensions.Resilience
  JobRadar.Store/           EF Core SQLite: model, migrations, FTS5, repositories. Packages: EF Core SQLite (+ Design as tooling)
  JobRadar.Agents/          IAgentRunner, CopilotAgentRunner, ByokAgentRunner, FakeAgentRunner, tools, prompts (embedded),
                            batching, Extractor, Scorer, Reporter, Repairer. The ONLY project that references GitHub.Copilot.SDK
  JobRadar.Cli/             commands: scrape, ingest, enrich, verify, publish, health, doctor, calibrate, query, repair, run-all.
                            Program.cs is a manifest
tests/
  JobRadar.Core.Tests/  JobRadar.Config.Tests/  JobRadar.Sources.Tests/  JobRadar.Store.Tests/  JobRadar.Agents.Tests/
  JobRadar.Cli.Tests/        pipeline on fixtures, end to end, no network
  fixtures/<source>/         recorded responses, <= 5 postings each
  evals/                     scenario data for the agents (§10)
config/  sources.yaml  criteria.yaml  criteria.lock  blocklist.yaml  report.yaml
scripts/  dev-setup.sh  setup-hooks.sh  publish-data.sh  check-kernel-size.sh  check-solution.sh
docs/  architecture/ (owned by the director)  spikes/  operations/CI.md  GETTING-STARTED.md
.github/workflows/  ci.yml  daily.yml  repair.yml  feedback.yml  probe.yml  eval-live.yml  secret-scan in ci.yml
```

Project references are the allowed edges. Any other edge is a review finding.

| Project | References |
|---|---|
| `Core` | none |
| `Config` | `Core` |
| `Sources` | `Core` |
| `Store` | `Core` |
| `Agents` | `Core` |
| `ServiceDefaults` | none |
| `Cli` | `ServiceDefaults`, `Core`, `Config`, `Sources`, `Store`, `Agents` |
| `AppHost` | `Cli` |

Dependency budget:

| Project | Allowed packages |
|---|---|
| `Core`, `ServiceDefaults` (beyond OpenTelemetry), `AppHost` (beyond Aspire) | none |
| `ServiceDefaults` | `OpenTelemetry.*`, `Microsoft.Extensions.Logging.Console` (JSON log format; amended 2026-11-13 during T-00.03) |
| `Config` | `YamlDotNet` |
| `Sources` | `Microsoft.Playwright`, `Microsoft.Extensions.Resilience` |
| `Store` | `Microsoft.EntityFrameworkCore.Sqlite`; `Microsoft.EntityFrameworkCore.Design` as build tooling only |
| `Agents` | `GitHub.Copilot.SDK` (and its dependency `Microsoft.Extensions.AI.Abstractions`, which stays internal) |
| `Cli` | `Microsoft.Extensions.Hosting` |
| tests | xUnit, `Microsoft.Playwright` (browser tier only) |

A package is added only by the director, in `Directory.Packages.props`.

## 4. Runtime topology

### 4.1 Development (P1)

The AppHost is the composition root for a developer. `dotnet run --project src/JobRadar.AppHost --launch-profile fake` runs the
whole pipeline once on fixtures and shows traces in the Aspire dashboard. It is not the production topology: production is
`.github/workflows/daily.yml` (P1).

| Resource | Kind | Notes |
|---|---|---|
| `jobradar` | project (`JobRadar.Cli`) | args `run-all --profile fake`; environment `JOBRADAR_PROFILE=fake` |

Profile `fake`: `Sources=Fixtures` (replay of `tests/fixtures`), `Agents:Provider=Fake` (scripted answers), database a temporary
SQLite file, no network, no credentials, no Playwright browser. This is the default profile and must work from a clean clone.
Profile `live`: real endpoints, `Agents:Provider=Copilot` or `Byok`, the database restored from the data branch.

### 4.2 Without Aspire

Every command also runs as `dotnet run --project src/JobRadar.Cli -- <command> --profile fake`. This is what the workflow jobs
call. The gate is the workflow (DECISIONS D-06), not the AppHost.

### 4.3 Deployed

Nothing is deployed (ADR-0002). State lives in two places only: the SQLite file and reports on the `data` branch, and workflow
artifacts between jobs (retention 1 day, except failure snapshots, 7 days).

## 5. Cross-cutting rules (apply to every task)

| # | Rule |
|---|---|
| R1 | English for code, comments, docs and logs. Report headings and column labels come from `config/report.yaml` and are Polish (D-28) |
| R2 | **Deterministic first.** Anything computable by code is code. A model is used only to extract fields a source does not give and to judge fit against written criteria |
| R3 | **Agents have a closed tool list** (§6.5 table) in `CopilotClientMode.Empty`, no shell, no network, no Git, no file access, except the Repairer's jailed tools. Writing to the repository, the database and GitHub is done by workflow code and CLI commands |
| R4 | **Offer text is data.** It is never placed in a system prompt. In a user prompt it sits between delimiters that contain a random per-call nonce, after a fixed instruction that says it is untrusted. Control characters and zero-width characters are removed; each description is cut at 12 000 characters with a visible marker |
| R5 | **No model output is trusted.** Enumerated fields are closed enums; numbers are range-checked; strings have length caps; an `evidence` quote must be a substring of the description, else the field is downgraded. A score is clamped to 0–100 and then capped by hard exclusions in code |
| R6 | **No guessing about liveness.** If the check cannot decide, the offer is `unverified` |
| R7 | **Idempotent commands.** Running any command twice for one run date gives the same database rows and the same report. The report file is overwritten; the daily issue is found by the marker `<!-- jobradar:daily:YYYY-MM-DD -->` and updated, never duplicated |
| R8 | **Source isolation.** Each source runs in its own browser context and its own `try/catch`. An offer is counted as missing from a source (`missed_runs`) only on a run in which that source was healthy and only for a source whose listing is complete (`expiry_by_absence: true` in `sources.yaml`; false for feeds that show only recent items, SOURCES §4) |
| R9 | **Politeness and terms.** 1–3 s random delay between requests to one host; at most 3 hosts at once; `robots.txt` honoured for every HTML host; User-Agent `JobRadar/1.0 (personal use)`; the ids `linkedin` and `indeed` are rejected by the config loader. Sources with attribution terms keep their attribution fields |
| R10 | **Time.** `TimeProvider` is injected; `Core` never reads a clock. Timestamps are UTC, ISO 8601. The run date is the UTC date at run start |
| R11 | **Timeouts and retries** are in the table below |
| R12 | **Secrets.** Only: `COPILOT_GITHUB_TOKEN` (environment `copilot`; `enrich`, `repair`, `eval-live`, `probe-copilot`), `ADZUNA_APP_ID` and `ADZUNA_APP_KEY` (scrape), `INFOJOBS_CLIENT_ID` and `INFOJOBS_SECRET` (browser scrape). Read at step level, never at job level. Never printed, never in an artifact, never in a command line. A secret scanner runs before every commit and in CI (P5) |
| R13 | **One writer.** Only `Store` writes the database, only the `publish` job commits it. Feedback is an append-only `feedback/feedback.jsonl` file so that the `feedback` workflow and `publish` never edit the same binary |
| R14 | **Cost is measured and bounded, and never scored.** AI credits are summed per batch from the usage events; the dollar figure uses `Cost:UsdPerAiCredit` (default 0.01). Cost, latency and tokens never enter a score or a threshold |
| R15 | **Criteria are versioned.** `config/criteria.yaml` has an integer `version`; `config/criteria.lock` holds the file's SHA-256 and the version it belongs to. CI fails when the hash changed and the version did not |
| R16 | **Pinned.** `GitHub.Copilot.SDK` is pinned in `Directory.Packages.props`. Third-party actions are pinned to a commit SHA. Workflow `permissions:` are set per job and are minimal |
| R17 | **Prefer the smaller change.** A new source is one adapter, one `sources.yaml` entry, fixtures and tests. No base class (P10) |

Timeouts and retries (R11):

| Call | Longest it may take | Retry |
|---|---|---|
| One page or API request | 30 s | GET only: 2 retries, back-off 2 s then 8 s, on 429 and 5xx, honouring `Retry-After` up to 60 s |
| One source (all its requests) | 10 min | none; the source is marked unhealthy |
| One Copilot batch reply | `Agents:ReplyTimeoutSeconds`, default 180 s (the value the chess arena settled on) | Not at transport level, each retry costs credits. One batch-level re-run only for offers the model left out of its answer |
| Starting the Copilot runtime, sign-in check and model listing | 30 s together | none; state becomes `Unavailable` or `NotAuthenticated`, enrich is skipped |
| A GitHub API call from a workflow step | 30 s | 2 retries; issue and branch writes are idempotent (marker, fast-forward push) |
| One workflow job | per §9 | whole job is re-run once by hand, never automatically |

> A write that is not idempotent is never retried. Issue creation is made idempotent by the marker; the branch push is a
> fast-forward of `data` after `git fetch`.

## 6. Modules

JobRadar is one deployable (the CLI) and one database, so P3 is met trivially: `Store` owns the schema and nothing else opens it.

### 6.1 `JobRadar.Core` (stateless, pure)

- **Responsibilities:** the models of §6.4, normalisation, identity, state machine, prefilter, hard exclusions, health evaluator,
  report composer. Must not: read a clock, a file, the network, a database, an environment variable.
- **Types (frozen by T-01.01, then changed only by the director):**
  `RawOffer`, `OfferFields`, `ScoreResult`, `Offer`, `SourceKind`, `Lifecycle`, `Liveness`, `WorkMode`, `Track`,
  `SourceHealth`, `IJobSource`, `IOfferStore`, `IKnownOffers`, `ICriteria`, `IReportSink`.
- **Functions (pure, each its own file, each tested):**

| Function | Rule |
|---|---|
| `OfferId.Of(source, sourceId)` | lowercase hex of SHA-256 of `source + "\u001f" + sourceId`, first 32 characters |
| `DescriptionHash.Of(text)` | SHA-256 of the description after trimming, collapsing whitespace runs to one space, and Unicode NFC; lowercase hex, full length |
| `Normalizer.Company(s)` | NFKD, remove diacritics, lowercase; remove legal-form words (`sp. z o.o.`, `s.a.`, `spółka`, `gmbh`, `ag`, `ltd`, `llc`, `inc`, `s.l.`, `s.a.u.`, `b.v.`, `oy`, `ab`, `as`, `sas`, `srl`); replace punctuation with spaces; collapse spaces |
| `Normalizer.Title(s)` | the same; additionally remove gender markers `(m/f/d)`, `(m/w/d)`, `(f/m/x)`, `m/k`, `(all genders)`, level words are **kept** |
| `CanonicalKey.Of(company, title, country)` | `Company(company) + "\|" + Title(title) + "\|" + upper(country ?? "xx")` |
| `Lifecycle.Next(state, event)` | the table in §6.4; any other pair is an error value, not an exception |
| `Prefilter.Evaluate(rawOffer, criteria, blocklist)` | §6.6 stage 1; returns `Pass` or `Reject(reasonId)` |
| `HardExclusions.Apply(fields, rawOffer, criteria, modelScore)` | §6.6; returns the capped score and the list of rule ids |
| `HealthEvaluator.Evaluate(todayCount, previousCounts, errors)` | §6.3 |
| `ReportComposer.Compose(inputs)` | §6.8; pure function from values to a Markdown string |

### 6.2 `JobRadar.Config`

- **Responsibilities:** load and validate `sources.yaml`, `criteria.yaml`, `blocklist.yaml`, `report.yaml` into immutable objects
  from `Core`. Validation errors name the file, the path and the rule, and stop the command before any network call.
- **Validation rules:** unknown keys are errors; source ids match `^[a-z][a-z0-9-]{1,30}$`; ids `linkedin` and `indeed` are
  refused with a message citing D-03; each company in an ATS list has a `slug` matching `^[A-Za-z0-9._-]+$`; `criteria.version`
  is a positive integer; tracks are `A`, `B`, `C`; thresholds 0–100; the lock file agrees (R15).
- **Seed values** of `criteria.yaml` are in Appendix A.

### 6.3 `JobRadar.Sources`

- **Responsibilities:** one adapter per source behind `IJobSource`; the HTTP policy; the robots guard; replay from fixtures.
  Must not: write the database, call an agent, read secrets other than its own source's.
- **Contract (frozen by T-01.01):**

```csharp
public interface IJobSource
{
    string Id { get; }                       // "greenhouse"
    SourceKind Kind { get; }                 // Ats = 3, Portal = 2, Aggregator = 1 (precedence for duplicates)
    Task<IReadOnlyList<DiscoveredOffer>> DiscoverAsync(SourceContext context, CancellationToken ct);
    Task<RawDetail?> FetchDetailAsync(DiscoveredOffer offer, SourceContext context, CancellationToken ct);
    RawOffer Normalize(RawDetail detail);    // deterministic, no model, no I/O
    SourceHealth Health();                   // counts and errors of this run
}
```

  `DiscoveredOffer` carries `SourceId`, `Url` and optionally the raw record when the listing already contains the detail (ATS
  APIs usually do). `FetchDetailAsync` is called only for offers that `IKnownOffers` reports as new, or not seen for
  `Scrape:RefetchAfterDays` (default 7). `SourceContext` carries the HTTP client, the clock, the per-source config and a logger.
- **Cheapest path first:** HTTP through Playwright's `IAPIRequestContext` (no rendering). A browser page is opened only when the
  source needs JavaScript or cookies (Stage 3). For HTML sources the extraction order is JSON-LD `JobPosting`, then embedded
  state such as `__NEXT_DATA__`, then CSS selectors. The description stays text for the agents.
- **HTTP policy (`SourceHttp`)**, in one place: R9 delay and host concurrency, R11 timeouts and retries, a User-Agent, a request
  counter per source. Images, fonts and media are blocked with `page.route()` whenever a page is opened.
- **Health:** `Health()` returns `OffersFound`, `Errors[]`. `HealthEvaluator.Evaluate` marks a source unhealthy when
  `OffersFound == 0`, or when `OffersFound < 0.2 × median(last 7 healthy runs)` and at least 3 previous runs exist.
- **On a parse error** the adapter writes the raw HTML or JSON and, in browser mode, a screenshot to `artifacts/failures/<source>/`
  (uploaded for 7 days). This is the Repairer's input.
- **Calls out to:** source hosts only, with the budgets of R11.
- **Degrades how:** a source that throws is recorded as unhealthy with the exception type and message (never the response body)
  and the other sources continue. A missing key for a keyed source disables that source and `doctor` says so (P8).
- **Extension point (P10):** a new `IJobSource` registered in `AddSources` and listed in `sources.yaml`.

Stage assignment and per-source facts are in [`SOURCES.md`](SOURCES.md).

### 6.4 `JobRadar.Store` and the data model

- **Responsibilities:** the only writer of the database; migrations; FTS5; repositories behind the ports of `Core`. One file:
  `data/jobradar.db` on the data branch; in profile `fake` a temporary file. Tests use a real SQLite file or `:memory:` database,
  **never** the EF InMemory provider, because the dedup indexes, FTS5 and query translation are exactly what must be proven
  (lesson of the chess arena, where InMemory hid a query PostgreSQL could not translate).
- **Migrations:** EF Core migrations, applied by `jobradar migrate`, which every command calls first. This replaces the
  hosted-service migration of P4 because the CLI is not a long-running host (§12.2). Reference data is not in migrations.
  The FTS5 table and its triggers are created by `migrationBuilder.Sql` in their own migration.

Tables (types are SQLite types; all timestamps UTC ISO 8601 text; booleans 0/1):

**`offers`**

| Column | Type | Notes |
|---|---|---|
| `id` | TEXT PK | `OfferId.Of(source, source_id)` |
| `source`, `source_id` | TEXT NOT NULL | `UNIQUE(source, source_id)` |
| `url` | TEXT NOT NULL | |
| `canonical_key` | TEXT NOT NULL | indexed |
| `primary_offer_id` | TEXT NULL | NULL for the primary of a group; otherwise the id of the primary |
| `title`, `company` | TEXT NOT NULL | |
| `country` | TEXT NULL | ISO 3166-1 alpha-2 when known |
| `location` | TEXT NULL | as the source gives it |
| `work_mode` | TEXT NOT NULL | `remote`, `hybrid`, `onsite`, `unknown` |
| `office_days_per_week` | INTEGER NULL | from the source only; the Extractor fills its own field |
| `contract` | TEXT NULL | as the source gives it |
| `salary_min`, `salary_max` | INTEGER NULL | |
| `currency`, `salary_period` | TEXT NULL | `year`, `month`, `day`, `hour` |
| `description` | TEXT NOT NULL | purged (set to empty) when the offer is archived |
| `description_hash` | TEXT NOT NULL | `DescriptionHash.Of` |
| `posted_at` | TEXT NULL | |
| `first_seen_at`, `last_seen_at` | TEXT NOT NULL | |
| `lifecycle` | TEXT NOT NULL | `new`, `active`, `expired`, `archived` |
| `missed_runs` | INTEGER NOT NULL | consecutive healthy runs of the source without this offer |
| `liveness` | TEXT NOT NULL | `unknown`, `alive`, `dead`, `unverified` |
| `last_checked_at` | TEXT NULL | |
| `expired_at` | TEXT NULL | |
| `prefilter_reason` | TEXT NULL | set when Stage 1 rejected it; such an offer is never sent to an agent |
| `needs_review` | INTEGER NOT NULL | set after a failed extraction |

**`offer_fields`**, key `(offer_id, description_hash)`: `role_family`, `stack_main`, `seniority`, `work_mode`,
`office_days_per_week`, `office_country`, `languages` (JSON array), `b2b_allowed`, `employer_type`, `confidence`,
`evidence` (JSON object of quotes), `model`, `prompt_version`, `extracted_at`.

**`scores`**, key `(offer_id, description_hash, criteria_version)`: `track`, `score`, `reasons` (JSON), `red_flags` (JSON),
`capped_by` (JSON array of rule ids), `model`, `prompt_version`, `scored_at`. A new criteria version adds a row; it replaces none.

**`runs`**, key `(run_id, source, kind)`: `kind` (`scrape`, `enrich`, `verify`), `started_at`, `finished_at`, `offers_found`,
`offers_new`, `offers_changed`, `errors` (JSON), `healthy`.

**`agent_usage`**, key `(run_id, agent, model)`: `batches`, `offers`, `input_tokens`, `output_tokens`, `reasoning_tokens`,
`cached_input_tokens`, `ai_credits` (REAL, NULL when the runtime reported none), `usd` (REAL, NULL likewise).

**`feedback`**, key `(offer_id, created_at)`: `verdict` (`fit`, `nofit`), `note`, `author`. Filled by `ingest` from
`feedback/feedback.jsonl`; never edited by hand.

**`offers_fts`**: FTS5 external-content table over `offers(title, company, description)` with insert, update and delete triggers.

Enumerated values of the extraction (closed; anything else is rejected):

| Field | Values |
|---|---|
| `role_family` | `ai_engineer`, `backend`, `fullstack`, `data`, `devops`, `other` |
| `stack_main` | `dotnet`, `python`, `java`, `typescript`, `go`, `other`, `unknown` |
| `seniority` | `junior`, `mid`, `senior`, `lead`, `unspecified` |
| `work_mode` | `remote`, `hybrid`, `onsite`, `unknown` |
| `office_days_per_week` | integer 0–5 or null |
| `office_country` | ISO alpha-2 or null |
| `languages` | array of ISO 639-1 codes the posting **requires** |
| `b2b_allowed` | `yes`, `no`, `unknown` |
| `employer_type` | `direct`, `agency`, `consulting`, `unknown` |
| `confidence` | `low`, `medium`, `high` |

**Lifecycle machine** (`Lifecycle.Next`):

| From | Event | To | Side effect |
|---|---|---|---|
| (absent) | `Seen` | `new` | `first_seen_at = last_seen_at = run date`, `missed_runs = 0` |
| any | `Seen` | unchanged, except `expired → active` | `last_seen_at` updated, `missed_runs = 0`, `expired_at` cleared |
| `new` | `Published` | `active` | the day's report has been composed |
| `new`, `active` | `Missed` (source healthy and `expiry_by_absence` true for it) | unchanged | `missed_runs += 1` |
| `new`, `active` | `MissedThrice` (`missed_runs ≥ 3`) or `Dead` (liveness check says dead) | `expired` | `expired_at = run date` |
| `expired` | `Aged` (`expired_at` older than `Archive:AfterDays`, default 30) | `archived` | `description` purged, `offer_fields` text kept |

Liveness is independent: `unknown` at first sight; `alive` or `dead` after a successful check; `unverified` when the check could
not decide (error, timeout, a block page). It records `last_checked_at`. `Dead` and `MissedThrice` both lead to `expired`.

**Duplicates.** Within a source: the unique pair `(source, source_id)`; seeing it again only updates `last_seen_at` (and, when
`description_hash` changed, the description, which makes the offer eligible for re-extraction). Across sources: offers with the
same `canonical_key` form a group. The primary is the member with the highest `SourceKind`; ties go to the earliest
`first_seen_at`, then to the lexicographically smaller `id`. Others get `primary_offer_id` set. Only primaries are reported and
sent to agents.

**Retention.** `Archive:AfterDays` as above. `VACUUM` runs weekly in `publish` on Sundays. Size guard: warn at 40 MB (an issue
labelled `db-size`), stop committing at 90 MB (GitHub refuses a file over 100 MB), see §13.

### 6.5 `JobRadar.Agents`

The only project that references `GitHub.Copilot.SDK`. No SDK type appears in a public signature (checked by
`PublicSurfaceTests` by reflection, as in the chess arena). The exact calls, and what has and has not been verified, are in
[`COPILOT-SDK.md`](COPILOT-SDK.md); this section is the behaviour.

- **Interface (frozen by T-01.01; SDK-free):**

```csharp
public interface IAgentRunner
{
    AgentRunnerStatus Status { get; }   // Ready | Fake | NotAuthenticated | Unavailable
    Task<AgentRun> RunAsync(AgentRequest request, CancellationToken ct);
}
public sealed record AgentRequest(string AgentName, string Model, string? ReasoningEffort, string SystemPrompt,
    string UserPrompt, IReadOnlyList<AgentTool> Tools, TimeSpan Timeout);
public sealed record AgentTool(string Name, string Description, Type ArgumentsType,   // closed record; schema is derived from it
    Func<object /* instance of ArgumentsType */, AgentToolResult> Handler, bool EndsTurn);
public sealed record AgentToolResult(bool Accepted, string Message);   // a rejection is shown to the model so it can retry
public sealed record AgentRun(IReadOnlyList<ToolCallRecord> ToolCalls, string? FinalText, AgentUsage Usage, TimeSpan Latency);
```

- **Implementations:** `CopilotAgentRunner` (the SDK), `ByokAgentRunner` (the same SDK with `SessionConfig.Provider`, for an
  OpenAI-compatible, Azure or Anthropic endpoint, T-02.16), `FakeAgentRunner` (scripted, §7).
- **Session rules (R3), all for the Copilot runner:** client in `CopilotClientMode.Empty`; per session `AvailableTools` lists
  exactly the custom tool names of the request; every custom tool is defined with `SkipPermission = true` and, for the one
  that returns the result, `IsTerminal = true`; `OnPermissionRequest` rejects everything; `SystemMessage` in `Replace` mode;
  `Streaming = false`; one session per batch; the session is disposed after the batch. The token comes from
  `COPILOT_GITHUB_TOKEN` through `CopilotClientOptions.GitHubToken`. If the spike (T-02.01) shows that any of these does not
  hold on the pinned version, the director amends this section before T-02.03 starts.
- **Batching:** 15 offers per prompt by default (`Agents:BatchSize`, allowed 10–20); a batch is split further when its estimated
  size exceeds `Agents:MaxPromptCharacters` (default 60 000). Offers are referred to in the prompt and in the tool call by short
  references `o1 … oN`, never by their real ids, so the model cannot invent or swap ids.
- **Cost guard:** after every batch the runner adds the reported AI credits to the run total. When the total reaches
  `Agents:MaxAiCreditsPerRun` the command stops starting batches, records the rest as pending, and exits 0 with a warning.
  A batch whose usage is not reported counts as `Agents:AssumedCreditsPerBatch` (default 0.5) for this guard only, and is
  stored as NULL.
- **Health:** `doctor` reports `Ready | Fake | NotAuthenticated | Unavailable` and whether the configured models are in the
  runtime's list. It is never an error (P8): enrich is skipped and the report says so.

The four agents:

| Agent | Input | Tools (allow-list) | Output (via tool, closed schema) |
|---|---|---|---|
| **Extractor** | up to 15 offers: reference, title, company, description between nonce delimiters | `save_offer_fields` only | per reference: `role_family`, `stack_main`, `seniority`, `work_mode`, `office_days_per_week`, `office_country`, `languages`, `b2b_allowed`, `employer_type`, `confidence`, `evidence` (a quote of at most 200 characters for each of work mode, office, b2b, employer type, languages) |
| **Scorer** | per offer: reference, title, company, the validated extracted fields, salary, a 1 200-character description excerpt; plus the criteria of the enabled tracks | `save_score` only | per reference: `track` (`A`, `B`, `C`, `none`), `score` 0–100, `reasons` (at most 3, each at most 160 characters), `red_flags` (from the enum of §6.6, plus at most 2 free texts of at most 80 characters) |
| **Reporter** | the numbers of the day and the top offers' titles and reasons | `write_report_summary` only | `summary_md`, at most 1 200 characters, no links, no HTML |
| **Repairer** | failure snapshot, adapter source, error log | `read_adapter_file`, `write_adapter_file`, `run_adapter_tests`, jailed to `src/JobRadar.Sources/<source>/**` and `tests/fixtures/<source>/**` | edited files in a scratch checkout; the pull request is opened by workflow code (§6.9) |

**Validation of the Extractor's answer (code, in `Agents`):** the tool handler checks the arguments against the schema; unknown
or missing references, enum violations and over-long strings are returned to the model as a rejection so it can retry within the
session. After the session, any offer without an accepted result is re-run once in a new batch; if it still has none it gets
`needs_review = 1` and stays out of the report. For each accepted result the code verifies every `evidence` quote is a
substring of the description after whitespace normalisation; a field whose quote is missing is kept but `confidence` is
lowered one step, and a quote that is not found marks the field `unknown`. The result is stored with the model name and the
`prompt_version` (the SHA-256 of the embedded prompt files, first 12 characters).

**Prompt-injection defence (the main risk, §11):** R3 and R4; closed schemas; references instead of ids; the Scorer never sees
the full description; the Scorer's output is capped by code (§6.6); an offer whose description matches the injection patterns
of `config/criteria.yaml` `injection_patterns` gets the red flag `suspected_injection` and is excluded from the report, whatever
the model said. The evals of §10 carry a class of adversarial descriptions.

### 6.6 Filtering and scoring

**Stage 1, prefilter (code, `Prefilter.Evaluate`).** An offer is rejected, with the reason id stored in `prefilter_reason`, when:

| Reason id | Condition |
|---|---|
| `title-no-keyword` | the normalised title contains none of `criteria.title_keywords` |
| `mode-onsite` | the source says `onsite` |
| `mode-hybrid-heavy` | the source says `hybrid` and `office_days_per_week > criteria.max_office_days_per_week`; a hybrid offer with no stated days passes |
| `blocklist-company` | the normalised company is in `config/blocklist.yaml` (agencies, software houses; grown by hand; the Scorer may add proposals to the daily summary, never to the file) |
| `country-outside-scope` | the country is known and not in `criteria.countries` |

The report states how many offers each reason removed. The ratio of offers sent to agents to offers ingested is printed per run
(the analysis expects one order of magnitude; it is measured, §13).

**Stage 2, Extractor.** §6.5.

**Stage 3, Scorer and hard exclusions (code after the model).** `HardExclusions.Apply` takes the model's score and the validated
fields, applies the rules below in order, and returns `0` and the list of the rules that fired if any did. The model's own
opinion on these points is ignored (ADR-0005).

| Rule id | Fires when |
|---|---|
| `employer-agency` | `employer_type` is `agency` or `consulting` |
| `language-not-basic` | `languages` contains a language in `criteria.excluded_languages` (start: `de`) |
| `office-presence` | `office_days_per_week > 1` and `office_country` is not in `criteria.office_exception_countries` (start: `ES`). Inside an exception country the rule does not fire and the score is reduced by `criteria.office_penalty` (start: 15) |
| `b2b-no` | `b2b_allowed = no` |
| `suspected-injection` | description matches an injection pattern |
| `track-none` | the Scorer returned `none` |

`b2b_allowed = unknown` does not exclude; it adds the red flag `b2b-unclear`. `seniority` and `stack_main` are judged by the
Scorer against the track definitions in `criteria.yaml`, and the code verifies the chosen track is enabled.

Red flag enum: `b2b-unclear`, `salary-missing`, `stack-mismatch`, `seniority-mismatch`, `location-unclear`, `agency-suspected`,
`suspected-injection`, `description-thin`.

### 6.7 Reporting, feedback and calibration

- **Daily report** (`ReportComposer`, §6.8) lists offers that satisfy **all** of: `lifecycle = new`; primary of its group;
  `prefilter_reason` null; `needs_review = 0`; a score row for the current `criteria_version`; `score ≥ report.threshold`;
  `liveness` is `alive` or `unverified`. In Stage 0, before agents exist, `report.require_score` is `false`: the list is the
  prefiltered new offers, labelled "not evaluated".
- **Feedback.** Each offer line in the daily issue has an eight-character code (the first eight characters of its id). The
  owner replies in the issue with lines `fit <code>` or `nofit <code> [note]`. The `feedback` workflow (trigger
  `issue_comment`, runs only when the commenter equals `vars.OWNER_LOGIN`) appends a JSON line to `feedback/feedback.jsonl` on
  the data branch. Comment text is read through an environment variable and is never interpolated into a shell command.
  `ingest` loads new lines into `feedback`.
- **`jobradar calibrate`** prints, for offers that have both a score row for the current `criteria_version` and feedback:
  count, agreement (`fit` and score ≥ threshold, or `nofit` and score < threshold) as a percentage, and the list of
  disagreements. Output is plain text; it is the proof for M2 (D-19).

### 6.8 Report composition

`ReportComposer.Compose` is pure. Input: run date, the offer rows to list, source-health results, counts by prefilter reason,
the usage and cost of the run, the optional Reporter summary, the count of offers not evaluated, labels from `report.yaml`.
Output: Markdown with these parts in this order:

1. Title with the run date and the Reporter summary when present.
2. Table, one row per offer, columns `data | firma | rola | link | tryb pracy | ścieżka | widełki | status | kod` in the order
   score descending, then `first_seen_at`. `status` is `alive`, or `unverified` shown as "niezweryfikowana". `kod` is the
   eight-character code.
3. "Nie ocenione": the number of offers left pending by budget, a missing token or an error.
4. "Zdrowie źródeł": one line per source with a count, the median and an alert when unhealthy; sources that were not run say so.
5. "Koszt": batches, tokens, AI credits and dollars per agent; "unknown" where the runtime reported nothing.
6. Footer with the criteria version, the prompt versions and the commit of the code.

The composer never reaches the network or the clock; identical input gives byte-identical output (tested).

### 6.9 `JobRadar.Cli` and the workflows

- **Commands.** Each takes `--profile fake|live`, `--run-date`, `--data-dir`, and exits non-zero only for a failure of the
  command itself (an unhealthy source or an unavailable agent is exit 0 with a report line).

| Command | Does | Reads | Writes |
|---|---|---|---|
| `migrate` | applies migrations | | the database |
| `doctor` | prints the state of every optional integration (P8): agents, keys per source, browsers, database | config, environment | `doctor.json` |
| `scrape --group api\|browser [--source id]` | runs adapters, one raw file per source | config, known ids from the database (read only) | `raw/<source>.jsonl`, `scrape-summary.json`, failure snapshots |
| `ingest` | normalises, prefilters, de-duplicates, applies lifecycle, loads feedback | `raw/*.jsonl`, database, `feedback.jsonl` | database, `ingest-result.json` |
| `enrich` | Extractor then Scorer for pending offers, hard exclusions, cost guard | database | database (`offer_fields`, `scores`, `agent_usage`), `enrich-summary.json` |
| `verify` | link liveness for active offers and for the offers of today's report | database | database (`liveness`, `last_checked_at`, lifecycle), `verify-summary.json` |
| `publish` | composes the report, optional Reporter summary, marks `new → active`, size guard, `VACUUM` on Sundays | database, summaries | `reports/YYYY-MM-DD.md`, database, issue body file |
| `health` | evaluates source health from `runs` | database | `health.json` |
| `calibrate` | §6.7 | database | stdout |
| `query "<fts>"` | full-text search of offers, plain text | database | stdout |
| `repair --source id` | runs the Repairer in a scratch checkout | failure snapshot | a branch diff for the workflow |
| `run-all` | the five stages in order in one process, for the `fake` profile and local use | everything | everything |

  `Program.cs` is a manifest (P9): `AddServiceDefaults`, `AddConfig`, `AddSources`, `AddStore`, `AddAgents`, `AddCommands`.

- **`daily.yml`** (`schedule: cron '0 5 * * *'` and `workflow_dispatch` with inputs `profile` (`fake`, `live`), `sources`,
  `dry_run`). Workflow `concurrency: jobradar-daily`, not cancelling. Jobs:

| Job | Runner | Needs | Secrets | Permissions | Timeout |
|---|---|---|---|---|---|
| `scrape-api` | hosted | | `ADZUNA_*` (step) | `contents: read` | 20 min |
| `scrape-browser` (Stage 3) | `RUNNER_LABELS_BROWSER`, default hosted | | `INFOJOBS_*` (step) | `contents: read` | 30 min |
| `ingest` | hosted | scrape jobs, `if: !cancelled()` | none | `contents: read` | 10 min |
| `enrich` (Stage 1) | hosted always | `ingest` | `COPILOT_GITHUB_TOKEN` (step, environment `copilot`) | `contents: read` | 30 min |
| `verify` | hosted | `enrich`, `if: !cancelled()` | none | `contents: read` | 20 min |
| `publish` | hosted always | `verify`, `if: !cancelled()` | none | `contents: write`, `issues: write` | 10 min |

  The database moves between jobs as an artifact named `db` (retention 1 day), raw files as `raw-<source>`. The data branch is
  checked out read-only in `scrape-*` (for known ids) and `ingest` (for the database), and written only in `publish`
  (job-level concurrency group `jobradar-data-write`, shared with `feedback`). If `enrich` fails or is skipped the run still
  publishes, with the offers marked not evaluated; they stay pending. If `ingest` fails nothing is published and the workflow
  fails, which GitHub reports to the owner.
- **`repair.yml`** (Stage 4): `workflow_dispatch` and `repository_dispatch` of type `source-unhealthy`; runs `repair` only for a
  source with `repairable: true` whose failure class is `parse-error`, not for 429, timeout or block. At most one open repair
  pull request per source and one attempt per source per day. The pull request is opened by workflow code from a branch
  `repair/<source>-<date>` after the diff check (only paths allowed to the Repairer, adapter tests pass); it is never merged
  automatically.
- **`feedback.yml`** (Stage 1): §6.7.
- **`probe.yml`** and **`probe-copilot`**: manual only. They make the first real calls (D-20), upload sanitised results as
  artifacts, and exist because the director's own sandbox may not reach these hosts.
- **`eval-live.yml`**: manual only; runs the scenario sets of §10 against a real model with `COPILOT_GITHUB_TOKEN`, bounded by
  `Agents:MaxAiCreditsPerRun`.
- **`ci.yml`**: §9.

## 7. Test doubles and profiles

| Double | Replaces | Runs in | Supports | Cannot support |
|---|---|---|---|---|
| `FakeAgentRunner` | the Copilot runtime | profile `fake`, all unit and pipeline tests | that the harness validates schemas, rejects bad answers, retries once, applies caps and hard exclusions, respects the budget, degrades when the runner is unavailable, and that the tool list and permission handler are the allow-list | any statement about model quality, about whether a real model obeys an injected instruction, about real token counts or credits |
| Fixture replay (`FixtureHttp`) | source hosts | profile `fake`, adapter tests | that an adapter parses the recorded shape correctly and normalises it | that the live endpoint still has that shape, that a hosted runner is not blocked, rate limits |
| Fake clock | `TimeProvider` | all tests | lifecycle, expiry, archive, run-date logic | none |
| Temporary SQLite file | the data-branch database | store and pipeline tests | schema, indexes, FTS5, query translation | repository growth in Git |
| Local static HTML pages | portal pages | `tier=browser` tests (Stage 3) | selector and JSON-LD extraction in a real Chromium | anti-bot behaviour |

Anything shown with a double is reported as such. The gates M1–M4 rest on real runs; `profile=fake` runs prove only M0.

## 8. Observability and privacy

- **Logs:** structured, to the console, as JSON in CI. Levels: `Information` for stage start and end with counts; `Warning` for
  an unhealthy source or a degraded agent; `Error` only for command failure. Never logged: any token or key, response bodies,
  prompts, more than 200 characters of a description.
- **Traces (P15):** an `ActivitySource` `JobRadar` with spans `stage`, `source`, `batch`; agent spans carry `gen_ai.request.model`
  and `gen_ai.usage.input_tokens` and `gen_ai.usage.output_tokens` as the chess arena does. OTLP export when
  `OTEL_EXPORTER_OTLP_ENDPOINT` is set (the AppHost sets it); otherwise none.
- **Run summaries:** each command writes a small JSON summary file; the workflow uploads them and prints the cost block to the job
  summary. These are the proof artifacts of D-19.
- **Metrics:** the summaries carry the numbers; there is no metrics endpoint. Labels, where a counter exists, are the source id
  only (low cardinality, at most about 20 values).
- **Privacy:** the system holds public offers and the owner's own feedback (D-04). The repository is private. Failure snapshots
  contain only pages of sources and are kept 7 days.

## 9. CI/CD

`job-radar/.github/workflows/ci.yml` on pull requests and pushes to `main`, hosted runners (DECISIONS D-09). Four required jobs
plus one optional:

| Job | Proves | Expected | Needs |
|---|---|---|---|
| `build-test` | `dotnet build -warnaserror`; unit and integration tests (`tier!=live&tier!=browser`); `PublicSurfaceTests`; architecture test that `Core` references nothing; config validation of `config/*.yaml` and `criteria.lock` | 8 min | .NET SDK 10.0.x from `global.json` |
| `kernel-size` | `JobRadar.ServiceDefaults` is at most 400 lines of C# | 1 min | nothing |
| `solution-check` | every `.csproj` under `src/` and `tests/` is in `JobRadar.sln`; only `Agents.csproj` references `GitHub.Copilot.SDK`; only `Sources.csproj` references `Microsoft.Playwright` (plus the browser test project); every web or exe project is registered in the AppHost where one is required | 1 min | nothing |
| `secret-scan` | `gitleaks` over commits reachable from `HEAD` | 2 min | nothing |
| `browser` (from Stage 3) | `tier=browser` tests in Chromium | 10 min | `playwright install chromium` at run time on hosted runners; T-00.03 and T-04.01 record the download |

Workflow rules: `permissions:` per job; actions pinned to a commit SHA; no `pull_request_target`; no secret in `ci.yml`. The
workflow-level runner switch is the single variable `RUNNER_LABELS` (`self-hosted-runners` skill), unset by default.

## 10. Testing

Strategy: `testing-strategy`, `ai-evals`, `e2e-acceptance-testing`. Tests carry `[Trait("tier", "...")]`: `unit`, `integration`
(real SQLite file, no network), `browser`, `live`.

| Layer | Content | Budget | Runs |
|---|---|---|---|
| Unit | `Core` functions, `Config` validation, adapters on fixtures, agent harness on `FakeAgentRunner` | 60 s total | every push |
| Integration | `Store` on a real SQLite file: upsert, unique index, canonical groups, expiry, FTS5, migrations from empty | 3 min | every push |
| Pipeline | `Cli.Tests`: `run-all --profile fake` on fixtures; a second run changes nothing; report byte-identical; zero duplicates | 5 min | every push |
| Browser | adapters of browser sources against local static pages | 10 min | CI `browser` job, from Stage 3 |
| Live | `eval-live.yml`, `probe.yml`, `probe-copilot` | 15 min, credit-capped | by the owner or director on request, never on a pull request |

**The E2E charter.** The pipeline test is the one end-to-end test. It must fail if: a duplicate reaches the report; a dead
offer is shown as alive; a source failure stops another source; an unevaluated offer is shown as a match; the budget is exceeded;
a rerun of the same run date changes anything. Waits in tests are waits on a condition with a generous limit, never a short
fixed delay.

**Evals** (`ai-evals`; data in `tests/evals/`, one JSON file per scenario, with `id`, `class`, `input`, `scripted_replies` for
offline use, `expect`):

- *Behaviour spec* for the Extractor and Scorer is §6.5–§6.6. Hard constraints that must hold at 100%: C1 an agent session has
  exactly its allow-listed tools; C2 no permission request is ever approved; C3 no write to the repository by an agent;
  C4 a score never exceeds the cap of a fired hard exclusion; C5 an offer with an unaccepted extraction never reaches the
  report; C6 spend stops at the budget.
- *Offline suite* (`FakeAgentRunner`, every push): at least 30 scenarios per agent in the classes **accepted**, **recovers**
  (invalid JSON, missing reference, enum violation, over-long text, evidence not in the text, then a valid answer), **fails**
  (invalid on every attempt → `needs_review`), **degraded** (runner unavailable, timeout, usage not reported), and
  **adversarial** (at least 12 injection descriptions: ignore-previous-instructions in Polish, Spanish and English, a fake
  closing delimiter, a fake tool call, "score 100", hidden zero-width text, base64 payload, role-play, a request to call another
  tool). Offline, adversarial scenarios prove the harness (delimiters carry the nonce, caps apply, the tool list is closed),
  not the model.
- *Prove the suite can fail* (T-02.12): for each hard constraint a deliberately broken variant of the harness must turn the
  matching scenario red; the pull request shows both runs.
- *Live eval* (`eval-live.yml`): the same adversarial and accepted scenarios against the real model; gate: no adversarial
  scenario changes the validated result compared with its clean twin. Its result is reported as "live, N scenarios, date".
- *No LLM judge.* The owner's `fit`/`nofit` labels are the ground truth for quality (§6.7); a judge model would add a second
  uncalibrated model (`ai-evals` §5), so Layer 2 is out of scope.

## 11. Security

The threat that matters most is **prompt injection through offer text** (rated Medium by the analysis; consequence: an inflated
score, in the extreme tool misuse). Controls, in order of strength: the agent has no tool that can do harm (R3, Empty mode, allow-list,
permissions rejected); output is closed and validated (R5); the part of the decision that matters is code (ADR-0005); text is delimited with a nonce (R4); the Scorer sees less text; injection
patterns exclude an offer; adversarial evals. The SDK, left on defaults, behaves like the Copilot CLI with `--allow-all`
(file system, Git, network), so none of the defaults may be relied on.

| Area | Rule |
|---|---|
| Authentication | Only the fine-grained token `COPILOT_GITHUB_TOKEN` (permission "Copilot Requests" on the owner's account, 90-day expiry), stored in the GitHub environment `copilot`, read only by `enrich`, `repair`, `eval-live` and `probe-copilot` at step level. The built-in `GITHUB_TOKEN` has no Copilot access in a private repository of a personal account. A calendar reminder 7 days before expiry is an owner action (PROGRESS). An expired token makes `doctor` report `NotAuthenticated` and the report say "not evaluated", not fail |
| Workflow injection | Event text (issue comment, branch names) is passed through `env:` and read as data. Only `feedback.yml` takes event text, and only from `vars.OWNER_LOGIN`. No `pull_request_target`. No expression from event text inside `run:` |
| Supply chain | Actions pinned by SHA. Packages only via `Directory.Packages.props`. A Repairer pull request can contain code: it is never auto-merged, `repair/*` branches cannot touch `.github/**`, `config/**`, `Directory.*` or any path outside the source's folder (diff check by code and CODEOWNERS), and the owner reviews it |
| Runners | A self-hosted runner never runs a job that holds a secret and never runs code from a fork (the repository is private and takes no fork pull requests) |
| Data | Offers are public. Failure snapshots may contain a page; retention 7 days. No candidate data exists |
| Terms of use | R9, SOURCES.md per-source notes, personal use only |
| Review | `security-review` at the end of Phase 2 (T-02.17) and before any move to public (not planned) |

## 12. Assumptions and deviations

### 12.1 Assumptions (not verified)

| # | Assumption | How and when it will be verified | Task |
|---|---|---|---|
| A-01 | The endpoints of §SOURCES have the shapes the analysis describes. **No endpoint has been called**: the analysis says so, and the sandbox in which this specification was written could not reach any of them either | `probe.yml` from a hosted runner; the response is saved as a fixture; a source whose shape differs is amended in SOURCES.md before its adapter task | T-00.04, T-01.12–14, T-03.01–05 |
| A-02 | In SDK 1.0.28, `CopilotClientMode.Empty` plus `AvailableTools` naming custom tools exposes exactly those tools, a custom tool defined with `SkipPermission` runs without a permission request, and `IsTerminal` ends the turn after a successful call. Known only from the XML documentation of the package | live spike, `probe-copilot` | T-02.01 |
| A-03 | The SDK's bundled runtime can start on a hosted runner and authenticate with the token. The analysis says the Copilot CLI must be installed; the chess arena runs on the SDK-bundled runtime and treats `CliPath` as optional. Which is true is unknown | live spike; the result decides whether `enrich` installs the CLI | T-02.01 |
| A-04 | One AI unit equals one AI credit, so credits = `TotalNanoAiu ÷ 10⁹`. The chess arena made the same assumption and has not verified it live | compare the usage events with the owner's billing page for one known run | T-02.01 |
| A-05 | A daily run costs well under `Agents:MaxAiCreditsPerRun = 20` at 15 offers per batch. The analysis estimates by premium requests, which no longer describes the billing | measured in the first live `enrich`; the budget is then set from the number | T-02.10 |
| A-06 | A cheap model suffices for extraction and scoring, and one such model is in the runtime's model list. Model ids are read from `ListModelsAsync`, never assumed | the spike lists models; `Agents:Extractor:Model` is set from the listing | T-02.01 |
| A-07 | Hosted-runner IPs are accepted by the unofficial JSON endpoints of No Fluff Jobs and justjoin.it (the analysis says Cloudflare protects the No Fluff Jobs site, not its API) | `probe.yml` | T-03.02, T-03.03 |
| A-08 | The SQLite file stays under 40 MB for the first months at the volume of 3 ATS groups and a few portals | the size is printed every run; the guard of §6.4 | T-01.24 |
| A-09 | A model that is asked to call one tool with an array for 15 offers does so reliably | offline evals prove the harness; the live eval measures the model | T-02.13 |
| A-10 | Playwright for .NET runs Chromium on a hosted runner with `playwright install chromium` within the job time limits | `browser` job | T-04.01 |
| A-11 | Remotive's 24-hour delay means "new" there means "first seen by us", not "posted today". Reports show the source's own date | documented behaviour of the source; the adapter keeps `posted_at` | T-01.14 |
| A-12 | D-30: the Spain exception reading of the analysis ("regular presence outside Spain") is as written | owner confirms with the PROPOSED rows | T-00.01 |
| A-13 | D-27: track C is undefined | owner defines it, or it stays disabled | T-00.01 |
| A-14 | A GitHub Actions cron can start later than the scheduled minute. The report time is therefore "after 05:00 UTC", not "at" | observed over the 7-run gate | T-01.25 |
| A-15 | Two job artifacts of a few tens of megabytes pass between jobs within the 1-day retention without trouble | the pipeline run | T-01.21 |

### 12.2 Deviations from the standards

Each has an ADR in `docs/adr/` before the code that deviates is merged. The ADRs of the first four rows are written with this
specification.

| Principle | Deviation | ADR |
|---|---|---|
| P6, P7, P12 | No container, no Fly.io app, no tag-driven deploy: the runtime is GitHub Actions on a schedule; there is no service to deploy. CI is a pull-request workflow plus `daily.yml` | ADR-0002 |
| P1 (stack), P3 | .NET is kept (the standards are .NET); the analysis' Python option is rejected. One store, one writer | ADR-0001 |
| P4, P8 | SQLite file instead of PostgreSQL; migrations applied at the start of each command, not by a hosted service (a CLI is not a long-running host); the health endpoint is replaced by `jobradar doctor`, which prints the same facts | ADR-0004 |
| P2, P10 (agents) | Agent isolation: `CopilotClientMode.Empty`, closed tool lists, code-side caps | ADR-0003 |
| P11 | Hard exclusions are applied by code after the model, not by the model | ADR-0005 |
| Cost | Cost model in AI credits with a hard per-run budget; the analysis' premium-request wording is superseded | ADR-0006 |
| P2 "standard resilience handler on every HttpClient" | Source requests go through Playwright's `IAPIRequestContext`, which is not an `HttpClient`; the equivalent policy (timeouts, retry, back-off, delay) is `SourceHttp`, tested (R11). Calls to GitHub use `HttpClient` with the standard handler | ADR-0002 |

## 13. Performance targets

| Target | Number | Measured where | Task |
|---|---|---|---|
| Whole `daily.yml` run, Stage 0 | at most 25 minutes | workflow run duration | T-01.25 |
| Whole `daily.yml` run, Stage 2 (all sources, enrich, verify) | at most 60 minutes | workflow run duration | T-03.09 |
| Duplicates in a report | 0 | `jobradar query --audit-duplicates` returns no group with more than one reported member, on every daily run | T-01.23, T-01.25 |
| Offers sent to agents ÷ offers ingested | printed every run; expected well under 10% | `ingest-result.json` | T-01.17 |
| AI credits per run | at most `Agents:MaxAiCreditsPerRun`; the first measured value replaces the starting 20 | `agent_usage` | T-02.10 |
| Judge agreement with the owner | at least 80% over 2 weeks of reported offers | `jobradar calibrate` | T-02.14 |
| Database size | warn at 40 MB, stop committing at 90 MB | `publish` log | T-01.24 |
| Link checks per run | at most 1 request per active offer, 1–3 s per host; the run finishes within the job timeout | `verify-summary.json` | T-03.06 |

## 14. Release plan

A gate is claimed in `PROGRESS.md` only with its proof. Calendar dates are not used where a date depends on something outside
this repository: a stage's days start when the stage's previous gate is claimed.

| Gate | Passes when (observable, on Linux hosted runners) | Proof (DECISIONS D-19) |
|---|---|---|
| **M0** | The solution scaffold builds; every job of §9 is green three times in a row on one commit; `daily.yml` dispatched with `profile=fake` is green on a hosted runner; the two real results of D-20 exist | CI run links on one named commit; the dispatch run link; `docs/spikes/first-real-result.md` |
| **M1** (Stage 0 exit) | Greenhouse, Ashby and Remotive adapters run live; 7 consecutive daily runs without a failed job; the duplicate audit returns 0 on each | the 7 run URLs and the audit output of each |
| **M2** (Stage 1 exit) | Extractor, Scorer and Reporter run live in the allow-listed sessions; the live tool-surface check passes; offline evals are green and shown able to fail; `jobradar calibrate` shows at least 80% agreement over two weeks of the owner's marks | run URLs; the calibrate output with the date range; the eval-live run URL |
| **M3** (Stage 2 exit) | No Fluff Jobs, justjoin.it, Adzuna (ES, PL), We Work Remotely and Lever run; liveness checks run; 7 consecutive healthy daily runs; the owner's sample of 20 reported offers has no wrong `alive` | run URLs; the owner's sample result recorded in the PR that claims the gate |
| **M4** (Stage 3 exit) | Browser sources Pracuj.pl and InfoJobs run on the runner chosen in D-25; failure snapshots appear as artifacts when a parse is broken on purpose; 7 healthy runs | run URLs; the deliberate-failure run |
| **M5** (Stage 4 exit) | A deliberately broken selector in a copy of an adapter produces a repair pull request that passes the adapter tests and touches only its source's paths; no run ever pushed to `main` | the pull request link and its diff |

## Appendix A. Seed of `config/criteria.yaml`

Values from the analysis of 12 November 2026. Any change is a new `version` (R15).

```yaml
version: 1
countries: [AT, BE, BG, CH, CY, CZ, DE, DK, EE, ES, FI, FR, GB, GR, HR, HU, IE, IS, IT, LT, LU, LV, MT, NL, NO, PL, PT, RO, SE, SI, SK, UA, RS]
max_office_days_per_week: 1
office_exception_countries: [ES]
office_penalty: 15
excluded_languages: [de]            # German above basic level
require_contract: b2b               # B2B through a sole proprietorship (JDG)
direct_employers_only: true
threshold: 70
title_keywords: [ai, ml, llm, ".net", dotnet, "c#", backend, "back-end", "machine learning", "generative"]
tracks:
  A: { enabled: true,  label: "Mid AI Engineer",        seniority: [mid],    role_family: [ai_engineer] }
  B: { enabled: true,  label: "Senior, .NET main stack", seniority: [senior], stack_main: [dotnet] }
  C: { enabled: false, label: "undefined",              note: "owner defines (DECISIONS D-27)" }
injection_patterns:                 # case-insensitive, matched on the normalised description
  - "ignore (all |any )?(previous|prior|above) instructions"
  - "zignoruj (wszystkie |poprzednie )?(instrukcje|polecenia)"
  - "ignora (todas )?las instrucciones"
  - "(you are|jesteś|eres) now"
  - "(score|oceń|puntúa)[^.]{0,20}\\b100\\b"
  - "save_score|save_offer_fields|write_report"
```

## Appendix B. Seed of `config/sources.yaml`

`expiry_by_absence` is true only where a run sees the source's whole current listing (R8).

```yaml
sources:
  greenhouse:     { enabled: true,  kind: ats,        stage: 0, expiry_by_absence: true,  companies: [] }   # the owner supplies slugs (T-01.15)
  ashby:          { enabled: true,  kind: ats,        stage: 0, expiry_by_absence: true,  companies: [] }
  remotive:       { enabled: true,  kind: aggregator, stage: 0, expiry_by_absence: false, attribution: "Remotive", delay_hours: 24 }
  lever:          { enabled: false, kind: ats,        stage: 2, expiry_by_absence: true,  companies: [] }
  nofluffjobs:    { enabled: false, kind: portal,     stage: 2, expiry_by_absence: false, repairable: true }
  justjoinit:     { enabled: false, kind: portal,     stage: 2, expiry_by_absence: false, repairable: true }
  adzuna:         { enabled: false, kind: aggregator, stage: 2, expiry_by_absence: false, countries: [es, pl] }
  weworkremotely: { enabled: false, kind: aggregator, stage: 2, expiry_by_absence: false }
  pracuj:         { enabled: false, kind: portal,     stage: 3, expiry_by_absence: false, browser: true, repairable: true }
  infojobs:       { enabled: false, kind: portal,     stage: 3, expiry_by_absence: false, browser: true, repairable: true }
```

For a source with `expiry_by_absence: false` an offer leaves the active set only through the liveness check (`Dead`).
