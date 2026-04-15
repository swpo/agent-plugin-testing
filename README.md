# Hive Agent Store (experimental)

Experimental sibling to the main Hive monorepo. This directory is the workbench for a new Hive vertical: **a store where users buy AI agents**, installed into Claude Code or Cowork via a remote MCP connector.

See `PLAN.md` for the full staged plan. See `../hive/` for the production Hive codebase.

## Status

**Phase -1** — proving that Claude/Cowork can install a skill from a local zip, before any MCP/server work.

## Layout

```
agent-store/
├── agents/                          # Source files for sample agent packages
│   └── spoho-style-assistant/       # Test payload for Phase -1
├── dist/                            # Built zips (gitignored)
├── docs/                            # Install recipes, phase notes
├── PLAN.md                          # Staged plan, running doc
└── README.md                        # This file
```

## Not in scope here (yet)

- Production web store UI — will eventually live in `../hive/packages/web/app/store/`
- MCP server for production — will eventually live in `../hive/packages/store-api/` as a separate Railway service
- User accounts, Stripe, DB — reusing main Hive infra once we have a shape worth wiring up
