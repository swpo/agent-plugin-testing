# Hive Agent Plugin Testing

Sibling to the main Hive monorepo. Workbench for building and iterating on Claude plugins that will eventually populate the Hive Agent Store.

Distributes plugins via the `hive-store-dev` marketplace (this repo's `.claude-plugin/marketplace.json`). Pushes to GitHub for Cowork to consume.

## Status

**Phase -1 complete:** the install pipeline works end-to-end. A plugin in this repo's `plugins/` directory, listed in `marketplace.json`, can be installed via `/plugin install <name>@hive-store-dev` in Claude Code or through the Marketplace UI in Cowork after adding `swpo/agent-plugin-testing` as a source. Persona-shaping via skill description has known limits in Cowork (skills auto-invoke on description match, not always-on).

**Phase 0 (current):** build a first real plugin — a lead-research agent that finds contact info for companies in a given industry subject to website constraints. Use it to learn what the right plugin shape is for "real" agent products.

## Layout

```
agent-store/
├── .claude-plugin/marketplace.json   # hive-store-dev catalog
├── plugins/                          # plugins in development (currently empty)
├── docs/
│   └── phase-minus-1-findings.md     # install-pipeline-validation log
├── PLAN.md                           # staged plan through MVP
└── README.md                         # this file
```

## Install for development

From any Claude Code session:

```
/plugin marketplace add swpo/agent-plugin-testing
/plugin install <plugin-name>@hive-store-dev
/reload-plugins
```

Cowork: Organization settings → Plugins → Add plugin → GitHub → `swpo/agent-plugin-testing`.

## Not in scope here (yet)

- Production storefront UI — eventually in `../hive/packages/web/app/store/`
- Per-user dynamic marketplace backend — eventually in `../hive/packages/store-api/`
- OAuth, Stripe, account management — reuses main Hive infra when wired up
