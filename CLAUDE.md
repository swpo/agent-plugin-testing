# Agent plugin testing — working notes for Claude

## Pre-push checklist

Before committing and pushing any changes to this repo, verify:

1. **Version consistency** — when bumping `plugins/<name>/.claude-plugin/plugin.json` version:
   - Update any `v0.X.Y` references in the plugin's `README.md` (especially the Status section)
   - Update the plugin's top-of-file description if the version implies a major shape change
   - Check `marketplace.json` — version should live in plugin.json only, not duplicated here
2. **Validate the marketplace** — run `claude plugin validate .` from the repo root. Must pass (warnings OK).
3. **Smoke-test scripts** — any bundled shell or Python scripts should run cleanly with a synthetic input.
4. **Check for leaked internal references** — this repo is public. No references to internal infra, domains, or plans that aren't ready to be seen.

## Repo conventions

- Plugins live in `plugins/<name>/` with `.claude-plugin/plugin.json` as the manifest
- Marketplace name `hive-store-dev` is the identifier stored in `.claude-plugin/marketplace.json`
- Skills, scripts, hooks, etc. follow the [standard Claude plugin layout](https://code.claude.com/docs/en/plugins-reference)
- `${CLAUDE_PLUGIN_ROOT}` for plugin-relative assets (scripts, helpers); `${CLAUDE_PLUGIN_DATA}` for persistent state that survives updates
- Skill descriptions are what triggers auto-invocation — write them carefully and use task-language the user would speak

## Auth for external services

Prefer remote MCP connectors (e.g., `https://mcp.firecrawl.dev/<KEY>/v2/mcp`) over plugin-level `userConfig`. userConfig does not reliably render in Cowork's plugin config UI. MCP connectors are cross-platform (Claude Code + Cowork) and handle credentials in the connector URL, not in chat or plugin settings.
