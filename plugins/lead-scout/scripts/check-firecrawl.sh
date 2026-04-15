#!/usr/bin/env bash
# check-firecrawl.sh
#
# Called by the SessionStart hook. Probes firecrawl state and writes a
# status file to ${CLAUDE_PLUGIN_DATA}/firecrawl-status. The lead-scout
# orchestrator reads this to decide whether to use firecrawl or fallback.
#
# Auth sources (in priority order):
#   1. CLAUDE_PLUGIN_OPTION_FIRECRAWL_API_KEY — the user's key entered
#      via plugin config UI (keychain-backed, never in chat). We remap
#      it to FIRECRAWL_API_KEY so the CLI picks it up.
#   2. FIRECRAWL_API_KEY env var already in the user's shell env.
#   3. firecrawl CLI's own stored credentials (from `firecrawl config`).
#
# Any of these can produce an authenticated session. We don't care which
# one wins — `authenticated: yes` just means firecrawl --status succeeded.
#
# Output (key: value per line):
#   cli_installed: yes|no
#   plugin_api_key_set: yes|no
#   authenticated: yes|no|unknown
#   credits_remaining: <number>|unknown
#   ready: yes|no
#   checked_at: <ISO8601 UTC>

set -euo pipefail

DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugins/data/lead-scout-hive-store-dev}"
mkdir -p "$DATA_DIR"
STATUS_FILE="$DATA_DIR/firecrawl-status"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Remap plugin userConfig → firecrawl's expected env var.
# This only takes effect for firecrawl calls in this script and anything
# it forks; doesn't leak into other plugin processes.
if [[ -n "${CLAUDE_PLUGIN_OPTION_FIRECRAWL_API_KEY:-}" ]]; then
  export FIRECRAWL_API_KEY="$CLAUDE_PLUGIN_OPTION_FIRECRAWL_API_KEY"
  PLUGIN_KEY_SET="yes"
else
  PLUGIN_KEY_SET="no"
fi

if ! command -v firecrawl >/dev/null 2>&1; then
  {
    echo "cli_installed: no"
    echo "plugin_api_key_set: $PLUGIN_KEY_SET"
    echo "authenticated: unknown"
    echo "credits_remaining: unknown"
    echo "ready: no"
    echo "checked_at: $NOW"
  } > "$STATUS_FILE"
  exit 0
fi

# CLI installed — ask it whether auth works (via any source).
STATUS_OUT="$(firecrawl --status 2>/dev/null | sed $'s/\x1b\\[[0-9;]*[a-zA-Z]//g' || true)"

if echo "$STATUS_OUT" | grep -qi "Authenticated"; then
  AUTHED="yes"
  CREDITS="$(echo "$STATUS_OUT" | awk -F'Credits:' '/Credits:/ {print $2; exit}' | grep -oE '[0-9][0-9,]*' | head -n1 | tr -d ',')"
  [[ -z "$CREDITS" ]] && CREDITS="unknown"
  READY="yes"
else
  AUTHED="no"
  CREDITS="unknown"
  READY="no"
fi

{
  echo "cli_installed: yes"
  echo "plugin_api_key_set: $PLUGIN_KEY_SET"
  echo "authenticated: $AUTHED"
  echo "credits_remaining: $CREDITS"
  echo "ready: $READY"
  echo "checked_at: $NOW"
} > "$STATUS_FILE"
