# Hive Agent Store (experimental)

Experimental sibling to the main Hive monorepo. This directory is the workbench for a new Hive vertical: **a store where users buy AI agents**, installed into Claude Code or Cowork via the native Claude plugin system.

See `PLAN.md` for the full staged plan. See `../hive/` for the production Hive codebase.

## Status

**Phase -1 (v2)** — validating the **plugin format** install path in both Claude Code and Cowork. The filesystem-drop approach explored in the first pass works in Claude Code but does not in Cowork; plugins are the unified install unit for both runtimes.

## Layout

```
agent-store/
├── .claude-plugin/
│   └── marketplace.json             # Hive dev marketplace catalog
├── plugins/
│   └── spoho-style-assistant/       # First test payload
│       ├── .claude-plugin/plugin.json
│       ├── skills/spoho-style-assistant/SKILL.md
│       ├── scripts/style-check.sh
│       └── README.md
├── docs/
│   ├── install-recipe.md            # User-facing install walkthrough
│   └── phase-minus-1-findings.md    # Running log of what we learned
├── PLAN.md                          # Staged plan through MVP
└── README.md                        # This file
```

## Why Cowork is the primary target

Claude Code users can already configure agents manually (write SKILL.md, drop it into `.claude/skills/`, done). The product-market fit for the Agent Store is Cowork — desktop/web users who don't have the terminal-level configurability and benefit from "click install, agent is ready." The store builds toward that audience while remaining compatible with Claude Code.

## Not in scope here (yet)

- Production storefront UI — eventually in `../hive/packages/web/app/store/`
- Per-user dynamic marketplace backend — eventually in `../hive/packages/store-api/` as a new Railway service
- OAuth, Stripe, account management — reuses main Hive infra when we wire it up
