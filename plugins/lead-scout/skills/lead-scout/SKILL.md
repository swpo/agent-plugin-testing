---
name: lead-scout
description: "Lead research orchestrator. Use when the user asks to find companies matching criteria, build a prospect list, research leads in an industry, find businesses with specific website features, or compile contact info for a target industry. Runs the full discover → filter → extract → compile pipeline."
---

# Lead Scout

You are the orchestrator for a lead research workflow. When invoked, you decompose the user's request, run a parallelized research pipeline, and produce a CSV of leads with a run log.

## Workflow

### 1. Load context

Read `${CLAUDE_PLUGIN_DATA}/preferences.md` if it exists — user's recorded preferences (geography, CSV columns, skip-list, tool preferences). Apply implicitly. Don't dump to the user.

Check whether Firecrawl MCP tools are available in this session by looking at your available tools for names like `firecrawl_search`, `firecrawl_scrape`, `firecrawl_map`, or similar `firecrawl_*` patterns. This tells you whether the user has added the Firecrawl connector to Claude Desktop.

### 2. Parse the request

From the user's prompt, extract:

- **industry** — what kind of company (e.g. "title insurance", "pilates studios")
- **geography** — city/state/region/country, if specified
- **constraint** — the website-level filter in natural language (e.g. "has a contact page", "offers private instruction"). May be absent — that's valid, it just means "compile a plain list, no filter."
- **batch_size** — how many candidates to research. Default 15.
- **output_columns** — CSV columns. Default: `company_name, url, match_status, match_evidence, contact_page_url, email, phone, address, principal_name, notes`.

Classify each field as one of three states:

- **Missing** — nothing in the prompt, nothing in `${CLAUDE_PLUGIN_DATA}/preferences.md`.
- **Vague** — present but underspecified (e.g., geography = "California" when looking for local businesses — a whole state is too broad for a 15-item sample; constraint = "good" or another subjective term).
- **Present** — explicit and unambiguous enough to proceed.

Rules:

- **Industry missing** → blocking, ask.
- **Geography missing** AND no default in preferences → blocking, ask. A default like "use my usual focus" counts as present.
- **Constraint missing** → **not** blocking. Proceed with `constraint = null`; the subagents will skip the per-site constraint check and just extract contact info.
- **Any field vague** → proceed, but commit to a concrete interpretation and surface it in step 2b so the user can redirect.
- **batch_size / output_columns** → silent defaults if unspecified.

### 2a. Clarify only when something is blocking

When a blocking field is missing, bundle the questions into a single message and offer sensible defaults. Example:

> I need a bit more to go on:
> - **Industry** — what type of company? (e.g. "title insurance", "pilates studios")
> - **Geography** — any specific area, or go nationwide / use your usual focus?
> - **Constraint** (optional) — any website requirement like "has a contact page", or just compile a plain list?
>
> Or say "use defaults" and I'll pick reasonable ones.

Ask at most once per run. If the user says "use defaults" or "you pick," proceed with your best interpretations and surface them in the preview.

### 2b. Preview before spending credits

Before calling any search API, echo back a one-line preview of what you're about to do and pause for confirmation. Format:

> Planning: ~15 pilates studios in Austin, TX. Constraint: "offers private instruction". Output: CSV in the current directory. Ok to proceed?

If you resolved any vagueness, flag the interpretation explicitly so the user can redirect:

> Planning: ~15 pilates studios. "California" is broad for a 15-item sample — I'll focus on the top 3 metros (LA, SF Bay, San Diego) unless you prefer a specific city. Constraint: "offers private instruction". Ok?

> Planning: ~15 locksmiths in Denver. "Trustworthy" is subjective — I'll interpret as "business has been operating 3+ years AND has a visible professional license on the site." Ok, or different bar?

This preview is the cheapest redirect point — before any credits/tokens are spent. Skip it only if the user preemptively said "just run it" or "no need to confirm."

### 3. Verify tooling

Check for Firecrawl MCP tools in your available tools (done in step 1). **Never ask the user for their API key in conversation** — the key is embedded in their connector URL, stored in Claude Desktop's connector config.

| Firecrawl tools available? | Preference | Action |
|---|---|---|
| Yes | any | Use firecrawl MCP tools (`firecrawl_search`, `firecrawl_scrape`, etc.) |
| No | `firecrawl_preference: fallback-only` | Use WebSearch + WebFetch silently |
| No | unset or `use-firecrawl` | Before starting, say: "Firecrawl isn't connected. Want me to walk you through the setup (~2 min, one-time), or proceed with the WebSearch/WebFetch fallback?" If they choose setup, invoke the `firecrawl-onboarding` skill. Record the choice in `preferences.md` so you don't ask again. |

### 4. Discover candidates

Invoke the `discover-companies` skill's guidance. Target `batch_size` distinct candidates by root domain, from 1-3 sources in parallel. Drop anything in the skip-list. Present the candidate list to the user as a 1-line-per-row summary and get an "ok, proceed" before spending credits on scraping.

### 5. Parallel constraint-check + extraction

For each candidate, spawn a subagent (Agent tool, `subagent_type: "general-purpose"`) with a prompt built from the `extract-contact` skill's template. Batch in groups of 5-10 to respect firecrawl's concurrency limit and avoid flooding your own context.

Pass to each subagent:
- `company_name`, `url`
- `constraint` (the natural-language filter)
- `output_columns` (what fields it needs to return)
- `firecrawl_available` (bool — determines whether the subagent should use firecrawl or fallback)

Each subagent returns a JSON object; the content must match `output_columns` plus `match_status` (`match` | `no-match` | `uncertain` | `error`) and `match_evidence`.

### 6. Compile output

Write outputs to the **user's current working directory** (use `pwd` via Bash if unsure). Timestamp with `date +%Y%m%d-%H%M%S`:

1. `leads-<ts>.jsonl` — one JSON per line, the raw per-company results
2. `leads-<ts>.csv` — run `python3 ${CLAUDE_PLUGIN_ROOT}/scripts/compile-csv.py <jsonl> <csv> "<comma-separated-columns>"`
3. `leads-<ts>.log` — markdown summary with: query, sources used, N candidates / N matches / N errors, notable patterns or failures worth the user's eye

### 7. Record lessons

If the user gave feedback during the run that reveals a durable preference, append a one-liner to `${CLAUDE_PLUGIN_DATA}/preferences.md` with today's date.

Good lessons (append):
- `2026-04-15: User focuses on North America — default geo when unspecified.`
- `2026-04-15: User prefers CSV columns: name, url, email, phone, principal_name.`
- `2026-04-15: Skip domain: example-scammy-directory.com — aggregator, not useful.`

Not lessons (do not append):
- One-off request details
- Things that are obvious from context

Keep entries terse. If `preferences.md` exceeds ~200 lines, consolidate.

### 8. Report

Summarize: N matches / N attempted, where the CSV is, any caveats (sites that errored, patterns you noticed). Offer to dump the CSV contents, filter, or re-run with different criteria.

## Sub-skill references

- `discover-companies` — how to find candidates across sources
- `extract-contact` — per-company check + extraction (used as the subagent prompt template)
- `firecrawl-onboarding` — connector setup walkthrough if firecrawl tools aren't available

## Guardrails

- Respect credits: firecrawl charges ~1 credit per scrape. A batch of 15 with some follow-ups is ~15-30 credits. If you can check credits via a firecrawl MCP tool, warn the user when low.
- Don't scrape behind logins, don't bypass CAPTCHAs. If a site is gated, mark `match_status: error` with a brief reason.
- The constraint check is agent judgment, not regex. Err toward `uncertain` over false `match` — the user would rather review a shortlist than chase bad leads.
