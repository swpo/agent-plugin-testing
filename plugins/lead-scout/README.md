# lead-scout

Lead research agent. Given an industry, a geography, and a website-level constraint, produces a CSV of companies matching the constraint with their contact information. Designed for runs of ~15 companies at a time; configurable.

## What it does

Takes a prompt like:

> Find title insurance companies in California that have a contact page on their website.

And produces:

- `leads-<timestamp>.csv` in the current working directory — the lead list
- `leads-<timestamp>.jsonl` — raw per-company JSON records
- `leads-<timestamp>.log` — markdown summary of the run

## How it works

Four-stage pipeline orchestrated by the `lead-scout` skill:

1. **Discover** (`discover-companies` skill) — finds candidates via Firecrawl search, WebSearch, and/or directories like Google Maps / Yelp, depending on the industry and what's available
2. **Filter + extract** (parallel subagents using `extract-contact` skill) — one subagent per candidate, each fetches the site, checks the constraint, and pulls contact info. Batched 5–10 at a time.
3. **Compile** — writes JSONL, generates CSV via `scripts/compile-csv.py`
4. **Log + learn** — writes a run summary; appends any durable user preferences to `${CLAUDE_PLUGIN_DATA}/preferences.md` for future runs

## Firecrawl

Preferred search backend. On install and at every session start, a hook checks whether Firecrawl is installed + authenticated, and writes the status to `${CLAUDE_PLUGIN_DATA}/firecrawl-status`.

- **If Firecrawl is ready:** used automatically
- **If not:** `firecrawl-onboarding` skill walks the user through install + auth. User can decline and use the fallback instead — their choice is recorded so they aren't re-asked

Fallback uses Claude's native `WebSearch` + `WebFetch` tools.

## Memory

Persistent state in `${CLAUDE_PLUGIN_DATA}/`:

- `preferences.md` — geographic defaults, CSV column defaults, domain skip-list, firecrawl preference. Terse one-liner entries with dates.
- `firecrawl-status` — ephemeral runtime state, rewritten on each session start

## Contents

| File | Purpose |
| --- | --- |
| `.claude-plugin/plugin.json` | Plugin manifest |
| `skills/lead-scout/SKILL.md` | Orchestrator — the entry point |
| `skills/discover-companies/SKILL.md` | Multi-source candidate discovery |
| `skills/extract-contact/SKILL.md` | Per-company check + extraction (used as subagent prompt template) |
| `skills/firecrawl-onboarding/SKILL.md` | Guided setup for the Firecrawl CLI |
| `scripts/check-firecrawl.sh` | Status probe, called by the SessionStart hook |
| `scripts/compile-csv.py` | JSONL → CSV helper |
| `hooks/hooks.json` | Registers the SessionStart hook |

## Usage

Install:

```
/plugin marketplace add swpo/agent-plugin-testing
/plugin install lead-scout@hive-store-dev
/reload-plugins
```

Then just ask Claude:

> Find pilates studios in Austin, Texas that offer private instruction. Run 15.

The orchestrator handles the rest.

## Design choices worth knowing

- **Parallel subagents, not parallel context.** Each candidate is evaluated in an isolated subagent so full site content never hits the main conversation's context window. Main Claude sees only compact per-company JSON.
- **Constraint check is agent judgment, not regex.** Semantic constraints ("offers private instruction") are evaluated by reading the site, not by pattern-matching. Err toward `uncertain` over false `match`.
- **Multi-source discovery.** General search covers B2B / nationwide; local directories (Maps, Yelp) cover local services. Picked per industry.
- **Cwd-local output.** CSVs and logs land in the user's current working directory so they're alongside whatever project prompted the research.

## Status

v0.1.0 — first test version. Things to learn from real runs:
- Does the multi-source discovery produce enough unique candidates?
- How often do sites 404 / anti-bot / JS-out-of-reach? Worth adding retry logic?
- Is 5–10 subagents in parallel the right batch size, or can we go higher?
