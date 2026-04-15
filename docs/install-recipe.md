# Install Recipe (Phase -1)

This is the instruction set we hand to Claude when asking it to install a Hive agent zip. In Phase 0 it becomes the `instructions` field in the `get_agent_package` MCP tool response.

## Prompt template

```
Install the Hive agent package at <ZIP_SOURCE> into this workspace.

Steps:
1. If <ZIP_SOURCE> is a URL, download it to a temp file. If it's a local
   path, use it directly. (If the caller provided a checksum, verify it
   now before proceeding.)
2. Read manifest.json out of the zip without extracting the whole archive
   (e.g. `unzip -p <zip> manifest.json`). Get the "name" field.
3. Create the install directory at:  <workspace>/.claude/skills/<name>/
   If it already exists, remove it first — this is a clean install, not
   an overlay, so stale files from a prior version are not carried over.
4. Extract the zip into that directory.
5. Verify SKILL.md and manifest.json exist in the install directory.
6. Ensure any .sh files are executable (recursively):
   `find <install-dir> -type f -name '*.sh' -exec chmod +x {} +`
7. Confirm success by reading the installed SKILL.md and reporting the
   skill name, version (from manifest.json — the SKILL.md frontmatter
   is not the source of truth for version), and trigger.

Do not read or modify payload file contents during install — no peeking
inside SKILL.md, README.md, or the scripts beyond the permission step.
Manifest is the only file you read to drive the install. The skill will
be activated by a subsequent prompt in a fresh session.
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
