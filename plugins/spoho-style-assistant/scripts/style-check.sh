#!/usr/bin/env bash
# style-check.sh — lightweight prose style linter for spoho-style-assistant
# Usage: bash style-check.sh <file>
#
# Flags: passive voice markers, weasel words, overlong sentences.
# Deliberately simple so the output is easy to read when confirming a
# successful plugin install.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: style-check.sh <file>" >&2
  exit 64
fi

FILE="$1"

if [[ ! -f "$FILE" ]]; then
  echo "style-check: file not found: $FILE" >&2
  exit 66
fi

echo "style-check v1.0.0 — auditing: $FILE"
echo "--------------------------------------------------"

PASSIVE=$(grep -n -E '\b(was|were|been|being|is|are)\s+\w+(ed|en)\b' "$FILE" || true)
if [[ -n "$PASSIVE" ]]; then
  echo "[passive voice candidates]"
  echo "$PASSIVE"
  echo
fi

WEASEL=$(grep -n -i -E '\b(very|really|quite|somewhat|rather|arguably|basically|essentially|literally|obviously|clearly|simply|just)\b' "$FILE" || true)
if [[ -n "$WEASEL" ]]; then
  echo "[weasel words]"
  echo "$WEASEL"
  echo
fi

LONG=$(awk 'BEGIN{RS="\\. "} NF>30 {gsub(/\n/," "); print NR": "substr($0,1,120)"... ("NF" words)"}' "$FILE" || true)
if [[ -n "$LONG" ]]; then
  echo "[long sentences (>30 words)]"
  echo "$LONG"
  echo
fi

if [[ -z "$PASSIVE" && -z "$WEASEL" && -z "$LONG" ]]; then
  echo "no style issues detected."
fi

echo "--------------------------------------------------"
echo "done."
