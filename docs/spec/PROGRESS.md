# Progress

Measured state, updated by the supervisor after every merge and at every phase checkpoint (SUPERVISOR §9).

Rules, checked by `scripts/check-spec.sh` where a script can check them:

- Statuses: `not-started`, `in-flight`, `open-red`, `open-green`, `merged`, `assumed`, `blocked:<reason>`.
- A row with status `merged` or `open-green` carries a link to the pull request or the CI run it was read from.
- `assumed` means the work was replaced by an unverified assumption (SPEC §12.1). It is never reported as done.
- "Implemented" is not a status. Code on a branch with unit tests green is `open-green`; it says nothing about a gate.
- Every claim has the date it was measured. A claim nobody re-measured is stale, not true.

| Task | Status | Evidence (PR or run link) | Measured | Notes |
|---|---|---|---|---|
| T-00.01 | not-started | | | |
| T-00.02 | not-started | | | |
| T-00.03 | not-started | | | |
| T-00.04 | not-started | | | |

## Gates

One line per gate of SPEC §14: `not claimed`, `claimed <date>` with the proof link and the commit, or `failed <date>` with the evidence.
Say exactly what the proof covers and what it does not (platform, start command, real dependency or stand-in).

- **M0**: not claimed.
- **M1**: not claimed.

## Not shown yet

What is still unproven although the code exists (for example: three consecutive green runs on one commit; a run on a second
platform; a run against the real dependency). This list is part of every status report.

- {{item}}

## Owner actions outstanding

- {{setting, account or hardware only the owner can provide}}
