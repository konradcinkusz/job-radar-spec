# ADR-0003: Agents run in `CopilotClientMode.Empty` with one custom tool each

- Status: accepted (to be confirmed by the spike T-02.01)
- Date: 2026-11-12

## Context
The agents read text written by strangers (job offers), so prompt injection is the main risk. The Copilot SDK defaults to the
behaviour of the Copilot CLI with all tools allowed (file system, Git, network). The chess arena avoided this by giving its
sessions an empty tool list and a reject-all permission handler; its own notes say that whether an empty list means "no tools"
was not confirmed. SDK 1.0.28 documents `CopilotClientMode.Empty`, which exposes no tools unless a session lists them, and
custom tools with `SkipPermission` and `IsTerminal` options.

## Decision
Every agent session uses a client in `CopilotClientMode.Empty`, an `AvailableTools` list that names only that agent's own tool,
a rejecting permission handler, and the system message in `Replace` mode. The tool is the agent's only output channel, with a
closed schema. Offer text is delimited by a random per-call nonce. Writes to the repository, database and GitHub are done by
workflow code. The Repairer is the one agent with file access, through three tools jailed to one source's folder.

## Consequences
- An injected instruction has no tool to act with, other than saving a (validated, capped) result.
- A live tool-surface check (T-02.01) must show it. Until it does, SPEC §1.1 goal 6 is an assumption (A-02).
- If the SDK does not behave as documented, SPEC §6.5 is amended before the runner is built.

## Alternatives considered
- An empty `AvailableTools` list in default mode, as in the chess arena: relies on an unconfirmed reading. Rejected as the sole guard.
- `gh aw` (Agentic Workflows) for all agents: less control over schema and batching. Kept only as an option for the Reporter.
