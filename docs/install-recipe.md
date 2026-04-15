# Install Guide

How a Hive agent plugin gets installed into Claude Code or Cowork. The mechanism is platform-native — no custom scripting; we're using the standard Claude plugin system.

## From the Hive dev marketplace (this repo)

For local testing during Phase -1/0.

### Claude Code

From anywhere in Claude Code:

```
/plugin marketplace add /Users/spoho/hive/agent-store
/plugin install spoho-style-assistant@hive-store-dev
/reload-plugins
```

`/plugin marketplace add` also accepts GitHub shorthand (`owner/repo`) or a direct URL to a `marketplace.json` file.

Check it loaded:

```
/plugin
```

Go to the **Installed** tab — `spoho-style-assistant@hive-store-dev` should be present. If loading fails, check the **Errors** tab.

### Cowork

1. In Cowork: **Organization settings → Plugins → Add plugin → GitHub**
2. Paste repo URL: `https://github.com/swpo/agent-plugin-testing` (or `swpo/agent-plugin-testing` shorthand)
3. From the Marketplace UI, find `spoho-style-assistant` and click **Install**

Cowork's plugin install is per-workspace-or-org — the exact scope depends on which install button you pick.

### Claude Code from the GitHub repo (alternative to the local path)

```
/plugin marketplace add swpo/agent-plugin-testing
/plugin install spoho-style-assistant@hive-store-dev
```

## Acceptance tests

After install, in a fresh conversation in the target runtime, try:

**Test 1 — verify activation**

> Is the style assistant installed?

Expected: response follows the strict style rules (opens with `Got it, here's the rundown:`, bullet points only, second person, closes with `— spoho-style-assistant`), includes the verification bullet list with version, rules loaded, personal facts count, helper script path, memory path.

**Test 2 — fact recall**

> What's my favorite food?

Expected: response includes `Spicy Korean BBQ short rib tacos`, wrapped in the style rules.

**Test 3 — script invocation**

> Style-check this file: `<any markdown file in scope>`

Expected: response reports the output of `bash ${CLAUDE_PLUGIN_ROOT}/scripts/style-check.sh <file>`, wrapped in the style rules.

**Test 4 — memory discipline**

> What do you remember about me?

Expected on first install: skill reads `${CLAUDE_PLUGIN_DATA}/memory.md`, reports that the file is empty or absent, offers to start tracking.

After several interactions where the user corrects the agent or shares preferences, re-run the test: skill should report some accumulated entries from `${CLAUDE_PLUGIN_DATA}/memory.md`.

## What we're watching for

Things that tell us the plugin system is (or isn't) behaving the way we expect:

- **Skill activation** — does the persona shape every response, or only when the plugin name is mentioned?
- **Environment variable substitution** — does Claude see absolute paths in `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PLUGIN_DATA}`, or literal placeholder strings?
- **Script execution** — does Claude have permission to run bash scripts inside the plugin cache? Any prompts?
- **Memory file creation** — does `${CLAUDE_PLUGIN_DATA}` auto-create when first referenced, or does Claude need to `mkdir -p` first?
- **Cowork parity** — does the persona shape main-Claude responses in Cowork the same way it does in Claude Code? Or does Cowork only surface the skill on explicit invocation?
- **Permission prompts** — does the install flow prompt for plugin authorization on first use? How does that feel?

## Uninstall

Claude Code: `/plugin uninstall spoho-style-assistant@hive-store-dev` — prompts before deleting `${CLAUDE_PLUGIN_DATA}`; pass `--keep-data` to preserve.

Cowork: Organization settings → Plugins → remove.
