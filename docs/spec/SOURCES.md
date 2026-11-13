# Sources

> Part of the specification. Source of the facts: the owner's analysis of 12 November 2026, amended by the first probe of 13 November 2026 (job-radar `docs/spikes/probe-2026-11-13.md`, run https://github.com/konradcinkusz/job-radar/actions/runs/43508296521): rows marked "probed" were called once from a hosted runner. ~~Nothing here was called.~~ Rows not marked "probed" were not called. "Confirmed"
> means the official documentation says so; "indirect" means the facts come from descriptions of other people's tools. The first
> task that touches a source (a `probe.yml` run from a hosted runner) checks the endpoint, saves the response as a fixture and
> amends this file before the adapter is written. An amendment to a row lands in the same pull request as the probe.
>
> Why the sandbox of the specification author did not probe: it could not reach any of these hosts. A director session may be
> in the same position, so probes run in GitHub Actions and their output is read back from the run.

## 1. How a source is chosen

Preference order, from the analysis: official or documented API, then published JSON or RSS, then a JSON endpoint of a portal, then
HTML with embedded state, then a browser. Direct employers beat intermediaries: an ATS board is the employer's own posting.
Precedence for duplicates follows the same line (`SourceKind`: `ats` 3, `portal` 2, `aggregator` 1).

## 2. Table

| Id | Kind | Market | Access | Entry point | Status | Stage | Notes and limits |
|---|---|---|---|---|---|---|---|
| `greenhouse` | ats | companies, global | public API, no key | `boards-api.greenhouse.io/v1/boards/{slug}/jobs?content=true` | confirmed | 0 | One company per request; filter on our side; needs a slug list |
| `ashby` | ats | companies, global | public API, no key | `api.ashbyhq.com/posting-api/job-board/{slug}?includeCompensation=true` | confirmed | 0 | One company per request; carries pay when the company publishes it |
| `remotive` | aggregator | remote, global | public API and RSS | `remotive.com/api/remote-jobs`, `remotive.com/feed` | confirmed | 0 | Offers delayed 24 h; a link back and a mention of the source are required; do not redistribute |
| `lever` | ats | companies, global | public API, no key | `api.lever.co/v0/postings/{slug}?mode=json` | probed 2026-11-13: 200, JSON array | 2 | One company per request |
| `nofluffjobs` | portal | PL, CEE | unofficial public JSON | `nofluffjobs.com/api/search/posting` (**POST**, `Content-Type: application/infiniteSearch+json`, body `{"rawSearch":"...","page":1}`), `/api/posting/{id}` | probed 2026-11-13: search answered 200 from a hosted runner; detail endpoint not probed | 2 | The site sits behind Cloudflare, the API reportedly does not; pay ranges are mandatory; may change without notice |
| `justjoinit` | portal | PL | unofficial public JSON and JSON-LD | **unknown**: `api.justjoin.it/v2/user-panel/offers/by-cursor` answered 503 (nginx) and `justjoin.it/job-offers/all-locations/backend` answered 404 on 2026-11-13; the real listing endpoint is to be found before T-03.03 | probed, differs | 2 | At most 10 000 offers per search; the listing is infinite scroll and `page=` does not work |
| `adzuna` | aggregator | ES, PL, CH and others | official API, `app_id` and `app_key` | `api.adzuna.com/v1/api/jobs/{country}/search/{page}` | confirmed | 2 | Free registration; free-plan limits; includes agencies, so the Extractor's `employer_type` matters most here |
| `weworkremotely` | aggregator | remote, global | RSS | `weworkremotely.com/remote-jobs.rss` and category feeds | probed 2026-11-13: 200, RSS 2.0 (`dc:`, `media:`), `ttl` 60 | 2 | About 90 newest offers; refreshed about hourly |
| `pracuj` | portal | PL | HTML with embedded `__NEXT_DATA__` | search pages of `pracuj.pl` and `it.pracuj.pl` | indirect | 3 | Browser or `__NEXT_DATA__` parsing |
| `infojobs` | portal | ES | official API (basic auth `client_id:secret`) or HTML | `api.infojobs.net/api/1/offer` | indirect | 3 | Register an application at `developer.infojobs.net`; access terms to be read first |
| `remoteok`, `himalayas`, `jobicy`, `arbeitnow` | aggregator | remote or EU | public API | to be established | indirect | backlog | RemoteOK needs a link back. Himalayas terms forbid passing offers on: own use only. Not built until a source needs them |
| `linkedin`, `indeed` | | global | | | **excluded** | never | Terms forbid scraping; the owner has no LinkedIn account. The config loader refuses these ids (SPEC §6.2) |

Recommended start (analysis): Greenhouse, Ashby and Lever for 50–150 target companies, No Fluff Jobs, justjoin.it, Adzuna (ES, PL),
We Work Remotely and Remotive. Pracuj.pl and InfoJobs come last, as browser sources.

## 3. Per-adapter acceptance (every source)

A source task is accepted only when all of this holds, each with a named test:

1. `Normalize` maps the recorded fixture to valid `RawOffer` records; the fixture has at most 5 postings and was recorded by
   `probe.yml` (or is marked "shape from documentation, not recorded" and the gate for that source cannot be claimed).
2. Missing optional fields produce nulls, never exceptions; a malformed posting is skipped and counted in `Errors`, and the
   rest of the run continues.
3. `Id`, `Kind`, the endpoint and the attribution requirement are in `sources.yaml` and in this table.
4. The adapter uses `SourceHttp` only (no direct `HttpClient`, no `Thread.Sleep`).
5. For an HTML host the robots guard is called before the first request.
6. `Health()` counts offers found and errors.
7. Salary, currency and period are carried as given; remote or hybrid statements are mapped to `WorkMode` only when the source
   states them, else `unknown`.

## 4. Per-source notes the adapters must respect

- **Greenhouse.** `content=true` returns the description as HTML **that is itself entity-escaped** (probe 2026-11-13: `&lt;h2&gt;...`): the adapter decodes entities first, then converts the HTML to text (tags removed, entities decoded again, list items kept as lines). A whole board of one company is about 6 MB, so detail is never fetched per posting. `source_id` is the job id; the board slug is part of `url` and of the company name when the API
  gives no name.
- **Ashby.** The posting carries `descriptionPlain` (use it) and `isListed`; a whole board is about 3 MB. Pay is optional: absent compensation is null, not zero. Listed and unlisted postings are distinguished by the API;
  only listed ones are taken.
- **Remotive.** The response carries `0-legal-notice` and `00-warning` fields (read them in T-01.14 and keep their requirements). Keep the attribution string in `RawOffer.Attribution`; the report line for a Remotive offer links to the Remotive
  page. Because of the delay, `first_seen_at` is the day we saw it and `posted_at` the source's own date.
- **Adzuna.** Redirect links go through Adzuna; the liveness check follows redirects up to 3 hops and the canonical employer URL,
  when the API provides one, is kept as `url`. Keys come from `ADZUNA_APP_ID` and `ADZUNA_APP_KEY`; a missing key disables the
  source.
- **No Fluff Jobs, justjoin.it.** Unofficial endpoints can change without notice; these are the most likely sources to trip the
  health alert and are the first candidates for the Repairer.
- **We Work Remotely.** An RSS feed holds about 90 items, so one daily run sees only recent offers; missing offers older than that
  must not count as `missed_runs` evidence of expiry for this source (`expiry_by_absence: false` in `sources.yaml`).
