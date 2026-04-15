# Install Recipe (Phase -1)

This is the instruction set we hand to Claude when asking it to install a Hive agent zip. In Phase 0 it becomes the `instructions` field in the `get_agent_package` MCP tool response.

## Prompt template

```
Install the Hive agent package at <ZIP_SOURCE> into this workspace.

Steps:
1. If <ZIP_SOURCE> is a URL, download it to a temp file. If it's a local path, use it directly.
2. Create the install directory:  .claude/skills/<agent-name>/
   where <agent-name> is the "name" field in manifest.json inside the zip.
3. Extract the zip into that directory. Overwrite existing files if present.
4. Verify SKILL.md and manifest.json exist in the install directory.
5. If a scripts/ directory exists, chmod +x any .sh files inside it.
6. Confirm success by reading the newly-installed SKILL.md and reporting the
   skill name, version, and trigger.

Do not read or modify file contents inside the zip during install. The skill
is active immediately after extraction — a subsequent prompt will test it.
```

## Concrete example (local zip, Claude Code)

> Install the Hive agent package at `/Users/spoho/hive/agent-store/dist/spoho-style-assistant-1.0.0.zip` into this workspace. Follow the steps in `docs/install-recipe.md`.

Expected filesystem state after install:

```
<workspace>/.claude/skills/spoho-style-assistant/
├── SKILL.md
├── README.md
├── manifest.json
└── scripts/
    └── style-check.sh   (executable)
```

## Acceptance test

After install, start a **new** Claude session (so the newly-installed skill is loaded) in the same workspace and ask:

> Is the style assistant installed?

Expected response (exactly):

```
Got it, here's the rundown:
- spoho-style-assistant v1.0.0 is active
- Rules loaded: opening phrase, closing phrase, bullet-only, second person
- Personal facts table: 5 entries
- Helper script: scripts/style-check.sh (run `bash <skill-dir>/scripts/style-check.sh <file>` to test)
— spoho-style-assistant v1.0.0
```

A second, stronger test:

> What's my favorite food?

Expected response begins with `Got it, here's the rundown:`, contains `Spicy Korean BBQ short rib tacos`, and ends with `— spoho-style-assistant v1.0.0`.

A third, verifies the bundled script runs:

> Style-check this file: `<any markdown file>`

Expected response reports the output of `bash .claude/skills/spoho-style-assistant/scripts/style-check.sh <file>`, wrapped in the style rules.

## What to watch for

- **Skill activation timing:** does it activate in the same session, or does it require a fresh session? Worth knowing for UX.
- **Permission prompts:** does Claude Code prompt before executing `unzip`? Before running the bundled script? We want to know the friction surface.
- **Cowork filesystem visibility:** where does `.claude/skills/` need to live in Cowork — in the workspace root or the VM home dir?
- **Script execution in Cowork:** can Cowork run `bash scripts/style-check.sh` from an installed skill, or is there a sandbox wall?
