---
name: firecrawl-onboarding
description: "Walks the user through adding Firecrawl as a remote MCP connector in Claude Desktop. One-time setup that makes Firecrawl's search, scrape, and map tools available in all Cowork sessions. Invoke when the user asks to set up firecrawl, or when lead-scout detects firecrawl tools are missing."
---

# Firecrawl Onboarding

Get Firecrawl's MCP tools available in this Claude session. One-time connector setup — takes ~2 minutes.

## DO NOT ask for the API key in conversation

The key goes into the connector URL (which is stored in Claude Desktop's connector config), NOT into chat. Never ask the user to paste credentials in conversation.

## Step 1 — Check if already set up

Look at your available tools. If you see tools with names like `firecrawl_search`, `firecrawl_scrape`, `firecrawl_map`, or similar `firecrawl_*` patterns, Firecrawl is already connected. Tell the user and stop.

## Step 2 — Walk through the setup

If firecrawl tools are NOT in your available tools:

> Firecrawl isn't connected yet. Here's how to set it up (~2 min, one-time):
>
> 1. **Get a free API key** at [firecrawl.dev/app](https://firecrawl.dev/app) — sign up, then copy the key from your dashboard. Free tier gives you 500 credits.
>
> 2. **Add the connector in Claude Desktop:**
>    - Go to **Customize → Connectors** (or click the `+` icon)
>    - Choose **Add custom connector**
>    - Name: `Firecrawl`
>    - URL: `https://mcp.firecrawl.dev/YOUR_API_KEY_HERE/v2/mcp` — replace `YOUR_API_KEY_HERE` with the key you copied
>    - Save
>
> 3. **Start a fresh conversation.** The Firecrawl tools (search, scrape, map, extract) will be available in every Cowork session from now on.
>
> Once set up, just come back and say "continue the lead research" and I'll pick up where we left off.

**For Claude Code users:** same key, different command:
```
claude mcp add firecrawl --url https://mcp.firecrawl.dev/YOUR_API_KEY_HERE/v2/mcp
```

## Step 3 — Offer the fallback

If the user doesn't want to sign up for Firecrawl right now:

> No worries — I can proceed with the built-in WebSearch + WebFetch fallback. It works well, just a bit slower and without geo-targeting. Say "skip firecrawl" and I'll note it so I don't ask again.

## Step 4 — Record the preference

Append to `${CLAUDE_PLUGIN_DATA}/preferences.md`:

- Set up: `YYYY-MM-DD: firecrawl_preference: use-firecrawl (connector added)`
- Skipped: `YYYY-MM-DD: firecrawl_preference: fallback-only (user declined)`

Only append if not already recorded.

## Step 5 — Verify (if they set it up)

If the user says they've added the connector, check if firecrawl tools are now in your available tools. If yes, confirm. If not, suggest starting a fresh conversation (connectors register at session start).
