#!/usr/bin/env bash
# check-firecrawl.sh
#
# Called by the SessionStart hook. Inspects the firecrawl CLI state and
# writes a simple status file to ${CLAUDE_PLUGIN_DATA}/firecrawl-status.
# The lead-scout orchestrator skill reads this file to decide whether
# to prompt for onboarding.
#
# Output format (text, key: value per line):
#   installed: yes|no
#   authenticated: yes|no
#   credits_remaining: <number>|unknown
#   checked_at: <ISO8601 UTC>

set -euo pipefail

DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugins/data/lead-scout-hive-store-dev}"
mkdir -p "$DATA_DIR"
STATUS_FILE="$DATA_DIR/firecrawl-status"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if ! command -v firecrawl >/dev/null 2>&1; then
  {
    echo "installed: no"
    echo "authenticated: no"
    echo "credits_remaining: unknown"
    echo "checked_at: $NOW"
  } > "$STATUS_FILE"
  exit 0
fi

STATUS_OUT="$(firecrawl --status 2>/dev/null | sed $'s/\x1b\\[[0-9;]*[a-zA-Z]//g' || true)"

if echo "$STATUS_OUT" | grep -qi "Authenticated"; then
  AUTHED="yes"
  # Firecrawl --status prints something like:
  #   Credits: 1,771 / 3,000 (59% left this cycle)
  # Pull the first numeric token from the Credits line.
  CREDITS="$(echo "$STATUS_OUT" | awk -F'Credits:' '/Credits:/ {print $2; exit}' | grep -oE '[0-9][0-9,]*' | head -n1 | tr -d ',')"
  [[ -z "$CREDITS" ]] && CREDITS="unknown"
else
  AUTHED="no"
  CREDITS="unknown"
fi

{
  echo "installed: yes"
  echo "authenticated: $AUTHED"
  echo "credits_remaining: $CREDITS"
  echo "checked_at: $NOW"
} > "$STATUS_FILE"
