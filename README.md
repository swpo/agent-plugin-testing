# Agent Plugin Testing

Experimental Claude plugin marketplace. A workspace for building and testing plugins that can be installed in Claude Code or Cowork.

## Install

Claude Code:

```
/plugin marketplace add swpo/agent-plugin-testing
/plugin install <plugin-name>@hive-store-dev
/reload-plugins
```

Cowork: Organization settings → Plugins → Add plugin → GitHub → `swpo/agent-plugin-testing`.

## Layout

```
├── .claude-plugin/marketplace.json   # marketplace catalog
├── plugins/                          # plugins in development
├── docs/                             # notes and findings
└── PLAN.md
```
