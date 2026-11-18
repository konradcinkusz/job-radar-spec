# Front end: proof of concept

`poc.html` is a single-file mock-up of a front end for JobRadar. Open it in a browser; it needs no build and no server (it loads two fonts from Google Fonts and falls back to system fonts offline).

**Status:** a proposal for whoever builds the front end. It is not part of the spec: D-03 still lists a front end as a non-goal, so a decision is needed before any of this is built.

## What it shows

| View | Question it answers |
|---|---|
| Dziś | Which new offers are worth reading today? Poland first, filters, search, detail panel, feedback buttons |
| Źródła | Can today's report be trusted? Offer count per source against its median, disabled sources with the reason |
| Lejek | Are the criteria too strict? Prefilter rejections by reason, liveness results and why some stayed unverified |
| Przebiegi | Where did the time go in each run, including waiting for self-hosted runners |
| Kontrakt danych | The JSON file the pipeline would have to write for the page to read |

## What is real and what is not

- Real: offers, source counts, prefilter counts and liveness results, copied from the reports of 2026-11-17 and 2026-11-18.
- Example data: AI scores and tracks (the agents have not run on a real model yet), and three of the five points in each source sparkline. The page marks both.
- Mock-up only: the feedback buttons store nothing.

## Open decisions

- Change D-03, or keep the front end outside this project.
- Hosting: the code repository is private, so the browser needs another way to read the JSON files.
- Feedback from the browser needs something that accepts a write; without a server it can only open the existing feedback workflow.
- The JSON export (`reports/YYYY-MM-DD.json`) does not exist yet. The page's last view proposes its shape; every field is already in the database or in the stage summaries.
