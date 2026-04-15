# Hive Agent Store — Staged Plan

Running document. Updated as we learn things.

## Concept

A second vertical for Hive: a store where the agent *itself* is the product. Users browse/purchase on a web storefront (`thisisagenthive.com/store`), then install purchased agents into their Claude Code or Cowork workspace.

**Distribution mechanism (pivoted from the original spec):** each Hive agent ships as a **Claude plugin**, distributed via a **per-user dynamic marketplace** at `marketplace.thisisagenthive.com/<user-token>`. The marketplace endpoint returns only the agents the user has purchased. Users install via `/plugin install <agent>@hive-store` in Claude Code, or via the Marketplace UI in Cowork.

**Primary target is Cowork** — desktop users without terminal-level configurability. Claude Code compatibility is free as long as we use the standard plugin format.

**No custom MCP connector needed for install.** The plugin system is native in both runtimes. An optional MCP connector could be added later for in-chat discovery ("Claude, what Hive agents would help with X?") — not on the critical path.

## Product pattern — skill-as-agent (Pattern B)

Each agent ships as a plugin whose **skill body is the agent persona + memory discipline**. When the plugin is enabled, the skill is always active — the user's Claude adopts the persona, reads accumulated memory from `${CLAUDE_PLUGIN_DATA}/memory.md`, and appends learned facts back. Memory is a compact index into the user's working files, not the WIP itself — WIP lives in the user's real directory.

**Pattern A (subagent with `memory: user`)** remains available for power cases — tool restrictions, dedicated sub-session context — but Cowork's delegation-only model makes it feel like "consultant I call on" rather than "this is the agent," which doesn't match the buyer mental model. Not the default.

## Phase -1 (v1) — filesystem install validation — DONE

First attempt. Built a zip, tested direct install into `.claude/skills/`. Worked in Claude Code, did not work in Cowork (skills require plugin registration in that runtime, not just filesystem presence). Findings in `docs/phase-minus-1-findings.md`. Approach abandoned in favor of plugins.

## Phase -1 (v2) — plugin format validation (current)

**Goal:** prove that a plugin + local marketplace loads and activates correctly in both Claude Code and Cowork, with no infra standing up yet.

- [x] Restructure sample agent as a plugin (`plugins/spoho-style-assistant/`)
- [x] Write `.claude-plugin/marketplace.json` listing the plugin
- [ ] Test `/plugin marketplace add` + `/plugin install` in Claude Code (local repo path)
- [ ] Push to GitHub so Cowork can reach it
- [ ] Add marketplace in Cowork (Org settings → Plugins → Add plugin → GitHub)
- [ ] Verify activation in both runtimes with the acceptance tests from `plugins/spoho-style-assistant/README.md`
- [ ] Document findings

## Phase 0 — dynamic marketplace endpoint

**Goal:** prove the per-user marketplace pattern — a JSON endpoint that returns a different catalog based on auth.

- Small Node/TS service that serves `marketplace.json` dynamically at a URL like `localhost:3100/m/<token>`
- Hardcoded "user database" — 2-3 fake users with different agent purchases
- Each user's marketplace lists different subsets of agents
- Agents themselves are hosted as GitHub repos (plugin sources use `github` source type)
- Run locally, expose via ngrok, test adding the URL as a marketplace in Cowork
- Validate: switching the user token changes what the Marketplace UI shows

Still no Hive backend involvement — just proving the dynamic-endpoint pattern works with Cowork's plugin system.

## Phase 1 — production MVP

**Goal:** shippable minimum. Move into the Hive monorepo, host on Railway, real storefront, real payments.

- New workspace package `hive/packages/store-api/` — the marketplace endpoint + admin/catalog API, Node/TS, separate Railway service
- Storefront UI added to `hive/packages/web/app/store/`
- OAuth against Hive accounts (reuse existing buyer auth if sensible)
- Stripe checkout (reuse Hive's Stripe account, or a new one — TBD)
- Agent plugins live as repos in a `Agent-Hive-Store` GitHub org (or similar); per-user marketplace points to them via `github` source
- DB: schema `store.*` in the existing Neon Postgres (agents, purchases, per-user marketplace tokens)
- Domain: storefront at `thisisagenthive.com/store`; marketplace endpoint at `marketplace.thisisagenthive.com/<user-token>` (or subpath — TBD)

## Phase 2 — publisher onboarding + richer tiers

- Let operators publish agents (not just Hive admin)
- Support Tier 3 (stateful subagents with memory) as a product tier
- Agent versioning and update flow
- Private npm registry for paid agents (stronger piracy protection than public GitHub repos)
- Submit Hive marketplace to Anthropic's plugin directory for discovery

## Hosting — decided (tentatively)

- **Runtime:** Node + TypeScript
- **Platform:** Railway, same project as main Hive API, **new separate service**
- **Why separate:** failure isolation, independent scaling for bursty marketplace traffic, cheap rollback if the experiment fails. Not dogmatic — reversible.
- **Code sharing:** workspace packages (`@hive/auth`, `@hive/db`, etc.) so store-api can reuse main API's auth/DB/Stripe helpers

## Component → concept mapping

How the current Hive mental model (Claude Code + hive CLI + workspace) maps onto the plugin model:

| Current concept | Plugin equivalent |
| --- | --- |
| `hive install` scaffolds a workspace | `/plugin install <name>@hive-store` (or Cowork UI install) |
| Hive agent's CLAUDE.md (always-loaded rules) | `skills/<name>/SKILL.md` body |
| `~/.hive/<profile>/memory/MEMORY.md` | `${CLAUDE_PLUGIN_DATA}/memory.md`, read/written via SKILL.md instructions |
| Workspace CLAUDE.md (project-specific) | User's own `.claude/CLAUDE.md` — unchanged |
| Helper scripts in workspace | `scripts/` (referenced via `${CLAUDE_PLUGIN_ROOT}`) or `bin/` (PATH-available) |
| Auto-memory in `~/.claude/projects/` | *(not provided)* — plugins don't get this; use explicit memory file instead |
| MCP servers the agent uses | `.mcp.json` at plugin root |
| Automated behaviors | `hooks/hooks.json` (SessionStart, PostToolUse, etc.) |
| CWD / working directory | Unchanged — user's real filesystem, WIP lives there |

## Open questions

1. Does Cowork respect the `"agent"` settings.json field that pins a subagent as the primary for a chat? Not documented; would need to test to unlock Pattern A in Cowork.
2. Does memory (both `${CLAUDE_PLUGIN_DATA}/*` and subagent `memory: user`) survive plugin uninstall? Or get cleaned? Unclear — affects whether reinstall resumes with prior context.
3. Private npm registry vs private GitHub org for paid agents — which has a smoother install UX under Cowork's auth model? Defer to Phase 2.
