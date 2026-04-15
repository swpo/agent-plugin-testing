---
name: firecrawl-onboarding
description: "Guides the user through getting Firecrawl set up for the lead-scout plugin — obtaining an API key, entering it via the secure plugin config UI, and verifying it works. Invoke when the user asks about firecrawl setup or when lead-scout defers to this skill."
---

# Firecrawl Onboarding

Get Firecrawl working with the lead-scout plugin. The API key is handled by Claude's plugin config system (keychain-stored, never visible in chat).

## DO NOT ask for the API key in conversation

It is **not** safe or correct to have the user paste their API key into chat. The conversation transcript would preserve it. Use the plugin config UI instead — that's what it's for.

## Step 1 — Read current state

Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-firecrawl.sh` and read `${CLAUDE_PLUGIN_DATA}/firecrawl-status`. Summarize the state:

- `cli_installed: yes|no` — is the `firecrawl` CLI available?
- `plugin_api_key_set: yes|no` — has the user entered a key via plugin config?
- `authenticated: yes|no` — does `firecrawl --status` succeed (any auth source)?
- `ready: yes|no` — cli + auth both good?

## Step 2 — Walk the user through what's needed

Based on state, one of these:

### Case A: `ready: yes`

> Firecrawl is set up and working — credits remaining: N. You're good to go.

Nothing else to do.

### Case B: `cli_installed: yes, authenticated: no` (no stored creds, no plugin key)

The CLI is there; they just need to enter their API key.

> You have the Firecrawl CLI installed, but no API key is configured yet.
>
> 1. Get a free API key at [firecrawl.dev](https://firecrawl.dev) — sign up, then copy the key from your dashboard.
> 2. Enter it via the plugin config UI:
>    - **Claude Code**: run `/plugin`, go to the Installed tab, select `lead-scout@hive-store-dev`, choose Configure.
>    - **Cowork**: Organization settings → Plugins → `lead-scout` → Configure.
> 3. Paste the key into the `firecrawl_api_key` field. It's stored in your system keychain and never sent to me in conversation.
>
> After saving, open a fresh session (or restart Claude Code) and I'll pick it up.

### Case C: `cli_installed: no, plugin_api_key_set: yes`

They have a key but no CLI. The CLI is a convenience wrapper — the key lets us hit the Firecrawl API either way, but some commands (parallel scrape, map) are easier with the CLI.

> Your Firecrawl API key is saved. The `firecrawl` CLI isn't installed in this environment, which limits what we can do with it. Options:
>
> 1. Install the CLI: `npm install -g firecrawl` (local shell). On Cowork's sandbox, this may or may not be permitted.
> 2. Proceed anyway — I'll use the Firecrawl HTTP API directly via curl for what I can, and fall back to WebSearch/WebFetch for the rest.

### Case D: `cli_installed: no, authenticated: no`

Nothing set up.

> Firecrawl isn't set up yet. You have two paths:
>
> - **Use Firecrawl** (better quality, uses ~1 credit per page scrape):
>   1. Sign up at [firecrawl.dev](https://firecrawl.dev) and copy your API key.
>   2. Enter it via the plugin config UI — see Case B above.
>   3. Optionally install the CLI: `npm install -g firecrawl`
>
> - **Skip firecrawl** (use built-in `WebSearch` + `WebFetch` fallback, works fine, slightly slower and no geo-targeting):
>
>   Just say "skip firecrawl" and I'll note it in your preferences so lead-scout won't mention it again. You can revisit anytime by invoking this skill (`firecrawl-onboarding`).

## Step 3 — Record the preference

If the user set up firecrawl, or chose to skip, append to `${CLAUDE_PLUGIN_DATA}/preferences.md`:

- Set up: `YYYY-MM-DD: firecrawl_preference: use-firecrawl (onboarding completed)`
- Skipped: `YYYY-MM-DD: firecrawl_preference: fallback-only (user chose fallback)`

Only append if not already recorded — keep the file clean.

## Step 4 — Re-probe

If they set up firecrawl, run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-firecrawl.sh` once more to refresh the status file.

## Hand-off

Close with a one-liner telling the user what happens next time they ask for lead research.
