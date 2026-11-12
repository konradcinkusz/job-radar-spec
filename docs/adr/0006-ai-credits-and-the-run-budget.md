# ADR-0006: Cost is counted in AI credits, with a budget per run

- Status: accepted
- Date: 2026-11-12

## Context
The analysis says each prompt uses a premium request from the monthly pool and therefore sends 10–20 offers per prompt. The chess
arena, whose notes were written later, records that GitHub Copilot has billed chat in AI credits, metered per token, since June
2026, and that a model's multiplier can be null. The unit conversion (1 AI unit = 1 credit) was not confirmed live there.

## Decision
- Batching (15 offers by default) is kept: it still lowers per-offer overhead.
- Cost is measured as AI credits per batch from the usage events and shown with a dollar figure. It never enters a score.
- `Agents:MaxAiCreditsPerRun` (start 20, replaced by the first measured value) stops new batches; unevaluated offers are reported
  as such and retried the next day.
- A `ByokAgentRunner` is built behind `IAgentRunner` so a different billing model can be switched in without touching the stages.

## Consequences
- The monthly cost is bounded by `budget × days`, not by the number of offers on a busy day.
- Whether the Copilot subscription covers the usage, or bills extra, is something the owner checks on the billing page; the
  spike T-02.01 compares one measured run with it.

## Alternatives considered
- No budget: a bad day could spend the monthly allowance. Rejected.
- Bring your own key from the start: predictable cost, but a second account and key to manage before the value is proven.
  Kept as a ready fallback.
