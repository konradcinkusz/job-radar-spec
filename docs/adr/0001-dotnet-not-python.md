# ADR-0001: .NET and C#, not Python

- Status: accepted (the owner confirms it with DECISIONS D-21)
- Date: 2026-11-12

## Context
The owner's analysis left the language open: Python (Playwright for Python, `github-copilot-sdk`, more scraping tools) or .NET
(Playwright for .NET, `GitHub.Copilot.SDK`, the owner's main stack). The standards (P1–P15) and every skill that would guide the
build describe .NET systems: Aspire, a ServiceDefaults kernel, EF Core migrations, xUnit. The chess arena, the only worked
example of the Copilot SDK in the estate, is .NET 10.

## Decision
.NET 10 and C#. Source records are C# records; the closed tool schemas come from records through `JsonSchemaExporter`, which
replaces Pydantic. Playwright for .NET is used for HTTP and for browsers.

## Consequences
- Every standard applies without translation, and the SDK usage is copied from a project that already uses it.
- Fewer ready-made scraping helpers than Python; the adapters are small and written by hand.
- A portfolio reader sees the owner's main stack.

## Alternatives considered
- Python: more scraping libraries and Pydantic, but the standards, the estate's guides, the tests, the CI and the reference SDK
  usage would all have to be re-derived. Rejected.
- A mix (Python adapters, .NET agents): two toolchains for one daily batch job. Rejected.
