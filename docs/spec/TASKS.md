# JobRadar — Phases and atomic tasks

> Companion to [`SPEC.md`](SPEC.md). Execution protocol: [`SUPERVISOR.md`](SUPERVISOR.md) (the director's rules; §10 is about
> Haiku 5.5 implementers).
>
> Every task is sized for **one sub-session, one branch, one pull request in `job-radar`**: at most about 250 changed lines
> (the implementer is a small model; the template's 400 is too much), one project, no design decisions left open. A task is done
> when its **Accept** criteria hold and its **Verify** command passes in CI, not when the code is written.

## How to read a task

```
### T-PP.NN Title
- Executor: implementer | supervisor | owner     who does it (owner = a person; an agent cannot)
- Milestone: M0 | M1 | M2 | M3 | M4 | M5
- Depends: task ids that must be merged first, or —
- Read: SPEC sections and standards skills to load before editing
- Files: paths it may create or modify (anything else is out of scope)
- Do: the work, as numbered steps
- Accept: observable conditions, each one testable
- Verify: the command CI runs and the sub-session runs before opening the PR
```

`scripts/check-spec.sh` fails when a task block lacks one of these eight fields or when two tasks share an id.

Paths are in the **application repository `job-radar`** unless a task says otherwise. Skills named in `Read` are skills of
`architecture-standards` (`reference-architecture`, `repo-baseline`, `testing-strategy`, `ai-evals`, `security-review`,
`self-hosted-runners`, `implementation-phase`, ...). Every implementation task follows `implementation-phase`.

Common **Verify** for a .NET task unless the task says otherwise:

```bash
dotnet build JobRadar.sln -warnaserror && dotnet test JobRadar.sln --filter "tier!=live&tier!=browser"
```

Rules for writing and running tasks:

- **Shared files are supervisor-only:** `Directory.Packages.props`, `JobRadar.sln`, every `.csproj`, `.github/workflows/**`,
  `src/JobRadar.AppHost/**`, `config/criteria.lock`, and the contracts frozen in T-01.01. T-00.03 creates every project and test
  project, so an implementer adds `.cs`, `.yaml`, `.json` and `.md` files only. A needed package, project reference or workflow
  change is requested in the PR description.
- **Test names are given in `Accept`.** The implementer creates a test with exactly that name (the method name) so the director
  can check it by name.
- **Public signatures are given in `Do`** wherever SPEC gives them. Where a signature is not given, the implementer follows SPEC
  names and asks in "Blocked: question for director" rather than inventing one.
- **Executor `owner`** marks what only a person can do. They are collected early.
- **A spike** produces a note under `docs/spikes/` with exact versions. If skipped, the task is replaced by a row in SPEC §12.1.
- **Accept criteria name their proof**: a test name, a command with its expected output, or a CI job.

---

## Phase 0 — Ground truth before code

Fixed, never parallel (SUPERVISOR §3).

### T-00.01 Owner decisions recorded
- Executor: owner · Milestone: M0 · Depends: —
- Read: `DECISIONS.md`
- Files: `docs/spec/DECISIONS.md` (this repository)
- Do: 1) Answer the director's single message about every PROPOSED row (D-08, D-13–D-18, D-21–D-24, D-27, D-28, D-30) and the open rows D-25, D-29. 2) The director records the answers and the date in the decision log. 3) Set `Status: decided`.
- Accept: no PROPOSED mark left; status line reads `Status: decided`; D-14 names the models.
- Verify: `scripts/check-spec.sh`

### T-00.02 Repository, settings and the Copilot token
- Executor: owner · Milestone: M0 · Depends: T-00.01
- Read: DECISIONS D-09–D-13; SPEC §11; `repo-baseline`
- Files: — (GitHub settings)
- Do: 1) Create the private repository `job-radar` (empty, default branch `main`). 2) Automatically delete head branches. 3) Secret scanning and code scanning on. 4) Branch protection on `main` with the four required checks of SPEC §9 (they will not exist until T-00.03; add them then). 5) Repository variable `OWNER_LOGIN` = the owner's GitHub login. 6) Create the GitHub environment `copilot`. 7) Create a fine-grained personal access token on the owner's account with only the permission "Copilot Requests", 90 days, and store it as the environment secret `COPILOT_GITHUB_TOKEN`. Put a calendar reminder 7 days before expiry. 8) Attach `job-radar` to the director's session.
- Accept: each setting is visible in the repository settings; the secret is listed in the environment (its value is never shown); a manually dispatched workflow on `main` starts (T-00.03 provides one).
- Verify: the owner confirms in the PR that closes this task. Settings and secrets are not readable by CI or by an agent.

### T-00.03 Scaffold and empty pipeline green
- Executor: supervisor · Milestone: M0 · Depends: T-00.02
- Read: SPEC §3, §4, §9, §12.2; `reference-architecture` P1, P2, P9; `repo-baseline`; `self-hosted-runners` §1
- Files: the whole scaffold of `job-radar` (see Do)
- Do: 1) Create `global.json` (SDK 10.0.x), `Directory.Build.props` (nullable, warnings as errors, analysers), `Directory.Packages.props`, `.editorconfig`, `JobRadar.sln`. 2) Create every project and test project of SPEC §3.2 with only the references and packages of the SPEC §3.2 tables, each with a placeholder public type so it builds, and a manifest `Program.cs` in `JobRadar.Cli` with the command skeleton. Registration is by convention so implementers never edit wiring: `AddSources` registers every public non-abstract `IJobSource` of the `Sources` assembly, `AddCommands` every `ICliCommand` of the `Cli` assembly, `AddStores` every repository of the `Store` assembly, and `IngestStage` receives all registered `IIngestHook`s. 3) `ServiceDefaults` with logging format and OpenTelemetry. `AppHost` starts `JobRadar.Cli`. 4) `scripts/check-kernel-size.sh`, `scripts/check-solution.sh` (SPEC §9 rules), `scripts/setup-hooks.sh` with a secret-scan pre-commit hook. 5) `ci.yml` with the four jobs of SPEC §9, `permissions` per job, actions pinned by SHA. 6) A `daily.yml` containing five jobs that each run `echo` for now, with `workflow_dispatch` only (no `schedule`), so the settings check of T-00.02 can dispatch it. 7) `AGENTS.md` and `README.md` for `job-radar` pointing to the specification repository. 8) `docs/operations/CI.md`: per job duration, what it downloads at run time, what it needs from the runner. 9) Copy the pull-request template of this specification repository to `.github/pull_request_template.md`. 10) Add the `PublicSurfaceTests` skeleton (empty assertion list that fails if `GitHub.Copilot.SDK` is referenced outside `Agents`).
- Accept: every pull-request job is green **three times in a row on one commit**; the recorded table is in `docs/operations/CI.md`; `daily.yml` dispatched on a hosted runner is green; `scripts/check-solution.sh` fails when a project is left out of the solution (shown once, then reverted).
- Verify: links to the three runs and the dispatch run in the PR description.

### T-00.04 First vertical slice against the real things
- Executor: supervisor · Milestone: M0 · Depends: T-00.03
- Read: SPEC §7, §12.1 A-01–A-04, A-06; DECISIONS D-20; `COPILOT-SDK.md` §3–§4; `ai-evals` §4 (trace assertions)
- Files: `.github/workflows/probe.yml`, `.github/workflows/probe-copilot.yml`, `src/JobRadar.Sources/Probe/**`, `src/JobRadar.Agents/Spike/**`, `tests/fixtures/greenhouse/**`, `docs/spikes/**`, `docs/spec` amendments (specification repository)
- Do: 1) `probe.yml` (`workflow_dispatch`): from a hosted runner call one real Greenhouse board (a slug the owner names), save the response trimmed to 5 postings as a fixture and as an artifact, record status code and content type. Repeat for one Ashby board, Remotive, Lever, We Work Remotely, No Fluff Jobs and justjoin.it: one request each, no loops. 2) `probe-copilot.yml` is NOT run in CI (D-20, amended 2026-11-13): write the spike program (`src/JobRadar.Agents/Spike/**`, a console entry point `jobradar-spike` the owner runs locally with their own `COPILOT_GITHUB_TOKEN`); it should start `CopilotClient` in `CopilotClientMode.Empty`, list models, create one session with one custom tool and a rejecting permission handler, ask it to call the tool with a fixed argument, print the events, the usage and the credits, then ask it to run a shell command and print what happened; a `--fake` flag runs it on `FakeAgentRunner`-like scripted events so CI proves the program itself works. The program that starts `CopilotClient` in `CopilotClientMode.Empty`, lists models, creates one session with one custom tool and a rejecting permission handler, asks it to call the tool with a fixed argument, prints the events, the usage and the credits, then asks it to run a shell command and prints what happened. 3) Write `docs/spikes/first-real-result.md` with both results, the exact SDK version, and the answers to the eight open questions of `COPILOT-SDK.md` §4. 4) Amend SOURCES.md and COPILOT-SDK.md (in the specification repository) with every difference found; update SPEC §12.1 rows A-01–A-04, A-06.
- Accept: a real Greenhouse response is saved as a fixture; the spike program builds and its `--fake` run is green in CI (a real Copilot result is T-00.05); credits read from the usage event are in the note, compared with the owner's billing page if the owner supplies it; each probed source has a verdict (works / differs / blocked); the tool-surface answer (question 5) is written down, whatever it is.
- Verify: the probe run URL; the CI run of the spike's `--fake` mode.

### T-00.05 Real Copilot session, run locally
- Executor: owner · Milestone: M0 · Depends: T-00.04
- Read: DECISIONS D-20; `COPILOT-SDK.md` §3–§4; the spike program from T-00.04
- Files: `docs/spikes/first-real-result.md` (via the director)
- Do: 1) On the owner's machine, with their Copilot-enabled account and a token in `COPILOT_GITHUB_TOKEN` (never committed, never pasted in chat), run the spike program as documented in its README. 2) Send the full console output to the director, with the credits shown on the owner's billing page for that run if visible. 3) The director writes `docs/spikes/first-real-result.md` and amends COPILOT-SDK.md and SPEC §12.1 A-02–A-04, A-06 from it.
- Accept: the note holds the real output, the exact SDK version, and the answers to the eight questions of `COPILOT-SDK.md` §4, whatever they are.
- Verify: the owner confirms the output is theirs and unedited.

---

## Phase 1 — Stage 0: the core without agents (milestone M1)

Exit: 7 consecutive daily runs without a failed job; duplicate audit 0 on each.

### T-01.01 Contracts frozen
- Executor: supervisor · Milestone: M1 · Depends: T-00.04
- Read: SPEC §6.1, §6.3, §6.4, §6.5, Appendix A
- Files: `src/JobRadar.Core/Models/**`, `src/JobRadar.Core/Ports/**`, `src/JobRadar.Agents/Contracts/**`, `docs/architecture/contracts.md`
- Do: 1) Write the records and enums of SPEC §6.1 and §6.4 (`RawOffer`, `OfferFields`, `ScoreResult`, `Offer`, `SourceKind`, `Lifecycle`, `Liveness`, `WorkMode`, `Track`, `SourceHealth`, `DiscoveredOffer`, `RawDetail`, `SourceContext`), the criteria records of Appendix A (`Criteria`, `TrackDefinition`), `IJobSource`, `IOfferStore`, `IKnownOffers`, `IReportSink`, `IIngestHook` (`Task RunAsync(IngestContext, CancellationToken)`, run by `ingest` after the upsert; T-02.14 adds the feedback loader as one) and `ICliCommand`. 2) `IAgentRunner`, `AgentRequest`, `AgentTool`, `AgentToolResult`, `AgentRun`, `AgentUsage`, `AgentRunnerStatus`, tool-argument records for the four tools. 3) `RawOffer` JSON shape documented in `docs/architecture/contracts.md` with one example line. 4) Contracts compile with no behaviour. After this task they change only by director decision.
- Accept: solution builds; every enum value of SPEC §6.4 exists; `RawOfferJsonTests.Roundtrip_keeps_every_field` passes.
- Verify: common verify

### T-01.02 Core: ids and hashes
- Executor: implementer · Milestone: M1 · Depends: T-01.01
- Read: SPEC §6.1 (the `OfferId` and `DescriptionHash` rows)
- Files: `src/JobRadar.Core/Identity/OfferId.cs`, `src/JobRadar.Core/Identity/DescriptionHash.cs`, `tests/JobRadar.Core.Tests/IdentityTests.cs`
- Do: 1) `public static class OfferId { public static string Of(string source, string sourceId) }` per SPEC. 2) `public static class DescriptionHash { public static string Of(string text) }` per SPEC: trim, collapse whitespace runs to one space, NFC, SHA-256, lowercase hex.
- Accept: `OfferId_is_32_lowercase_hex`; `OfferId_differs_for_swapped_arguments`; `OfferId_known_vector` (a value computed independently and written in the test); `DescriptionHash_ignores_whitespace_differences`; `DescriptionHash_changes_when_a_word_changes`; `DescriptionHash_treats_nfc_and_nfd_alike`.
- Verify: common verify

### T-01.03 Core: normaliser and canonical key
- Executor: implementer · Milestone: M1 · Depends: T-01.01
- Read: SPEC §6.1 (`Normalizer`, `CanonicalKey`), §6.4 duplicates
- Files: `src/JobRadar.Core/Identity/Normalizer.cs`, `src/JobRadar.Core/Identity/CanonicalKey.cs`, `tests/JobRadar.Core.Tests/NormalizerTests.cs`, `tests/JobRadar.Core.Tests/CanonicalKeyTests.cs`
- Do: 1) `Normalizer.Company(string)` and `Normalizer.Title(string)` exactly as the SPEC table. 2) `CanonicalKey.Of(string company, string title, string? country)`. 3) Tests are table-driven: at least 12 company pairs (for example `"Acme Sp. z o.o."` and `"ACME"`, `"Zürich Tech GmbH"` and `"zurich tech"`) and 12 title pairs (`"Senior .NET Developer (m/f/d)"` and `"senior .net developer"`), plus 6 pairs that must **not** match (`"Senior"` vs `"Junior"` titles; `"AI Engineer"` vs `"AI Engineering Manager"`).
- Accept: `Company_equivalent_forms_match`; `Title_equivalent_forms_match`; `Title_level_words_are_kept`; `CanonicalKey_uses_xx_when_country_is_null`; `CanonicalKey_differs_across_countries`.
- Verify: common verify

### T-01.04 Core: lifecycle state machine
- Executor: implementer · Milestone: M1 · Depends: T-01.01
- Read: SPEC §6.4 "Lifecycle machine"
- Files: `src/JobRadar.Core/Lifecycle/LifecycleMachine.cs`, `tests/JobRadar.Core.Tests/LifecycleMachineTests.cs`
- Do: 1) `public enum LifecycleEvent { Seen, Published, Missed, MissedThrice, Dead, Aged }`. 2) `public static class LifecycleMachine { public static LifecycleResult Next(Lifecycle state, LifecycleEvent e) }` where `LifecycleResult` is `Ok(Lifecycle next)` or `Invalid(string reason)`, never an exception. 3) Encode the table of SPEC §6.4 exactly; every pair not in the table is `Invalid` except `Seen` on a state that stays unchanged.
- Accept: one test per table row, named `Row_<from>_<event>_<to>`; `Every_pair_is_either_ok_or_invalid` (loops over all 4×6 combinations); `Archived_never_leaves_archived`.
- Verify: common verify

### T-01.05 Core: prefilter
- Executor: implementer · Milestone: M1 · Depends: T-01.01, T-01.03
- Read: SPEC §6.6 stage 1; Appendix A
- Files: `src/JobRadar.Core/Filtering/Prefilter.cs`, `tests/JobRadar.Core.Tests/PrefilterTests.cs`
- Do: 1) `public static class Prefilter { public static PrefilterResult Evaluate(RawOffer offer, Criteria criteria, IReadOnlySet<string> blocklist) }`; `PrefilterResult` is `Pass` or `Reject(string reasonId)` with the five reason ids of SPEC. 2) Title keywords match on the normalised title, whole token or the exact `.net`/`c#` forms; `ai` must not match inside `maintain`. 3) The blocklist is already normalised company names.
- Accept: one passing and one rejecting test per reason id; `Title_keyword_ai_does_not_match_inside_words`; `Hybrid_without_days_passes`; `Unknown_country_passes`; `Reasons_are_checked_in_the_documented_order`.
- Verify: common verify

### T-01.06 Config: sources and criteria loaders, validation, lock
- Executor: implementer · Milestone: M1 · Depends: T-01.01
- Read: SPEC §6.2, Appendices A and B; SOURCES §2
- Files: `src/JobRadar.Config/Loading/**`, `src/JobRadar.Config/Validation/**`, `config/sources.yaml`, `config/criteria.yaml`, `config/criteria.lock`, `scripts/make-criteria-lock.sh`, `tests/JobRadar.Config.Tests/ConfigLoaderTests.cs`, `tests/JobRadar.Config.Tests/CriteriaLockTests.cs`
- Do: 1) `ConfigError(string File, string Path, string Rule)` and `ConfigResult<T>(T? Value, IReadOnlyList<ConfigError> Errors)`; `ConfigLoader.LoadSources(path)` and `ConfigLoader.LoadCriteria(path)` returning immutable `Core` types (`SourceConfig` list, `Criteria`) inside a `ConfigResult`, errors naming file, path and rule. 2) Validation rules of SPEC §6.2: unknown keys, source id pattern, forbidden ids `linkedin` and `indeed` with a message citing D-03, slug pattern, positive integer version, thresholds, track letters. 3) `CriteriaLock.Check(criteriaPath, lockPath)`: SHA-256 of the file against the lock; the lock file format is two lines `version: N` and `sha256: <hex>`. 4) Write the seed files `config/sources.yaml` and `config/criteria.yaml` from SPEC Appendices B and A. 5) `scripts/make-criteria-lock.sh` writes `config/criteria.lock` from `config/criteria.yaml` (version read from the file); run it and commit the lock. (T-01.26 adds the blocklist and report loaders; split from this task on 2026-11-13 because the original task exceeded the size limit.)
- Accept: `Seed_files_load_without_errors`; `Unknown_key_is_an_error_naming_the_path`; `Linkedin_source_is_refused_citing_D03`; `Indeed_source_is_refused_citing_D03`; `Lock_mismatch_fails_when_content_changed_but_version_did_not`; `Lock_ok_when_version_and_hash_both_changed`.
- Verify: common verify

### T-01.07 Store: schema, first migration, FTS5
- Executor: implementer · Milestone: M1 · Depends: T-01.01
- Read: SPEC §6.4 (tables and migrations); `reference-architecture` P4
- Files: `src/JobRadar.Store/Model/**`, `src/JobRadar.Store/JobRadarDbContext.cs`, `src/JobRadar.Store/Migrations/**`, `src/JobRadar.Store/Migrate.cs`, `tests/JobRadar.Store.Tests/SchemaTests.cs`
- Do: 1) EF Core entities and mappings for `offers`, `offer_fields`, `scores`, `runs`, `agent_usage`, `feedback` with the exact column names, keys, uniqueness and indexes of SPEC §6.4 (`UNIQUE(source, source_id)`, index on `canonical_key`, `lifecycle`). 2) The first migration created with `dotnet ef`. 3) A second migration whose `Up` creates `offers_fts` (FTS5, external content over `offers(title, company, description)`) and the three triggers via `migrationBuilder.Sql`; `Down` drops them. 4) `Migrate.RunAsync(string dbPath)` applies migrations to a file path.
- Accept: `Migrations_apply_to_an_empty_file`; `Unique_source_pair_is_enforced`; `Fts_finds_an_inserted_offer_by_title_word`; `Fts_reflects_an_update`; `Fts_reflects_a_delete`; `Migrations_are_idempotent_when_run_twice`. All on a real SQLite file in a temp folder, never the InMemory provider.
- Verify: common verify

### T-01.08 Store: upsert and change detection
- Executor: implementer · Milestone: M1 · Depends: T-01.07, T-01.02
- Read: SPEC §6.4 "Duplicates" (within a source), lifecycle table row `Seen`
- Files: `src/JobRadar.Store/Repositories/OfferUpsert.cs`, `tests/JobRadar.Store.Tests/OfferUpsertTests.cs`
- Do: 1) `OfferUpsert.UpsertAsync(IReadOnlyList<RawOffer> offers, DateOnly runDate)` returning counts `New`, `Changed`, `Unchanged` and the ids of new and changed offers. 2) A first sighting inserts with `lifecycle = new`, `first_seen_at = last_seen_at = runDate`, `missed_runs = 0`, `liveness = unknown`, `description_hash` computed, `canonical_key` computed (T-01.03), `id` (T-01.02). 3) A repeat updates only `last_seen_at`, resets `missed_runs`, and moves `expired → active`. 4) A repeat with a different `description_hash` also replaces the description and reports the offer as changed. 5) The whole call is one transaction.
- Accept: `First_sighting_inserts_a_new_offer`; `Repeat_updates_only_last_seen`; `Repeat_after_expiry_reactivates`; `Changed_description_is_reported_changed`; `Same_batch_twice_gives_identical_rows`; `A_failing_row_rolls_back_the_batch`.
- Verify: common verify

### T-01.09 Store: canonical groups and primary choice
- Executor: implementer · Milestone: M1 · Depends: T-01.08
- Read: SPEC §6.4 "Duplicates" (across sources)
- Files: `src/JobRadar.Store/Repositories/CanonicalGroups.cs`, `tests/JobRadar.Store.Tests/CanonicalGroupsTests.cs`
- Do: 1) `CanonicalGroups.RecomputeAsync(IReadOnlyCollection<string> canonicalKeys)`: for each key, choose the primary by the rule of SPEC (highest `SourceKind`, then earliest `first_seen_at`, then smaller `id`), set `primary_offer_id` NULL on it and the primary's id on the others. 2) `SourceKind` is looked up through an `ISourceKinds` interface (`Core` port) so `Store` does not read config.
- Accept: `Ats_beats_portal_beats_aggregator`; `Tie_goes_to_earliest_first_seen`; `Second_tie_goes_to_smaller_id`; `Single_offer_is_its_own_primary`; `Recompute_is_idempotent`; `A_new_better_source_takes_over_the_primary`.
- Verify: common verify

### T-01.10 Store: expiry, archive, runs
- Executor: implementer · Milestone: M1 · Depends: T-01.08, T-01.04
- Read: SPEC §6.4 (lifecycle, retention, `runs`), R8
- Files: `src/JobRadar.Store/Repositories/Expiry.cs`, `src/JobRadar.Store/Repositories/Runs.cs`, `tests/JobRadar.Store.Tests/ExpiryTests.cs`, `tests/JobRadar.Store.Tests/RunsTests.cs`
- Do: 1) `Expiry.RecordMissedAsync(string source, IReadOnlySet<string> seenSourceIds, bool sourceHealthy, bool expiryByAbsence, DateOnly runDate)`: when healthy and expiry-by-absence, `missed_runs += 1` for active or new offers of the source not seen; at 3 → `expired`, `expired_at = runDate`. When not healthy or not expiry-by-absence, nothing changes. 2) `Expiry.MarkDeadAsync(string offerId, DateOnly)`. 3) `Expiry.ArchiveAsync(DateOnly runDate, int afterDays)`: expired longer than `afterDays` → `archived` and `description` set to empty. Use `LifecycleMachine`. 4) `Runs.RecordAsync(...)` and `Runs.LastHealthyCountsAsync(string source, int take)` returning the last `take` healthy offers-found values.
- Accept: `Healthy_source_missing_three_times_expires_the_offer`; `Unhealthy_source_never_expires_offers`; `Source_without_expiry_by_absence_never_expires_offers`; `Seen_again_resets_missed_runs`; `Archive_purges_the_description`; `Archive_waits_for_the_age`; `LastHealthyCounts_skips_unhealthy_runs`.
- Verify: common verify

### T-01.11 Sources: HTTP policy, fixture replay, robots guard
- Executor: implementer · Milestone: M1 · Depends: T-01.01
- Read: SPEC §5 R9, R11, §6.3; `service-api-patterns` (hardened outbound calls)
- Files: `src/JobRadar.Sources/Http/PolicySourceHttp.cs`, `src/JobRadar.Sources/Http/IRawHttp.cs`, `src/JobRadar.Sources/Http/FixtureSourceHttp.cs`, `src/JobRadar.Sources/Http/RobotsGuard.cs`, `tests/JobRadar.Sources.Tests/HttpTests/**`
- Do: (split on 2026-11-13: the Playwright transport is T-01.27.) 1) `ISourceHttp`, `HttpResult` and `ISourceLog` already exist in `JobRadar.Core.Ports` (T-01.01). Define in Sources `IRawHttp { Task<HttpResult> SendAsync(RawHttpRequest request, CancellationToken ct); }` with `RawHttpRequest(HttpMethodKind Method, Uri Url, string? ContentType, string? Body, string UserAgent, TimeSpan Timeout)` and `enum HttpMethodKind { Get, Post }`: one network attempt, no policy. 2) `PolicySourceHttp : ISourceHttp` wrapping an `IRawHttp` and an `IDelay` (`Task DelayAsync(TimeSpan, CancellationToken)`, a test double replaces it), implementing the policy of SPEC R9 and R11: User-Agent `JobRadar/1.0 (personal use)`, a per-host random delay of 1–3 s before each request to a host after the first (the random source is injected as `Func<double>` returning 0..1), at most 3 hosts at once, 30 s request timeout passed to the transport, 2 retries with back-off 2 s then 8 s on status 429 and 5xx and on a transport exception, honouring `Retry-After` (seconds) up to 60 s, a request counter per host; GET only is retried, a POST is never retried. 3) `FixtureSourceHttp : ISourceHttp` serving files from a folder by a mapping `url → file`, failing loudly (an exception naming the url) for an unmapped url. 4) `RobotsGuard.IsAllowedAsync(Uri, ISourceHttp)` parsing `User-agent: *` rules (Allow, Disallow, longest match), caching per host; an unreachable `robots.txt` allows.
- Accept: `Retries_on_503_twice_then_fails`; `Does_not_retry_on_404`; `Honours_retry_after_up_to_the_cap`; `Post_is_never_retried`; `Delay_is_applied_between_requests_to_one_host`; `Never_more_than_three_hosts_at_once`; `Fixture_http_fails_on_unmapped_url`; `Robots_longest_match_wins`; `Robots_unreachable_allows`. The delay and retry tests use an injected fake delay and a fake `IRawHttp`; none calls the network.
- Verify: common verify

### T-01.27 Sources: Playwright transport
- Executor: implementer · Milestone: M1 · Depends: T-01.11
- Read: SPEC §5 R9, R11, §6.3; T-01.11 (`IRawHttp`, `RawHttpRequest`)
- Files: `src/JobRadar.Sources/Http/PlaywrightRawHttp.cs`, `tests/JobRadar.Sources.Tests/HttpTests/PlaywrightRawHttpTests.cs`
- Do: `PlaywrightRawHttp : IRawHttp, IAsyncDisposable` using Playwright's `IAPIRequestContext` (HTTP only, no browser): one context per instance, the request's User-Agent and timeout applied, GET and POST (the body with the given content type), the response mapped to `HttpResult(status, content type, body text, headers lower-cased)`; a non-2xx status is a result, not an exception; a transport failure throws.
- Accept: `Get_returns_status_body_and_content_type`; `Post_sends_the_body_and_content_type`; `Non_success_status_is_a_result_not_an_exception`; `User_agent_is_sent`; `Timeout_is_applied`. Tests run against a tiny in-process `HttpListener` on a loopback port (no internet).
- Verify: common verify

### T-01.12 Sources: Greenhouse adapter
- Executor: implementer · Milestone: M1 · Depends: T-01.11, T-01.28, T-00.04
- Read: SPEC §6.3; SOURCES §3 and §4 (Greenhouse); the fixtures and notes of T-00.04
- Files: `src/JobRadar.Sources/Greenhouse/**`, `tests/JobRadar.Sources.Tests/GreenhouseTests.cs`
- Do: 1) `GreenhouseSource : IJobSource` (`Id = "greenhouse"`, `Kind = Ats`) taking the company slugs from the source config; `DiscoverAsync` requests `boards-api.greenhouse.io/v1/boards/{slug}/jobs?content=true` once per slug through `ISourceHttp`; one slug failing is recorded in `Errors` and does not stop the others. 2) `Normalize` maps to `RawOffer`: HTML description to text, location to `location`, country when derivable from a country name or code in the location else null, `work_mode` only if the posting says remote/hybrid/on-site in a structured field, else `unknown`. 3) `Health()`.
- Accept: `Normalizes_the_recorded_fixture`; `Html_description_becomes_text`; `Missing_location_gives_nulls`; `Malformed_posting_is_skipped_and_counted`; `One_slug_failing_does_not_stop_the_others`; `Uses_only_ISourceHttp` (an architecture test that the type has no `HttpClient` field).
- Verify: common verify

### T-01.13 Sources: Ashby adapter
- Executor: implementer · Milestone: M1 · Depends: T-01.11, T-01.28, T-00.04
- Read: SPEC §6.3; SOURCES §3 and §4 (Ashby)
- Files: `src/JobRadar.Sources/Ashby/**`, `tests/JobRadar.Sources.Tests/AshbyTests.cs`
- Do: as T-01.12 for `api.ashbyhq.com/posting-api/job-board/{slug}?includeCompensation=true`, with compensation mapped to `salary_min`, `salary_max`, `currency`, `salary_period` only when present, and unlisted postings skipped.
- Accept: `Normalizes_the_recorded_fixture`; `Absent_compensation_is_null_not_zero`; `Unlisted_posting_is_skipped`; `Malformed_posting_is_skipped_and_counted`; `One_slug_failing_does_not_stop_the_others`; `Uses_only_ISourceHttp`.
- Verify: common verify

### T-01.14 Sources: Remotive adapter
- Executor: implementer · Milestone: M1 · Depends: T-01.11, T-01.28, T-00.04
- Read: SPEC §6.3, A-11; SOURCES §4 (Remotive)
- Files: `src/JobRadar.Sources/Remotive/**`, `tests/JobRadar.Sources.Tests/RemotiveTests.cs`
- Do: as T-01.12 for `remotive.com/api/remote-jobs` (`Kind = Aggregator`), setting `RawOffer.Attribution = "Remotive"`, `posted_at` from the source's date, `work_mode = remote`.
- Accept: `Normalizes_the_recorded_fixture`; `Attribution_is_set`; `Posted_at_comes_from_the_source`; `Malformed_posting_is_skipped_and_counted`; `Uses_only_ISourceHttp`.
- Verify: common verify

### T-01.15 Company lists
- Executor: owner · Milestone: M1 · Depends: T-00.04
- Read: DECISIONS D-26; SOURCES §2
- Files: `config/sources.yaml` (via the director)
- Do: 1) Give the director 30 Greenhouse or Ashby board slugs of target companies, each marked with the system it belongs to. 2) The director adds them and checks each with `probe.yml`; a slug that returns an error is reported back.
- Accept: `sources.yaml` lists at least 30 slugs; each answered 200 in a probe run.
- Verify: `ConfigLoader` test `Seed_files_load_without_errors` and the probe run URL.

### T-01.16 Core: health evaluator
- Executor: implementer · Milestone: M1 · Depends: T-01.01
- Read: SPEC §6.3 "Health"
- Files: `src/JobRadar.Core/Health/HealthEvaluator.cs`, `tests/JobRadar.Core.Tests/HealthEvaluatorTests.cs`
- Do: `HealthEvaluator.Evaluate(int todayCount, IReadOnlyList<int> previousHealthyCounts, IReadOnlyList<string> errors)` → `HealthVerdict(bool Healthy, string? Reason)`. Unhealthy when `todayCount == 0`, or when at least 3 previous counts exist and `todayCount < 0.2 × median(previous 7)`; the reason names the numbers.
- Accept: `Zero_offers_is_unhealthy`; `Drop_below_twenty_percent_of_median_is_unhealthy`; `Drop_with_fewer_than_three_previous_runs_is_healthy`; `Median_uses_only_the_last_seven`; `Exactly_twenty_percent_is_healthy`.
- Verify: common verify

### T-01.17 Cli: ingest
- Executor: implementer · Milestone: M1 · Depends: T-01.05, T-01.06, T-01.26, T-01.08, T-01.09, T-01.10
- Read: SPEC §6.9 (`ingest` row), §5 R7, R8, §13
- Files: `src/JobRadar.Cli/Commands/IngestCommand.cs`, `src/JobRadar.Cli/Stages/IngestStage.cs`, `tests/JobRadar.Cli.Tests/IngestTests.cs`
- Do: 1) `IngestStage.RunAsync` reads `raw/*.jsonl` and the config; for each offer: prefilter (set `prefilter_reason`), upsert, then group recompute for touched keys; then `Expiry.RecordMissedAsync` per source with the source's health, then `Expiry.ArchiveAsync`. 2) After the upsert it runs every registered `IIngestHook` (none yet). 3) Writes `ingest-result.json`: per source counts, ids of new and changed offers, counts by prefilter reason, and the ratio `passed prefilter ÷ ingested`. 4) `IngestCommand : ICliCommand` implements `jobradar ingest`.
- Accept: `Ingest_twice_gives_identical_database_rows`; `Prefilter_reason_is_stored_and_counted`; `Unhealthy_source_does_not_expire_its_offers`; `Result_json_lists_new_and_changed_ids`; `Ratio_is_printed_and_in_the_result_file`.
- Verify: common verify

### T-01.18 Cli: scrape
- Executor: implementer · Milestone: M1 · Depends: T-01.12, T-01.13, T-01.14, T-01.16, T-01.06, T-01.26, T-01.27
- Read: SPEC §6.9 (`scrape` row), R8, R9, R11
- Files: `src/JobRadar.Cli/Commands/ScrapeCommand.cs`, `src/JobRadar.Cli/Stages/ScrapeStage.cs`, `tests/JobRadar.Cli.Tests/ScrapeTests.cs`
- Do: 1) For each enabled source of the requested group, run `Discover`, then `FetchDetail` only for ids the store does not know (a read-only `IKnownOffers` over the database), then `Normalize`; write `raw/<source>.jsonl` (one `RawOffer` per line) and `scrape-summary.json` with counts, errors and the verdict of `HealthEvaluator` (reading the last healthy counts). 2) Each source in its own `try/catch` and its own 10-minute `CancellationToken`. 3) On a parse error write the raw body to `artifacts/failures/<source>/`.
- Accept: `A_throwing_source_does_not_stop_the_others`; `A_source_over_ten_minutes_is_cancelled_and_marked_unhealthy`; `Only_unknown_ids_are_fetched_in_detail`; `Raw_file_has_one_valid_RawOffer_per_line`; `Failure_snapshot_is_written_on_a_parse_error`; `A_missing_key_disables_a_keyed_source`.
- Verify: common verify

### T-01.19 Core: report composer
- Executor: implementer · Milestone: M1 · Depends: T-01.01
- Read: SPEC §6.8; `testing-strategy` (golden files)
- Files: `src/JobRadar.Core/Reporting/ReportComposer.cs`, `src/JobRadar.Core/Reporting/ReportInput.cs`, `tests/JobRadar.Core.Tests/ReportComposerTests.cs`, `tests/JobRadar.Core.Tests/golden/**`
- Do: `ReportComposer.Compose(ReportInput)` → Markdown string with the six parts of SPEC §6.8 in order. Columns and labels from `ReportLabels`. A row's `status` is `alive`, or the unverified label. When there are no rows the table is replaced by one line saying so. Pipes in values are escaped.
- Accept: `Golden_report_matches_byte_for_byte`; `Rows_are_sorted_by_score_then_first_seen`; `Unverified_is_labelled`; `Empty_day_says_so`; `Pipes_are_escaped`; `Same_input_gives_identical_output`; `Source_health_alert_is_listed`; `Unknown_cost_is_shown_as_unknown`.
- Verify: common verify

### T-01.20 Cli: publish and health
- Executor: implementer · Milestone: M1 · Depends: T-01.19, T-01.17
- Read: SPEC §6.7, §6.9 (`publish`, `health` rows), R7
- Files: `src/JobRadar.Cli/Commands/PublishCommand.cs`, `src/JobRadar.Cli/Commands/HealthCommand.cs`, `src/JobRadar.Cli/Stages/PublishStage.cs`, `tests/JobRadar.Cli.Tests/PublishTests.cs`
- Do: 0) Declare `PublishStage` as a `partial class` (T-02.11 adds a part). 1) `publish` selects report rows by the conditions of SPEC §6.7 (Stage 0: `require_score` false), builds `ReportInput`, writes `reports/YYYY-MM-DD.md` and `issue-body.md` (the report plus the marker `<!-- jobradar:daily:YYYY-MM-DD -->` as its first line), then moves `new → active` for every offer that was `new` (R7: calling it twice must not change a rerun's report: take the rows from `ingest-result.json`, not from the current lifecycle). 2) `health` writes `health.json` from `scrape-summary.json` and the database.
- Accept: `Publish_twice_gives_byte_identical_files`; `Issue_body_starts_with_the_marker`; `Offers_become_active_after_publish`; `Duplicates_are_not_listed`; `Prefiltered_and_needs_review_are_not_listed`; `Health_json_lists_unhealthy_sources`.
- Verify: common verify

### T-01.21 daily.yml, Stage 0
- Executor: supervisor · Milestone: M1 · Depends: T-01.18, T-01.20
- Read: SPEC §6.9 (`daily.yml`), R12, R16, §11; `reference-architecture` P12; `self-hosted-runners` §2
- Files: `.github/workflows/daily.yml`, `scripts/publish-data.sh`, `docs/operations/DAILY.md`
- Do: 1) Replace the echo jobs with `scrape-api`, `ingest`, `verify` (a placeholder step in Stage 0), `publish`; `enrich` appears in T-02.15. `schedule` still absent: `workflow_dispatch` with `profile`, `sources`, `dry_run`. 2) Artifacts `raw-<source>` and `db`. 3) `publish-data.sh`: fetch `data`, create it as an orphan on first run, copy `data/jobradar.db` and `reports/`, commit, fast-forward push; job-level concurrency group `jobradar-data-write`. 4) Issue upsert by marker with `gh`. 5) `dry_run` skips every push and issue. 6) Run it live with `profile=live` and the owner's company list.
- Accept: a live dispatch is green and creates `reports/<date>.md` on `data` and one issue; dispatching again the same day changes no row and creates no second issue (`R7`); `ingest` still runs when one scrape matrix leg fails (shown with a deliberately broken slug).
- Verify: the three run URLs and the `git diff` of the second run on `data` showing no change.

### T-01.22 AppHost fake profile, run-all, getting started
- Executor: supervisor · Milestone: M1 · Depends: T-01.20
- Read: SPEC §4; `reference-architecture` P1; the lesson "no run guide" in `LESSONS.md`
- Files: `src/JobRadar.AppHost/**`, `src/JobRadar.Cli/Commands/RunAllCommand.cs`, `docs/GETTING-STARTED.md`, `README.md`
- Do: 1) `run-all --profile fake` runs scrape (fixtures), ingest, enrich (skipped in Stage 0 with a line saying why), verify (skipped), publish in one process on a temporary database. 2) The AppHost starts it with the dashboard. 3) `GETTING-STARTED.md`: clone, dev-setup, the fake command, where the report lands, how to read the dashboard; every command in it has been run.
- Accept: from a clean clone `dotnet run --project src/JobRadar.AppHost --launch-profile fake` produces a report file; the commands in the guide were run and their output matches.
- Verify: the command and its output pasted in the PR.

### T-01.23 Cli: query and the duplicate audit; pipeline test
- Executor: implementer · Milestone: M1 · Depends: T-01.17, T-01.20
- Read: SPEC §6.9 (`query`), §10 "E2E charter", §13
- Files: `src/JobRadar.Cli/Commands/QueryCommand.cs`, `tests/JobRadar.Cli.Tests/PipelineTests.cs`, `tests/fixtures/pipeline/**`
- Do: 1) `jobradar query "<fts>"` prints plain-text lines `code | company | title | lifecycle | liveness | url`; `jobradar query --audit-duplicates` prints groups with more than one **reported** member and exits non-zero if any. 2) `PipelineTests`: run scrape (fixtures with the same job in two sources), ingest, publish twice; assert one row for the duplicate, the ATS copy chosen, zero audit findings, identical second run, a broken source does not stop the others, a dead offer is never shown as `alive`.
- Accept: `Duplicate_across_sources_is_reported_once`; `Ats_copy_is_chosen`; `Second_run_changes_nothing`; `Broken_source_does_not_stop_others`; `Audit_finds_a_planted_duplicate` (the audit is shown able to fail); `Query_finds_by_title_word`.
- Verify: common verify

### T-01.24 Store: size guard
- Executor: implementer · Milestone: M1 · Depends: T-01.20
- Read: SPEC §6.4 "Retention", §13, A-08
- Files: `src/JobRadar.Cli/Stages/SizeGuard.cs`, `tests/JobRadar.Cli.Tests/SizeGuardTests.cs`
- Do: `SizeGuard.Check(long bytes)` → `Ok`, `Warn` (at or above 40 MB; the workflow opens an issue labelled `db-size`), `Stop` (at or above 90 MB; `publish` writes the report but does not commit the database). Print the size every run. Run `VACUUM` in `publish` on Sundays (UTC run date).
- Accept: `Below_forty_is_ok`; `At_forty_warns`; `At_ninety_stops`; `Publish_does_not_commit_when_stopped` (the file list the script would commit excludes the database); `Vacuum_runs_only_on_sundays`.
- Verify: common verify

### T-01.25 Stage 0 gate: seven days
- Executor: supervisor · Milestone: M1 · Depends: T-01.21, T-01.22, T-01.23, T-01.24
- Read: SPEC §14 (M1), A-14, A-15; SUPERVISOR §8, §9
- Files: `docs/spec/PROGRESS.md` (specification repository)
- Do: 1) Ask the owner to approve enabling the `schedule: cron '0 5 * * *'` trigger (DECISIONS D-18) and add it. 2) After 7 consecutive scheduled runs, list the run URLs, the duration of each, the audit output of each, and any run that failed with its cause. 3) Checkpoint (SUPERVISOR §9).
- Accept: seven consecutive runs, none with a failed job; the duplicate audit printed 0 in each; the durations are within SPEC §13; or the gate is reported as failed with evidence.
- Verify: the run URLs.

### T-01.26 Config: blocklist and report loaders
- Executor: implementer · Milestone: M1 · Depends: T-01.06, T-01.03
- Read: SPEC §6.2, §6.6 (blocklist), §6.8 (labels, columns); T-01.06 (the `ConfigError` and `ConfigResult<T>` types)
- Files: `src/JobRadar.Config/Loading/BlocklistLoader.cs`, `src/JobRadar.Config/Loading/ReportLoader.cs`, `config/blocklist.yaml`, `config/report.yaml`, `tests/JobRadar.Config.Tests/BlocklistReportLoaderTests.cs`
- Do: 1) `ConfigLoader.LoadBlocklist(path)` returning the companies normalised with `Normalizer.Company` as an `IReadOnlySet<string>` inside a `ConfigResult`. 2) `ConfigLoader.LoadReport(path)` returning `ReportConfig(int Threshold, bool RequireScore, IReadOnlyDictionary<string,string> Labels)`; `report.yaml` carries `threshold: 70`, `require_score: false` and the Polish labels of SPEC §6.8 (column headings `data`, `firma`, `rola`, `link`, `tryb pracy`, `ścieżka`, `widełki`, `status`, `kod`; section headings `Nie ocenione`, `Zdrowie źródeł`, `Koszt`; the unverified status label `niezweryfikowana`) under stable English keys. 3) An empty blocklist file with a comment is valid. 4) Validation: unknown keys and a threshold outside 0–100 are errors naming file, path and rule.
- Accept: `Blocklist_is_normalised`; `Empty_blocklist_is_valid`; `Report_seed_loads_with_polish_labels`; `Report_threshold_out_of_range_is_an_error`; `Report_unknown_key_is_an_error_naming_the_path`.
- Verify: common verify

### T-01.28 Sources: shared text and country helpers
- Executor: implementer · Milestone: M1 · Depends: T-01.01
- Read: SPEC §6.3 (adapters carry text, not markup), SOURCES §4 (Greenhouse: entity-escaped HTML), COPILOT-SDK §6 (descriptions stay text for agents)
- Files: `src/JobRadar.Sources/Common/HtmlText.cs`, `src/JobRadar.Sources/Common/CountryResolver.cs`, `tests/JobRadar.Sources.Tests/CommonTests/**`
- Do: 1) `HtmlText.ToPlainText(string html)`: decode HTML entities once when the input holds entity-escaped tags (`&lt;h2&gt;`, as Greenhouse returns them), drop `script` and `style` elements with their content, turn `<br>` and the closing tags of `p`, `div`, `li`, `h1`–`h6`, `tr` into line breaks, prefix each `<li>` with `- `, remove every other tag, decode entities again, collapse runs of blank lines to one, trim. 2) `CountryResolver.FromLocation(string? location)` returning an upper-case ISO 3166-1 alpha-2 code or null: a country NAME (English or the local form) for the countries of SPEC Appendix A plus `US` and `CA`, found as a whole word anywhere in the location, or an alpha-2 CODE that is the last comma-separated segment (upper case, exactly two letters, in the same set); null when neither is present (a bare city does not resolve).
- Accept: `Entity_escaped_html_becomes_text`; `Plain_html_becomes_text`; `List_items_become_lines`; `Script_and_style_are_dropped`; `Entities_are_decoded`; `Country_name_resolves`; `Local_country_name_resolves`; `Trailing_code_resolves`; `Bare_city_is_null`; `Null_or_blank_is_null`.
- Verify: common verify

---

## Phase 2 — Stage 1: agents (milestone M2)

Exit: Extractor, Scorer and Reporter run live inside closed sessions; offline evals green and shown able to fail; at least 80% agreement over two weeks.

### T-02.01 Copilot SDK spike, in depth
- Executor: supervisor · Milestone: M2 · Depends: T-01.25, T-00.05
- Read: `COPILOT-SDK.md` all; SPEC §6.5, §11, A-02–A-06; `ai-evals` §4; `security-review`
- Files: `src/JobRadar.Agents/Spike/**`, `.github/workflows/probe-copilot.yml`, `docs/spikes/copilot-sdk.md`
- Do: 1) Extend the T-00.04 spike to the real use: a batch of 3 synthetic offers, the `save_offer_fields` tool as a typed record, `IsTerminal`, rejecting permissions; run it three times. 2) Answer the eight questions of `COPILOT-SDK.md` §4 with evidence from the events. 3) Live tool-surface check: put an instruction in an offer description asking the model to run a shell command, to read a file, and to call `save_score`; record what the runtime did. 4) Measure the credits of a 3-offer and a 15-offer batch; compare with the billing page if the owner supplies it. 5) List models; pick the cheapest suitable ones for the Extractor and Scorer. 6) Amend `COPILOT-SDK.md` and SPEC §6.5 where the spike disagrees; record the pin.
- Accept: `docs/spikes/copilot-sdk.md` answers the eight questions, shows the tool-surface check events, states credits per batch size, names the chosen models and the pinned version; goal 6 of SPEC §1.1 is either supported by the evidence or the SPEC is amended before T-02.03 starts.
- Verify: the `probe-copilot` run URLs.

### T-02.02 Agents: runner contract, fake runner, public-surface test
- Executor: implementer · Milestone: M2 · Depends: T-01.01, T-02.01
- Read: SPEC §6.5, §7; `COPILOT-SDK.md` §9
- Files: `src/JobRadar.Agents/Fake/**`, `tests/JobRadar.Agents.Tests/FakeRunnerTests.cs`, `tests/JobRadar.Agents.Tests/PublicSurfaceTests.cs`
- Do: 1) `FakeAgentRunner : IAgentRunner` driven by a `Script` (list of steps: `ToolCall(name, jsonArguments)`, `Text(string)`, `Timeout`, `Unavailable`, `Usage(in, out, credits?)`). It feeds each tool call through the request's tool handlers exactly as the real runner will (deserialise strictly into `ArgumentsType`, call the handler, return the message), refuses a tool name not in the request, and ends the turn after a successful call of a tool with `EndsTurn`. 2) `PublicSurfaceTests`: by reflection, no public type of `JobRadar.Agents` exposes a type from a namespace starting with `GitHub.Copilot` or `Microsoft.Extensions.AI`.
- Accept: `Invalid_arguments_are_rejected_then_valid_accepted`; `Unknown_tool_is_refused`; `Successful_terminal_call_ends_the_turn`; `Timeout_step_raises_a_timeout`; `Usage_is_reported_or_null`; `Public_surface_has_no_sdk_types`.
- Verify: common verify

### T-02.03 Agents: Copilot runner
- Executor: implementer · Milestone: M2 · Depends: T-02.02
- Read: `COPILOT-SDK.md` §1–§4, §8, §9; SPEC §5 R3, R12; the spike note `docs/spikes/copilot-sdk.md`
- Files: `src/JobRadar.Agents/Copilot/**`, `tests/JobRadar.Agents.Tests/CopilotRunnerTests.cs`
- Do: 1) `CopilotSessionSettings.For(AgentRequest)`: a pure internal function returning the `SessionConfig` (model, effort, system message in Replace mode, streaming off, `AvailableTools` = request tool names, `Tools`, rejecting permission handler). 2) `CopilotAgentRunner : IAgentRunner`: client in `CopilotClientMode.Empty` with a temporary `BaseDirectory`, start that never throws and records `Ready | NotAuthenticated | Unavailable`, one session per `RunAsync` disposed after, `SendAndWaitAsync` with the request timeout, `AbortAsync` after a timeout, usage tally per `COPILOT-SDK.md` §7, token never logged. 3) Experimental `GHCP001` types confined as in `COPILOT-SDK.md` §2 rule 9.
- Accept: `Session_config_lists_exactly_the_request_tools`; `Session_config_rejects_every_permission`; `Session_config_uses_replace_mode_and_no_streaming`; `Missing_token_ends_in_NotAuthenticated_without_exception`; `Refused_connection_ends_in_Unavailable`; `Token_never_appears_in_logs` (a log capture over the failing-start test); `Public_surface_has_no_sdk_types`.
- Verify: common verify

### T-02.04 Agents: prompt packaging and batching
- Executor: implementer · Milestone: M2 · Depends: T-01.01
- Read: `COPILOT-SDK.md` §6; SPEC §5 R4, §6.5 "Batching"
- Files: `src/JobRadar.Agents/Prompting/**`, `tests/JobRadar.Agents.Tests/PromptingTests.cs`
- Do: 1) `OfferText.Sanitize(string)`: NFC, remove control characters except newline and tab, remove `U+200B–U+200F`, `U+202A–U+202E`, `U+2060`, `U+FEFF`, collapse runs of blank lines, cut at 12 000 characters and append `[truncated]`. 2) `PromptBuilder.BuildBatch(IReadOnlyList<OfferForPrompt> offers, Func<string> nonce)` returning the user prompt with the fixed instruction paragraph and one delimited block per offer, references `o1…oN`, and the map from reference to offer id. 3) `Batcher.Split(offers, batchSize, maxChars)`. 4) `PromptVersion.Of(IEnumerable<string> embeddedPrompts)`.
- Accept: `Sanitize_removes_zero_width_and_bidi_controls`; `Sanitize_truncates_with_a_marker`; `Description_cannot_contain_the_closing_marker` (a description containing a guessed marker is still inside the real nonce block); `Nonce_differs_per_call`; `References_are_o1_to_oN_and_ids_never_appear_in_the_prompt`; `Batch_never_exceeds_size_or_chars`; `Prompt_version_changes_when_a_prompt_changes`.
- Verify: common verify

### T-02.05 Agents: tool arguments and strict reading
- Executor: implementer · Milestone: M2 · Depends: T-01.01
- Read: `COPILOT-SDK.md` §5; SPEC §6.4 enumerated values, §6.5 "Validation"
- Files: `src/JobRadar.Agents/Tools/**`, `tests/JobRadar.Agents.Tests/ToolArgumentsTests.cs`
- Do: 1) `StrictJson.Options` and `StrictJson.TryRead<T>(string json, out T? value, out string error)` per `COPILOT-SDK.md` §5. 2) `OfferFieldsValidator.Validate(SaveOfferFieldsArgs, IReadOnlySet<string> knownRefs)` and `ScoreValidator.Validate(SaveScoreArgs, knownRefs, enabledTracks)` with the range, length and array rules of SPEC §6.5; the error message names the field and never echoes more than 100 characters. 3) `ToolSchemas.For(Type)` using `JsonSchemaExporter`.
- Accept: `Unknown_property_is_rejected`; `Integer_for_enum_is_rejected`; `Out_of_range_score_is_rejected`; `Too_long_reason_is_rejected`; `Unknown_reference_is_rejected`; `Duplicate_reference_is_rejected`; `Disabled_track_is_rejected`; `Error_message_never_echoes_more_than_100_characters`; `Schema_lists_every_enum_value`.
- Verify: common verify

### T-02.06 Agents: Extractor
- Executor: implementer · Milestone: M2 · Depends: T-02.02, T-02.04, T-02.05
- Read: SPEC §6.5 (Extractor, validation), R5; `COPILOT-SDK.md` §6
- Files: `src/JobRadar.Agents/Extractor/**`, `src/JobRadar.Agents/Prompts/extractor.system.md`, `tests/JobRadar.Agents.Tests/ExtractorTests.cs`
- Do: 1) `Extractor.ExtractAsync(IReadOnlyList<OfferForExtraction>, IAgentRunner, ExtractorOptions)` returning one `ExtractionOutcome` per offer: `Accepted(OfferFields)` or `NeedsReview`. 2) Per batch: build the prompt, one tool `save_offer_fields` with `EndsTurn = true` whose handler validates and stores accepted entries; after the session, offers without an accepted entry are re-run once in a new batch, then `NeedsReview`. 3) Evidence check: each quote must be a substring of the description after whitespace normalisation; missing quote lowers `confidence` one step; a quote not found marks that field `unknown`. 4) The system prompt file is written in English, says the text is untrusted data, lists the field definitions, and forbids anything but the tool call.
- Accept: `Accepted_batch_returns_fields_for_every_offer`; `Invalid_then_valid_call_is_accepted`; `Missing_offer_is_rerun_once_then_needs_review`; `Quote_not_in_text_marks_the_field_unknown`; `Missing_quote_lowers_confidence`; `Runner_unavailable_leaves_all_offers_pending_not_review`; `Only_save_offer_fields_is_offered` (the request's tool list equals exactly that one name).
- Verify: common verify

### T-02.07 Core: hard exclusions
- Executor: implementer · Milestone: M2 · Depends: T-01.01
- Read: SPEC §6.6 "Stage 3" and the rule table; ADR-0005; Appendix A
- Files: `src/JobRadar.Core/Filtering/HardExclusions.cs`, `tests/JobRadar.Core.Tests/HardExclusionsTests.cs`
- Do: `HardExclusions.Apply(OfferFields fields, RawOffer offer, Criteria criteria, int modelScore, string? modelTrack, bool descriptionMatchesInjection)` → `CappedScore(int Score, string Track, IReadOnlyList<string> RulesFired, IReadOnlyList<string> AddedRedFlags)` implementing the six rules of SPEC in order. Fired rule → score 0 and track `none`. Spain exception reduces the score by `office_penalty` (not below 0) and does not fire.
- Accept: one test per rule `Rule_<id>_fires` and `Rule_<id>_does_not_fire_when_condition_is_false`; `Office_in_spain_reduces_score_by_penalty`; `Penalty_never_goes_below_zero`; `B2b_unknown_adds_a_flag_and_does_not_exclude`; `Model_score_100_with_agency_is_0`; `Several_rules_are_all_listed`.
- Verify: common verify

### T-02.08 Agents: Scorer
- Executor: implementer · Milestone: M2 · Depends: T-02.06, T-02.07
- Read: SPEC §6.5 (Scorer), §6.6; `COPILOT-SDK.md` §6
- Files: `src/JobRadar.Agents/Scorer/**`, `src/JobRadar.Agents/Prompts/scorer.system.md`, `tests/JobRadar.Agents.Tests/ScorerTests.cs`
- Do: 1) `Scorer.ScoreAsync(IReadOnlyList<OfferForScoring>, Criteria, IAgentRunner, ScorerOptions)` returning `ScoreResult` per offer after `HardExclusions.Apply`. 2) The prompt carries the enabled tracks from `criteria.yaml` in the system prompt and, per offer, reference, title, company, validated fields, salary and a 1 200-character excerpt (never the whole description). 3) One tool `save_score`, `EndsTurn = true`, validated by T-02.05; one batch-level re-run for missing offers; still missing → no score row and the offer stays pending. 4) An injection-pattern match on the description sets the flag before the cap.
- Accept: `Score_is_capped_by_a_fired_rule`; `Disabled_track_answer_is_rejected`; `Excerpt_is_at_most_1200_characters`; `Full_description_never_reaches_the_prompt`; `Injection_pattern_gives_zero_and_flag`; `Missing_offer_is_rerun_once`; `Only_save_score_is_offered`.
- Verify: common verify

### T-02.09 Store: fields, scores, usage, pending queries
- Executor: implementer · Milestone: M2 · Depends: T-01.07, T-01.17
- Read: SPEC §6.4 (`offer_fields`, `scores`, `agent_usage`), §6.7
- Files: `src/JobRadar.Store/Repositories/Enrichment.cs`, `tests/JobRadar.Store.Tests/EnrichmentTests.cs`
- Do: 1) `Enrichment.PendingExtractionAsync()`: primary offers, not prefiltered, not archived, with no `offer_fields` row for their current `description_hash`, excluding `needs_review` ones whose hash is unchanged. 2) `SaveFieldsAsync`, `MarkNeedsReviewAsync`. 3) `PendingScoringAsync(int criteriaVersion)`: offers with fields and no score row for `(hash, criteriaVersion)`. 4) `SaveScoreAsync` (adds a row; never replaces another version). 5) `SaveUsageAsync`.
- Accept: `Changed_description_makes_an_offer_pending_again`; `New_criteria_version_makes_offers_pending_for_scoring_only`; `Score_rows_of_other_versions_are_kept`; `Needs_review_is_not_retried_until_the_text_changes`; `Duplicates_and_prefiltered_are_never_pending`; `Usage_row_allows_null_credits`.
- Verify: common verify

### T-02.10 Cli: enrich and the cost guard
- Executor: implementer · Milestone: M2 · Depends: T-02.08, T-02.09, T-02.03
- Read: SPEC §6.5 "Cost guard", §6.9 (`enrich`), R14, A-05; `COPILOT-SDK.md` §7, §8
- Files: `src/JobRadar.Cli/Commands/EnrichCommand.cs`, `src/JobRadar.Cli/Stages/EnrichStage.cs`, `tests/JobRadar.Cli.Tests/EnrichTests.cs`
- Do: 1) `EnrichStage` loads pending offers, runs the Extractor then the Scorer in batches, saves results and usage after each batch, and writes `enrich-summary.json` (batches, tokens, credits or `unknown`, dollars, counts evaluated, pending, needs-review, and why any are pending). 2) Cost guard: after each batch add reported credits (or `AssumedCreditsPerBatch` for the guard only) and stop starting batches at `MaxAiCreditsPerRun`. 3) If the runner status is not `Ready` or `Fake`, evaluate nothing, exit 0, and say so in the summary.
- Accept: `Budget_stops_new_batches_and_leaves_the_rest_pending`; `Unavailable_runner_evaluates_nothing_and_exits_zero`; `Unreported_usage_uses_the_assumed_figure_for_the_guard_only`; `Second_run_evaluates_only_what_is_pending`; `Summary_lists_pending_reasons`; `Credits_are_null_when_nothing_was_reported`.
- Verify: common verify

### T-02.11 Agents: Reporter and report integration
- Executor: implementer · Milestone: M2 · Depends: T-01.19, T-02.02
- Read: SPEC §6.5 (Reporter), §6.8
- Files: `src/JobRadar.Agents/Reporter/**`, `src/JobRadar.Agents/Prompts/reporter.system.md`, `src/JobRadar.Cli/Stages/PublishStage.Summary.cs`, `tests/JobRadar.Agents.Tests/ReporterTests.cs`
- Do: 1) `Reporter.SummariseAsync(ReporterInput, IAgentRunner)` with one tool `write_report_summary` (`EndsTurn = true`), `summary_md` at most 1 200 characters, no links and no HTML (validated). 2) `PublishStage` (declared `partial` by T-01.20, so this task adds a second file) adds the summary when present; when the runner is unavailable, the summary is absent and the report is still produced (P8).
- Accept: `Summary_with_a_link_is_rejected`; `Summary_with_html_is_rejected`; `Over_long_summary_is_rejected`; `Unavailable_runner_gives_a_report_without_summary`; `Only_write_report_summary_is_offered`.
- Verify: common verify

### T-02.12 Evals: offline scenario suite
- Executor: implementer · Milestone: M2 · Depends: T-02.06, T-02.08, T-02.10
- Read: SPEC §10 (Evals); `ai-evals` §2–§4, §9; `e2e-acceptance-testing`
- Files: `tests/evals/**`, `tests/JobRadar.Agents.Tests/Evals/**`, `docs/EVALS.md`
- Do: 1) Scenario files (JSON: `id`, `class`, `input`, `scripted_replies`, `expect`) for the Extractor and the Scorer: at least 30 each in the classes accepted, recovers, fails, degraded and adversarial; at least 12 adversarial descriptions as listed in SPEC §10. 2) A runner that plays every file through `FakeAgentRunner` and asserts, on the trace of tool calls and permissions: constraints C1–C6. 3) `docs/EVALS.md` with the behaviour spec (SPEC §10 text), the class counts, and what the offline suite cannot prove. 4) The director later adds the demonstration of the suite failing (next step in Accept) — the implementer provides a switch `EVAL_BREAK=<constraint>` read by test code only, that weakens the harness for that one constraint.
- Accept: scenario counts per class as above; `Eval_suite_is_green`; for each of C1–C6 a test `Eval_suite_fails_when_<constraint>_is_broken` that runs the suite with the switch and expects at least one failing scenario.
- Verify: common verify

### T-02.13 eval-live workflow and live runs
- Executor: supervisor · Milestone: M2 · Depends: T-02.12
- Read: SPEC §10; `ai-evals` §6; R12
- Files: `.github/workflows/eval-live.yml`, `tests/evals/live/**`, `docs/EVALS.md`
- Do: 1) `eval-live.yml` (`workflow_dispatch`, environment `copilot`) runs the accepted and adversarial scenarios against the real model with `Agents:MaxAiCreditsPerRun`. 2) Gate: no adversarial scenario changes the validated result compared with its clean twin. 3) Run it twice; record the results as "live, N scenarios, date".
- Accept: two run URLs; the numbers (scenarios, passes, credits) in `docs/EVALS.md`; a failing scenario, if any, is a finding in PROGRESS, not a weakened test.
- Verify: the run URLs.

### T-02.14 Feedback capture and calibrate
- Executor: implementer · Milestone: M2 · Depends: T-02.09, T-01.20
- Read: SPEC §6.7, §11 (workflow injection), D-31
- Files: `src/JobRadar.Cli/Commands/CalibrateCommand.cs`, `src/JobRadar.Cli/Stages/FeedbackLoader.cs`, `src/JobRadar.Core/Feedback/FeedbackParser.cs`, `tests/JobRadar.Core.Tests/FeedbackParserTests.cs`, `tests/JobRadar.Cli.Tests/CalibrateTests.cs`
- Do: 1) `FeedbackParser.Parse(string commentBody)` returning entries from lines `fit <code>` and `nofit <code> [note]` (code = eight hex characters, case-insensitive; other lines ignored; at most 50 entries per comment; note at most 200 characters). 2) `FeedbackLoader` loads `feedback/feedback.jsonl` lines into `feedback` during `ingest`, ignoring duplicates. 3) `calibrate` prints count, agreement percentage and the list of disagreements per SPEC §6.7.
- Accept: `Parser_reads_fit_and_nofit_lines`; `Parser_ignores_other_text`; `Parser_rejects_a_bad_code`; `Parser_caps_entries_and_note_length`; `Loader_ignores_duplicates`; `Calibrate_reports_agreement_and_disagreements`; `Calibrate_with_no_feedback_says_so`.
- Verify: common verify

### T-02.15 daily.yml with enrich, and feedback.yml
- Executor: supervisor · Milestone: M2 · Depends: T-02.10, T-02.11, T-02.14
- Read: SPEC §6.9, §11, R12, R13; `self-hosted-runners` §2
- Files: `.github/workflows/daily.yml`, `.github/workflows/feedback.yml`, `scripts/publish-data.sh`
- Do: 1) Add the `enrich` job (hosted, environment `copilot`, secret at step level, `contents: read`), `verify` and `publish` now `needs` it with `if: !cancelled()`. 2) `feedback.yml`: `issue_comment`, runs only when `github.event.comment.user.login == vars.OWNER_LOGIN`, passes the body through `env:`, calls the parser, appends to `feedback/feedback.jsonl` on `data` under group `jobradar-data-write`. 3) Show that the run with a missing token still publishes with "not evaluated".
- Accept: a live run with the token evaluates offers and reports cost; a run with the secret removed (on a branch) publishes "not evaluated" and is green; a comment from another login does nothing (shown); an owner comment `fit <code>` appears in `feedback.jsonl`.
- Verify: the run URLs.

### T-02.16 Agents: bring-your-own-key runner
- Executor: implementer · Milestone: M2 · Depends: T-02.03
- Read: `COPILOT-SDK.md` §3 (Bring your own key), §10; SPEC §6.5; D-22
- Files: `src/JobRadar.Agents/Byok/**`, `tests/JobRadar.Agents.Tests/ByokRunnerTests.cs`
- Do: `ByokAgentRunner : IAgentRunner` using `SessionConfig.Provider` with the fields of the chess arena's `ProviderFor` (type, base URL, key, wire model, wire API); the key comes from configuration `Agents:Byok:ApiKey`, never logged, never part of `ToString()`; same session rules as T-02.03 through a shared settings builder. Not wired by default.
- Accept: `Provider_config_carries_type_url_and_model`; `Key_is_not_in_any_string_representation`; `Session_rules_match_the_copilot_runner`; `Missing_key_ends_in_NotAuthenticated`.
- Verify: common verify

### T-02.17 Security review
- Executor: supervisor · Milestone: M2 · Depends: T-02.15, T-02.13
- Read: `security-review` all; SPEC §11
- Files: `docs/security/REVIEW-1.md`
- Do: Run the method of `security-review` over `job-radar`: workflows (permissions, secrets, event text), agent isolation (the live tool-surface evidence), config loader, artifacts, `publish-data.sh`. Findings in the standard format with severity; each blocking finding becomes a task before M2 is claimed.
- Accept: the document exists; no unresolved finding of severity blocking; the workflow-injection and tool-surface sections cite evidence.
- Verify: link to the review and to the fixing pull requests.

### T-02.18 Stage 1 gate: two weeks
- Executor: supervisor · Milestone: M2 · Depends: T-02.15, T-02.17
- Read: SPEC §14 (M2), D-31, D-19; SUPERVISOR §8, §9
- Files: `docs/spec/PROGRESS.md` (specification repository)
- Do: 1) Remind the owner to mark each reported offer `fit` or `nofit` for two weeks. 2) After two weeks run `jobradar calibrate` and attach the output. 3) If agreement is below 80%, open tasks to adjust prompts, criteria version or threshold (each a new `criteria.yaml` version) and measure again; do not claim the gate.
- Accept: calibrate output with the date range and the list of feedback entries; agreement at least 80% for the gate; otherwise reported as failed with the disagreements.
- Verify: the run log with the calibrate output.

---

## Phase 3 — Stage 2: portals, ATS list, liveness (milestone M3)

### T-03.00 Adzuna account
- Executor: owner · Milestone: M3 · Depends: T-02.18
- Read: SOURCES §2 (Adzuna)
- Files: — (repository secrets)
- Do: Register at the Adzuna developer site; store `ADZUNA_APP_ID` and `ADZUNA_APP_KEY` as repository secrets; extend the company list to 50–150 slugs in the director's message (T-03.10).
- Accept: both secrets are listed in the repository settings.
- Verify: the owner confirms in the PR.

### T-03.01 Sources: Lever adapter
- Executor: implementer · Milestone: M3 · Depends: T-01.11, T-02.18
- Read: SPEC §6.3; SOURCES §2, §3, §4 (Lever is "indirect": probe first)
- Files: `src/JobRadar.Sources/Lever/**`, `tests/JobRadar.Sources.Tests/LeverTests.cs`, `tests/fixtures/lever/**`
- Do: as T-01.12 for `api.lever.co/v0/postings/{slug}?mode=json`, from the fixture recorded by `probe.yml` (the director records it first; if the shape differs, SOURCES.md is amended first).
- Accept: `Normalizes_the_recorded_fixture`; `Malformed_posting_is_skipped_and_counted`; `One_slug_failing_does_not_stop_the_others`; `Uses_only_ISourceHttp`.
- Verify: common verify

### T-03.02 Sources: No Fluff Jobs adapter
- Executor: implementer · Milestone: M3 · Depends: T-01.11, T-02.18
- Read: SPEC §6.3, A-07; SOURCES §4
- Files: `src/JobRadar.Sources/NoFluffJobs/**`, `tests/JobRadar.Sources.Tests/NoFluffJobsTests.cs`, `tests/fixtures/nofluffjobs/**`
- Do: adapter for the search and detail endpoints, from the recorded fixtures; pay range (mandatory on that site) mapped to salary fields; stops after `Scrape:MaxPagesPerSource` (default 20).
- Accept: `Normalizes_the_recorded_fixture`; `Pay_range_is_mapped`; `Stops_at_the_page_cap`; `Malformed_posting_is_skipped_and_counted`; `Uses_only_ISourceHttp`.
- Verify: common verify

### T-03.03 Sources: justjoin.it adapter
- Executor: implementer · Milestone: M3 · Depends: T-01.11, T-02.18
- Read: SPEC §6.3, A-07; SOURCES §4
- Files: `src/JobRadar.Sources/JustJoinIt/**`, `tests/JobRadar.Sources.Tests/JustJoinItTests.cs`, `tests/fixtures/justjoinit/**`
- Do: adapter for the listing endpoint and the `JobPosting` JSON-LD of an offer page (JSON-LD first, as SPEC §6.3 orders extraction), no `page=` use, stop at the 10 000 cap.
- Accept: `Normalizes_the_recorded_fixture`; `Json_ld_is_preferred_over_selectors`; `Stops_at_the_cap`; `Malformed_posting_is_skipped_and_counted`; `Uses_only_ISourceHttp`; `Robots_guard_is_called_before_an_html_request`.
- Verify: common verify

### T-03.04 Sources: Adzuna adapter
- Executor: implementer · Milestone: M3 · Depends: T-01.11, T-03.00
- Read: SPEC §6.3, §5 R12; SOURCES §4 (Adzuna)
- Files: `src/JobRadar.Sources/Adzuna/**`, `tests/JobRadar.Sources.Tests/AdzunaTests.cs`, `tests/fixtures/adzuna/**`
- Do: adapter for `es` and `pl`, paging to `Scrape:MaxPagesPerSource`, keys from the options (never logged, never in `Errors`, never in a URL written to a log: log the URL without the key query parameters), a missing key disables the source.
- Accept: `Normalizes_the_recorded_fixture`; `Missing_key_disables_the_source`; `Key_never_appears_in_logs_or_errors`; `Pages_are_capped`; `Uses_only_ISourceHttp`.
- Verify: common verify

### T-03.05 Sources: We Work Remotely adapter
- Executor: implementer · Milestone: M3 · Depends: T-01.11, T-02.18
- Read: SPEC §6.3; SOURCES §4 (WWR)
- Files: `src/JobRadar.Sources/WeWorkRemotely/**`, `tests/JobRadar.Sources.Tests/WeWorkRemotelyTests.cs`, `tests/fixtures/weworkremotely/**`
- Do: RSS adapter for the main feed and the category feeds in `sources.yaml`, `work_mode = remote`, region from the feed item when present.
- Accept: `Normalizes_the_recorded_fixture`; `Malformed_item_is_skipped_and_counted`; `Uses_only_ISourceHttp`.
- Verify: common verify

### T-03.06 Sources: liveness checker
- Executor: implementer · Milestone: M3 · Depends: T-01.11, T-01.01
- Read: SPEC §5 R6, §6.4 liveness, §13
- Files: `src/JobRadar.Sources/Liveness/**`, `config/liveness-markers.yaml`, `tests/JobRadar.Sources.Tests/LivenessTests.cs`
- Do: 1) `LivenessChecker.CheckAsync(Offer, ISourceHttp)` → `Alive`, `Dead`, `Unverified`. Order: a GET (HEAD only where a source's config says it works); 404 or 410 → `Dead`; 200 → look for the source's expiry markers (phrases and redirect-to-listing patterns from `config/liveness-markers.yaml`, for example "oferta wygasła", "esta oferta ya no está disponible") → `Dead` if found, else `Alive`; up to 3 redirects, a redirect to a different path pattern per the source's config counts as `Dead`; timeouts, 403, 429, 5xx, a captcha or block page → `Unverified`. 2) Seed the marker file for the sources of Stage 0 and 2 using the fixtures; a source without markers can only return `Alive` for a 200 whose body contains the offer title, else `Unverified`.
- Accept: `Not_found_is_dead`; `Marker_phrase_is_dead`; `Redirect_to_listing_is_dead`; `Plain_200_with_title_is_alive`; `Timeout_is_unverified`; `Block_page_is_unverified`; `Source_without_markers_never_claims_alive_without_the_title`; `Three_redirects_at_most`.
- Verify: common verify

### T-03.07 Cli: verify
- Executor: implementer · Milestone: M3 · Depends: T-03.06, T-01.10
- Read: SPEC §6.9 (`verify`), §6.4 liveness, §13
- Files: `src/JobRadar.Cli/Commands/VerifyCommand.cs`, `src/JobRadar.Cli/Stages/VerifyStage.cs`, `tests/JobRadar.Cli.Tests/VerifyTests.cs`
- Do: select active offers plus today's report offers, at most one request each, 1–3 s per host through `SourceHttp`; set `liveness` and `last_checked_at`; `Dead` calls `Expiry.MarkDeadAsync`; write `verify-summary.json` with counts per result and the duration; stop starting checks when 80% of the job time limit is used and leave the rest unchecked (their liveness stays as it was).
- Accept: `Dead_offer_is_expired`; `Unverified_is_recorded_not_guessed`; `One_request_per_offer`; `Time_limit_leaves_the_rest_unchecked`; `Summary_counts_match_the_database`.
- Verify: common verify

### T-03.08 daily.yml with verify and the Stage 2 sources
- Executor: supervisor · Milestone: M3 · Depends: T-03.07, T-03.01, T-03.02, T-03.03, T-03.04, T-03.05
- Read: SPEC §6.9; SPEC §7 (report rows with `unverified`)
- Files: `.github/workflows/daily.yml`, `config/sources.yaml`
- Do: replace the `verify` placeholder with the real command; enable the Stage 2 sources one at a time, each after one live dispatch showing it healthy; add the issue labelled `source-health` upsert for unhealthy sources.
- Accept: a live run lists the new sources with counts; a deliberately blocked source (a wrong slug) opens one `source-health` issue and a second run updates it rather than opening another.
- Verify: the run URLs.

### T-03.09 Stage 2 gate
- Executor: supervisor · Milestone: M3 · Depends: T-03.08
- Read: SPEC §14 (M3), §13; SUPERVISOR §9
- Files: `docs/spec/PROGRESS.md` (specification repository)
- Do: 7 consecutive healthy runs with all Stage 2 sources; ask the owner to check a sample of 20 reported offers for a wrong `alive`; record durations against the 60-minute target; checkpoint; the owner decides D-25 here.
- Accept: run URLs; the owner's sample result; D-25 answered.
- Verify: the run URLs.

### T-03.10 Company list growth
- Executor: owner · Milestone: M3 · Depends: T-03.00
- Read: DECISIONS D-26
- Files: `config/sources.yaml` (via the director)
- Do: extend the lists to 50–150 slugs across Greenhouse, Ashby and Lever; the director checks each with `probe.yml`.
- Accept: at least 50 slugs, each answering 200.
- Verify: probe run URL.

---

## Phase 4 — Stage 3: browser sources (milestone M4)

### T-04.00 Runner decision and InfoJobs account
- Executor: owner · Milestone: M4 · Depends: T-03.09
- Read: DECISIONS D-09–D-11, D-25; `self-hosted-runners`
- Files: — (runner host, repository settings)
- Do: 1) Decide D-25. If a home server: register it as a self-hosted runner (ephemeral, one job at a time), set the repository variable `RUNNER_LABELS_BROWSER`, and tell the director what is installed. If hosted: leave it unset. 2) Register an application at `developer.infojobs.net` and store `INFOJOBS_CLIENT_ID` and `INFOJOBS_SECRET`.
- Accept: the variable and the secrets are visible in settings; the director records the runner image contents in `docs/operations/CI.md`.
- Verify: the owner confirms in the PR.

### T-04.01 Sources: browser context factory
- Executor: implementer · Milestone: M4 · Depends: T-04.00, T-01.11
- Read: SPEC §6.3, R8; A-10
- Files: `src/JobRadar.Sources/Browser/**`, `tests/JobRadar.Sources.Tests/BrowserTests/**`, `tests/pages/**`
- Do: 1) `BrowserSession.OpenAsync(string source)`: one browser context per source; `page.route()` aborting image, font and media requests; page timeout 30 s; on a parse error `SnapshotAsync` writes HTML and a screenshot to `artifacts/failures/<source>/`. 2) Local static pages under `tests/pages` served by a tiny in-test server. Tests carry `tier=browser`.
- Accept: `Images_fonts_and_media_are_blocked`; `Each_source_has_its_own_context`; `Snapshot_writes_html_and_screenshot_on_error`; `Page_timeout_is_30_seconds`.
- Verify: `dotnet test JobRadar.sln --filter "tier=browser"` after `pwsh bin/Debug/net10.0/playwright.ps1 install chromium` (the command that was run, as `docs/operations/CI.md` records).

### T-04.02 Sources: Pracuj.pl adapter
- Executor: implementer · Milestone: M4 · Depends: T-04.01
- Read: SPEC §6.3 (extraction order); SOURCES §2, §4
- Files: `src/JobRadar.Sources/Pracuj/**`, `tests/JobRadar.Sources.Tests/PracujTests.cs`, `tests/pages/pracuj/**`
- Do: parse `__NEXT_DATA__` from the search and offer pages first; fall back to selectors; robots guard first; listing capped by `Scrape:MaxPagesPerSource`.
- Accept: `Next_data_is_preferred_over_selectors`; `Normalizes_the_recorded_page`; `Selector_fallback_works_without_next_data`; `Robots_guard_is_called_first`; `Malformed_page_is_skipped_and_counted`.
- Verify: common verify and the `tier=browser` command if the task has browser tests.

### T-04.03 Sources: InfoJobs adapter
- Executor: implementer · Milestone: M4 · Depends: T-04.01
- Read: SPEC §6.3, R12; SOURCES §2 (InfoJobs)
- Files: `src/JobRadar.Sources/InfoJobs/**`, `tests/JobRadar.Sources.Tests/InfoJobsTests.cs`, `tests/fixtures/infojobs/**`
- Do: the official API with basic authentication when the terms allow it (the director confirms the terms first and amends SOURCES.md), else HTML through the browser session; keys never logged.
- Accept: `Normalizes_the_recorded_fixture`; `Key_never_appears_in_logs_or_errors`; `Missing_key_disables_the_source`; `Malformed_posting_is_skipped_and_counted`.
- Verify: common verify

### T-04.04 daily.yml with the browser scrape job
- Executor: supervisor · Milestone: M4 · Depends: T-04.02, T-04.03
- Read: SPEC §6.9, §11 (runners); `self-hosted-runners`
- Files: `.github/workflows/daily.yml`, `.github/workflows/ci.yml`, `docs/operations/CI.md`
- Do: add `scrape-browser` on `RUNNER_LABELS_BROWSER` (default hosted), failure artifacts for 7 days, the `browser` CI job; confirm that no job holding a secret can be routed to the self-hosted runner.
- Accept: a live run scrapes both sources; a deliberately broken selector produces a failure artifact and an unhealthy verdict without stopping other sources.
- Verify: the run URLs.

### T-04.05 Stage 3 gate
- Executor: supervisor · Milestone: M4 · Depends: T-04.04
- Read: SPEC §14 (M4); SUPERVISOR §9
- Files: `docs/spec/PROGRESS.md` (specification repository)
- Do: 7 healthy runs; the deliberate-failure run; checkpoint.
- Accept: run URLs.
- Verify: the run URLs.

---

## Phase 5 — Stage 4: self-repair (milestone M5)

### T-05.01 Agents: jailed repair tools
- Executor: implementer · Milestone: M5 · Depends: T-02.05, T-04.05
- Read: SPEC §6.5 (Repairer), §11 (supply chain); R3
- Files: `src/JobRadar.Agents/Repair/Tools/**`, `tests/JobRadar.Agents.Tests/RepairToolsTests.cs`
- Do: `PathJail` for `src/JobRadar.Sources/<source>/**` and `tests/fixtures/<source>/**` of a scratch checkout; tools `read_adapter_file(path)`, `write_adapter_file(path, content)` (size cap 100 KB, no binary), `run_adapter_tests()` (runs the source's tests only, output capped at 4 000 characters). A path is normalised, symbolic links are refused, and any path outside the jail returns a rejection.
- Accept: `Dot_dot_escape_is_rejected`; `Absolute_path_is_rejected`; `Symlink_is_rejected`; `Write_outside_the_source_folder_is_rejected`; `Oversize_write_is_rejected`; `Test_output_is_capped`; `Only_the_three_tools_are_offered`.
- Verify: common verify

### T-05.02 Agents: Repairer
- Executor: implementer · Milestone: M5 · Depends: T-05.01, T-02.08
- Read: SPEC §6.5 (Repairer); `COPILOT-SDK.md` §6
- Files: `src/JobRadar.Agents/Repair/Repairer.cs`, `src/JobRadar.Agents/Prompts/repairer.system.md`, `tests/JobRadar.Agents.Tests/RepairerTests.cs`
- Do: `Repairer.RepairAsync(RepairInput, IAgentRunner)` with the failure snapshot (HTML or JSON, cut at 12 000 characters, sanitised as offer text), the adapter source, the log; the prompt says the snapshot is untrusted data. A session ends when `run_adapter_tests` has passed or after `Repair:MaxToolCalls` (default 25).
- Accept: `Snapshot_text_is_sanitised_and_delimited`; `Session_stops_after_the_tool_call_cap`; `Only_jailed_tools_are_offered`; `Success_is_reported_only_when_the_tests_passed`.
- Verify: common verify

### T-05.03 Cli: repair and the diff guard
- Executor: implementer · Milestone: M5 · Depends: T-05.02
- Read: SPEC §6.9 (`repair`, `repair.yml`), §11
- Files: `src/JobRadar.Cli/Commands/RepairCommand.cs`, `src/JobRadar.Cli/Stages/DiffGuard.cs`, `tests/JobRadar.Cli.Tests/DiffGuardTests.cs`
- Do: `repair --source id` runs the Repairer in a scratch checkout, then `DiffGuard.Check(changedPaths, source)`: only paths under the source's adapter and fixture folders and its tests are allowed; `.github/**`, `config/**`, `Directory.*`, `*.csproj`, other sources and anything else fail the guard; writes `repair-result.json` (`ok`, `changedPaths`, `testsPassed`).
- Accept: `Only_the_sources_own_paths_pass`; `Workflow_change_fails`; `Config_change_fails`; `Csproj_change_fails`; `Other_source_change_fails`; `Result_json_says_why_a_repair_was_refused`.
- Verify: common verify

### T-05.04 repair.yml
- Executor: supervisor · Milestone: M5 · Depends: T-05.03
- Read: SPEC §6.9 (`repair.yml`), §11; R12, R16
- Files: `.github/workflows/repair.yml`, `.github/CODEOWNERS`, `scripts/open-repair-pr.sh`
- Do: triggers `workflow_dispatch` and `repository_dispatch` (`source-unhealthy`); only for `repairable` sources whose failure class is `parse-error`; at most one open `repair/<source>-*` pull request and one attempt per source per day; the pull request is opened by the script after the diff guard and the adapter tests, never merged by the workflow; CODEOWNERS makes the owner a required reviewer of `repair/*`.
- Accept: a dispatch for a source with a broken selector (a copy of an adapter with a deliberately wrong selector, on a branch) opens one pull request that passes the adapter tests and touches only its source's paths; a second dispatch the same day opens none; a source that is unhealthy for a network reason is refused.
- Verify: the run URLs and the pull request.

### T-05.05 Repair evals and the Stage 4 gate
- Executor: supervisor · Milestone: M5 · Depends: T-05.04
- Read: SPEC §14 (M5), §10; `ai-evals` §3
- Files: `tests/evals/repair/**`, `docs/EVALS.md`, `docs/spec/PROGRESS.md` (specification repository)
- Do: add repair scenarios (a changed selector, a renamed JSON field, an injection inside the snapshot, a request to edit a workflow); run them live once; claim M5 only with the pull request of T-05.04.
- Accept: the scenarios and the live result recorded; the injection and workflow-edit scenarios end refused.
- Verify: the run URL.

### T-05.06 Final architecture review and documents
- Executor: supervisor · Milestone: M5 · Depends: T-05.05
- Read: `architecture-review` agent; `repo-baseline`; `readme-badges`
- Files: `docs/architecture/ARCHITECTURE_REVIEW.md` (`job-radar`), `README.md`, `docs/spec/PROGRESS.md` (specification repository)
- Do: run the `architecture-review` agent over `job-radar`, resolve its blocking findings, make the README say only what the code does (every command in it was run), and bring PROGRESS to the truth.
- Accept: review document with no unresolved blocking finding; README commands verified.
- Verify: link to the review and the pull request.

---

## Waves

Which tasks may run at the same time (disjoint `Files:` sets). The director never starts more sub-sessions than DECISIONS D-16
allows, whatever this table permits. Supervisor tasks run between waves.

| Wave | Tasks | Blocked by |
|---|---|---|
| 0 | T-00.01 → T-00.02 → T-00.03 → T-00.04 (in order, never parallel); T-00.05 (owner, local) runs beside Phase 1 | — |
| 1 | T-01.01 (director alone) | T-00.04 |
| 2 | T-01.02, T-01.03, T-01.04, T-01.06, T-01.07, T-01.11, T-01.16, T-01.19 (disjoint folders); T-01.26 after T-01.06 and T-01.03 | T-01.01 |
| 3 | T-01.05, T-01.08, T-01.12, T-01.13, T-01.14 | T-01.03 for T-01.05; T-01.07 and T-01.02 for T-01.08; T-01.11 for the adapters |
| 4 | T-01.09, T-01.10 | T-01.08 |
| 5 | T-01.17, T-01.18 (T-01.27 before T-01.18) | T-01.05, T-01.06, T-01.09, T-01.10 for T-01.17; T-01.12–T-01.14, T-01.16 for T-01.18 |
| 6 | T-01.20 | T-01.17, T-01.19 |
| 7 | T-01.23, T-01.24 (then director: T-01.21, T-01.22, T-01.25) | T-01.17, T-01.20 |
| 8 | T-02.02, T-02.04, T-02.05, T-02.07, T-02.09 | T-02.01 (T-02.09 also T-01.17) |
| 9 | T-02.03, T-02.06, T-02.11, T-02.14 | T-02.02, T-02.04, T-02.05 (T-02.14 also T-02.09, T-01.20) |
| 10 | T-02.08, T-02.16 | T-02.06, T-02.07 for T-02.08; T-02.03 for T-02.16 |
| 11 | T-02.10 | T-02.03, T-02.08, T-02.09 |
| 12 | T-02.12 (then director: T-02.13, T-02.15, T-02.17, T-02.18) | T-02.06, T-02.08, T-02.10 |
| 13 | T-03.01, T-03.02, T-03.03, T-03.04, T-03.05, T-03.06 (adapters, disjoint folders; at most D-16 at a time) | T-02.18; T-03.00 for T-03.04 |
| 14 | T-03.07 (then director: T-03.08, T-03.09) | T-03.06 |
| 15 | T-04.01, then T-04.02 and T-04.03 (then director: T-04.04, T-04.05) | T-04.00 |
| 16 | T-05.01 → T-05.02 → T-05.03 (then director: T-05.04–T-05.06) | T-04.05 |

An owner task (T-00.01, T-00.02, T-00.05, T-01.15, T-03.00, T-03.10, T-04.00) is raised with the owner as soon as its dependency is
merged, never at the end of a wave.
