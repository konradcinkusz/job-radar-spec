# ADR-0005: Hard exclusions are applied by code after the model answers

- Status: accepted
- Date: 2026-11-12

## Context
The analysis says that hard exclusions (German above basic level, regular office presence outside Spain, an agency employer)
give score 0 "regardless of the rest". If the Scorer applies them, an injected description can talk the model out of them.

## Decision
The Extractor produces facts (`employer_type`, `languages`, `office_days_per_week`, `office_country`, `b2b_allowed`). The Scorer
proposes a track and a score. `HardExclusions.Apply`, a pure function in `JobRadar.Core`, then caps the score from the validated
facts and the criteria. The model's opinion on an excluded point is ignored. Injection patterns exclude an offer in code as well.

## Consequences
- The exclusions are unit-testable and cannot be bypassed by text in an offer.
- A wrong extraction still produces a wrong exclusion; evidence quotes (verified by substring) and the owner's feedback are the
  controls.

## Alternatives considered
- The Scorer applies the rules: simpler prompt, but the rules would live in a probabilistic layer. Rejected.
