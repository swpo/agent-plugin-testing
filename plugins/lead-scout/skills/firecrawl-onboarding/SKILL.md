---
name: firecrawl-onboarding
description: "Walks the user through installing and authenticating the Firecrawl CLI. Invoke when the user explicitly asks to set up firecrawl, or when lead-scout defers to this skill because firecrawl is missing. Idempotent — safe to re-run."
---

# Firecrawl Onboarding

Get the Firecrawl CLI installed and authenticated, then record the user's preference so lead-scout doesn't ask again.

## Steps

### 1. Check current state

Run: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-firecrawl.sh` then read `${CLAUDE_PLUGIN_DATA}/firecrawl-status`. Report the state concisely to the user.

### 2. If not installed

Offer the install one-liner. Firecrawl is an npm package:

```
npm install -g firecrawl
```

(On macOS, Homebrew is also an option: `brew install firecrawl` if available in their tap. Default to npm.)

Ask permission before running the install command. If they say yes, run it. If they'd rather install it themselves, wait for them to confirm completion and then rerun the check.

### 3. If installed but not authenticated

Run `firecrawl config` (or `firecrawl login`) to kick off the auth flow. This opens a browser / prompts for an API key — guide the user through it. They can get an API key at [firecrawl.dev](https://firecrawl.dev) and paste it.

### 4. Verify

After setup, run `firecrawl --status`. Confirm authenticated + credits available. If not, surface the error.

### 5. Record the preference

Once firecrawl is set up (or the user declines), write to `${CLAUDE_PLUGIN_DATA}/preferences.md`:

- If now working: append `YYYY-MM-DD: firecrawl_preference: use-firecrawl (setup confirmed)` (only if not already recorded)
- If user declined: append `YYYY-MM-DD: firecrawl_preference: fallback-only (user declined setup)`

lead-scout reads this to decide whether to prompt again.

### 6. Re-run check

Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-firecrawl.sh` one more time so the status file reflects the new state.

## Hand-off

Finish by telling the user what to do next: "Firecrawl is ready — next time you ask me to research leads (`Find <industry> in <geo>...`), I'll use it." Or, for fallback: "I'll use web search + fetch as the fallback — works fine, just uses more tokens per company."

## Idempotency

If firecrawl is already installed and authenticated, just confirm and offer to update the preference if they want. Don't force a reinstall.
