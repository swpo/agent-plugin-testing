# Spoho Style Assistant

Test payload for the Hive Agent Store install pipeline. Not a real product.

When installed as a skill into `.claude/skills/spoho-style-assistant/`, this agent:

- Enforces a distinctive output format (opening/closing phrases, bullet-only, second person)
- Knows a table of personal facts about Spoho
- Exposes a bundled bash script for style auditing

These three mechanics exist so a reader can verify the skill is loaded correctly in three independent ways (format adherence, fact recall, script execution).

## Install (manual, Phase -1)

Unzip the archive into `.claude/skills/spoho-style-assistant/` in your workspace, then ask Claude:

> Is the style assistant installed?

The expected response is defined in `SKILL.md` under *Install verification*.

## Contents

| File | Purpose |
| --- | --- |
| `SKILL.md` | Skill definition (YAML frontmatter + instructions) |
| `manifest.json` | Hive Agent Store metadata |
| `README.md` | This file |
| `scripts/style-check.sh` | Style-linting helper, invokable by the skill |

## Source

Part of the Hive Agent Store experiment. See `~/hive/agent-store/PLAN.md`.
