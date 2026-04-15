# Hive Agent Store — Staged Plan

Running document. Updated as we learn things.

## Concept

A second vertical for Hive: a store where the agent *itself* is the product. Users browse/purchase on a web storefront (`thisisagenthive.com/store`), then install purchased agents into their Claude Code or Cowork workspace via a remote MCP connector.

The MCP server is metadata + signed download URLs. Claude is the installer — it fetches the zip directly and extracts into `.claude/skills/`. File contents never pass through the model context.

## Phase -1 — filesystem install validation (current)

**Goal:** prove Claude/Cowork can install a skill from a zip, with no server, no MCP, no auth.

- [x] `agents/spoho-style-assistant/` — sample agent with distinctive style rules, personal facts, bundled bash helper
- [x] `dist/spoho-style-assistant-1.0.0.zip` — built package
- [x] `docs/install-recipe.md` — the prompt/steps we hand to Claude
- [ ] Test in Claude Code (local terminal)
- [ ] Test in Cowork (upload to workspace or fetch via URL)
- [ ] `docs/phase-minus-1-findings.md` — what worked, what surprised us

## Phase 0 — local MCP server, custom connector

**Goal:** the full install flow works end-to-end via a real MCP connector, running locally.

- Node + TypeScript, MCP TypeScript SDK
- Hardcoded agent catalog, zips served from local static handler
- Expose via ngrok (or equivalent), add as custom connector in Claude Desktop
- Implement `list_agents`, `get_agent_details`, `get_agent_package` — skip `search_agents` until we have more than 1 agent
- Skip OAuth — anonymous or static-token for POC
- Verify: "show me my Hive agents", "install the style assistant" both work in Claude Desktop (Cowork) and Claude Code

## Phase 1 — production

**Goal:** shippable minimum. Move into the Hive monorepo, host on Railway, real storefront.

- New workspace package `hive/packages/store-api/` — MCP server + store backend, Node/TS, separate Railway service in the same project
- Storefront UI added to `hive/packages/web/app/store/`
- OAuth against Hive accounts (reuse existing buyer auth if sensible)
- Stripe checkout (reuse Hive's Stripe account, or a new one — TBD)
- Package storage in R2 (reuse existing Hive R2 bucket under a `store/` prefix)
- Postgres schema `store.*` in the existing Neon DB
- Domain: MCP endpoint at `api.thisisagenthive.com/mcp` or `mcp.thisisagenthive.com`; storefront at `thisisagenthive.com/store`

## Phase 2+

- Submit connector to Anthropic's Connectors Directory
- Publisher onboarding (agents can be published by operators)
- Agent updates (`check_updates` tool)
- Uninstall tool
- Usage analytics

## Hosting — decided (tentatively)

- **Runtime:** Node + TypeScript
- **Platform:** Railway, same project as main Hive API, **new separate service**
- **Why separate:** failure isolation, independent scaling for bursty MCP traffic, cheap rollback if the experiment fails. Not dogmatic — reversible.
- **Code sharing:** workspace packages (`@hive/auth`, `@hive/db`, etc.) so the store-api can reuse main API's auth/DB/Stripe helpers

## Open questions (from the spec, deferred)

1. Global vs project install default — defer to Phase 0 testing
2. Updates mechanism — Phase 2
3. Uninstall — Phase 2
4. Multi-skill bundles / CLAUDE.md / subagents — Phase 2+
5. Cowork egress — **must verify in Phase 0**. If the VM can't reach arbitrary HTTPS, we need a base64-in-response fallback for small packages
6. Publisher trust/review — Phase 2
