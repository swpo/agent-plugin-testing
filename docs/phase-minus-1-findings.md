# Phase -1 Findings

Running log of what we learned from the filesystem-install-validation phase.

## Test 1: Mechanical install (direct bash, no Claude)

Sanity check that the zip unpacks cleanly and permissions survive.

**Result:** clean. All files land at the expected paths, executable bit on `scripts/style-check.sh` is preserved through the zip round-trip.

## Test 2: Agentic install (fresh Claude subagent, given only the recipe)

A Claude subagent was handed the install recipe and the zip path, with no prior context. It executed:

```bash
unzip -p <zip> manifest.json                            # peek at name
mkdir -p <workspace>/.claude/skills/<name>
unzip -o <zip> -d <workspace>/.claude/skills/<name>/
chmod +x <install-dir>/scripts/*.sh
```

**Result:** install succeeded. The recipe was followable end-to-end with no hand-holding. The subagent correctly identified skill name, version, and trigger from the installed files.

## Friction points the subagent surfaced

Honest feedback from the subagent, ranked by how much they matter for Phase 0:

### 1. Redundant path info in the manifest (fix in Phase 0)

The manifest has `install_path: ".claude/skills/spoho-style-assistant"` AND the recipe says to construct the same path from `name`. Two sources of truth for the install location — an installer has to pick one and hope they don't diverge.

**Decision:** drop `install_path` from `manifest.json`. The installer derives the path from `name` + the target scope (project vs global). The manifest specifies intent (this is a `.claude/skills/` agent), not path details.

### 2. Update semantics were undefined (fixed in recipe v2)

`unzip -o` overwrites but doesn't prune stale files from a prior install. For a real update flow, overlay vs clean-install is a real choice.

**Decision:** clean install by default. Remove the target dir first, then extract. Simple, predictable, matches user expectation of "installing version 2.0.0 means 2.0.0 is what's on disk."

### 3. Script permission step was ambiguous (fixed in recipe v2)

"Ensure `.sh` files are executable" — shallow or recursive? Subagent went shallow.

**Decision:** recursive via `find ... -exec chmod +x {} +`. Also: ideally the zip is packaged with correct permissions and this step is defensive belt-and-suspenders. Our current zip already preserves the bit correctly, so the chmod is free insurance.

### 4. No checksum verification in the recipe (fixed in recipe v2)

For Phase -1 with a local file it doesn't matter, but Phase 0's `get_agent_package` MCP response includes a `checksum` field — verification should be mandatory once we introduce downloads.

**Decision:** recipe v2 mentions "if the caller provided a checksum, verify it now."

### 5. SKILL.md frontmatter has no version field (fix in Phase 0)

The subagent reached for version info and had to go to `manifest.json` to find it. SKILL.md frontmatter has `name` and `description` but no `version`. A harness that only inspects SKILL.md (the way native skill loaders do) can't tell which version is installed.

**Decision:** add `version` to SKILL.md frontmatter too. It duplicates the manifest, but frontmatter is the public-facing contract for skill loaders; manifest is Hive-specific metadata. Both should carry it.

### 6. "Do not read file contents" was self-contradictory (fixed in recipe v2)

The recipe said not to read file contents, but step 2 required reading `manifest.json`. The intent was "don't read payload files for extra context" — not "don't read the install manifest."

**Decision:** recipe v2 says "don't read payload files (SKILL.md, README.md, scripts) — manifest is the only thing you read to drive the install."

## What this tells us for Phase 0

- The install recipe is viable. Claude can execute it from cold. Our MCP `get_agent_package` response can return something very close to the v2 recipe as its `instructions` field.
- We should decide the manifest schema before Phase 0 starts. See friction point #1 and #5 for the changes to make.
- The checksum step (#4) needs to be reflected in the MCP tool response — `get_agent_package` should always include a sha256.
- We do **not** yet know whether skill activation is automatic in the same session or requires a fresh session. Must verify by hand.
- We do **not** yet know Cowork behavior. Must verify by hand.

## Test 3: Cowork skill-discovery gap — blocking finding

User tested the pre-installed `/tmp/hive-store-test/` in a Cowork workspace. Cowork did not auto-load the skill from the mounted `.claude/skills/` directory, and `/style-check` didn't register as a command.

Cowork's reply (paraphrased): in Cowork, skills come from `<available_skills>` at session start, sourced from *bundled Anthropic skills + installed plugin skills*. A loose folder in a mounted project is not scanned. The model can still `Read` and hand-follow the rules if pointed at them, but the runtime doesn't treat it as a registered skill. Slash-commands aren't wired to project-local skill files either. The assistant suggested "package as a Cowork plugin" as the path forward.

**This invalidates the core premise of the original spec** — "drop a zip, it becomes a skill" works only in Claude Code, not Cowork. A real product has to use the plugin system.

## Pivot: from filesystem drop to plugin marketplace

Research (see `../PLAN.md`, sources at end of this file) confirmed:

- Claude Code and Cowork share the **Claude plugin system** as their registration mechanism
- Plugins are distributed via **marketplaces** — either a Git repo with `.claude-plugin/marketplace.json`, or a raw HTTPS URL serving the same JSON
- Install is platform-native (`/plugin install` in Code; Marketplace UI in Cowork); **no custom MCP connector needed for install**
- Plugins bundle `skills/`, `agents/` (subagents), `commands/`, `hooks/`, `.mcp.json`, `bin/`, `scripts/`
- Persistent storage: `${CLAUDE_PLUGIN_DATA}` (per-plugin dir surviving updates) and subagent `memory: user|project|local` (per-subagent memory dir)
- Paid-agent auth: private npm registry via `npm` source + `registry` field — standard npm auth gates downloads
- **Per-user dynamic marketplaces are possible** by serving `marketplace.json` from a server endpoint that varies content by auth token in URL. Plugin sources within point to public GitHub repos (or private with token), or npm packages

The original MCP-connector-for-install architecture is now **optional**, possibly revisited at Phase 2 for in-chat discovery only.

## Phase -1 v2 plan

Restructure the sample agent as a proper plugin + local marketplace:

```
agent-store/
├── .claude-plugin/marketplace.json
├── plugins/
│   └── spoho-style-assistant/
│       ├── .claude-plugin/plugin.json
│       ├── skills/spoho-style-assistant/SKILL.md  # persona + memory discipline
│       └── scripts/style-check.sh
```

Product pattern: **skill-as-agent (Pattern B)** — skill body carries the agent persona, references `${CLAUDE_PLUGIN_DATA}/memory.md` for accumulated learning. Works identically in Code and Cowork. Pattern A (subagent with `memory: user`) is held for later, higher-tier product offerings.

See `../PLAN.md` Phase -1 (v2) for the test checklist.

## Sources

- [Claude Code plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- [Claude Code plugins reference](https://code.claude.com/docs/en/plugins-reference)
- [Claude Code discover/install plugins](https://code.claude.com/docs/en/discover-plugins)
- [Claude Code subagents](https://code.claude.com/docs/en/sub-agents)
- [Claude Code settings](https://code.claude.com/docs/en/settings)
- [Use plugins in Claude Cowork](https://support.claude.com/en/articles/13837440-use-plugins-in-claude-cowork)
- [Get started with Claude Cowork](https://support.claude.com/en/articles/13345190-get-started-with-claude-cowork)
