#!/usr/bin/env python3
"""Compile JSONL lead records into a CSV file.

Usage:
    compile-csv.py <input.jsonl> <output.csv> [<comma-separated-columns>]

If columns are omitted, a default set is used.
"""
from __future__ import annotations

import csv
import json
import sys

DEFAULT_COLUMNS = [
    "company_name",
    "url",
    "match_status",
    "match_evidence",
    "contact_page_url",
    "email",
    "phone",
    "address",
    "principal_name",
    "notes",
]


def main() -> int:
    if len(sys.argv) < 3:
        print(
            "usage: compile-csv.py <input.jsonl> <output.csv> [columns-comma-separated]",
            file=sys.stderr,
        )
        return 64

    input_path = sys.argv[1]
    output_path = sys.argv[2]
    columns = (
        [c.strip() for c in sys.argv[3].split(",") if c.strip()]
        if len(sys.argv) > 3
        else DEFAULT_COLUMNS
    )

    rows: list[dict] = []
    with open(input_path, encoding="utf-8") as f:
        for lineno, line in enumerate(f, start=1):
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError as e:
                print(f"warn: line {lineno} is not valid JSON, skipping: {e}", file=sys.stderr)

    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=columns, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow({c: row.get(c, "") for c in columns})

    print(f"wrote {len(rows)} rows to {output_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
