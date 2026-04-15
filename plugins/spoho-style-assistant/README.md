# spoho-style-assistant

Test payload for the Hive Agent Store plugin pipeline. Not a real product.

Ships as a Claude Code / Cowork plugin via the Hive development marketplace. Demonstrates:

- A persona-shaping **skill** that's always active when the plugin is enabled
- **Memory discipline** via `${CLAUDE_PLUGIN_DATA}` — the agent reads/writes a running log of learned facts
- A **bundled helper script** (`scripts/style-check.sh`) referenced via `${CLAUDE_PLUGIN_ROOT}`
- Three independent ways to verify the install worked: response format, personal-fact recall, script invocation

## Install (via the Hive dev marketplace)

In Claude Code:

```
/plugin marketplace add <path-to-repo>
/plugin install spoho-style-assistant@hive-store-dev
/reload-plugins
```

In Cowork: Organization settings → Plugins → Add plugin → GitHub → point at this repo. Then install the plugin through the Marketplace UI.

## Acceptance tests

After install, try these:

1. `Is the style assistant installed?` — should respond in the strict format with the verification bullet list
2. `What's my favorite food?` — should answer "Spicy Korean BBQ short rib tacos" wrapped in the style rules
3. `Style-check this file: <any markdown file>` — should run `scripts/style-check.sh` and report its output
4. `What do you remember about me?` — on a fresh install, should read `${CLAUDE_PLUGIN_DATA}/memory.md` (may be empty) and report honestly

## Contents

| File | Purpose |
| --- | --- |
| `.claude-plugin/plugin.json` | Plugin manifest |
| `skills/spoho-style-assistant/SKILL.md` | The persona, style rules, memory discipline, personal facts |
| `scripts/style-check.sh` | Prose linter — referenced by the skill via `${CLAUDE_PLUGIN_ROOT}` |
| `README.md` | This file |

## Source

Part of the Hive Agent Store experiment. See `../../PLAN.md`.
