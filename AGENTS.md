<!-- FOR AI AGENTS - Human readability is a side effect, not a goal -->
<!-- Managed by agent: keep sections and order; edit content, not structure -->
<!-- Last updated: 2026-09-27 | Last verified: 2026-09-27 -->

# AGENTS.md

**Precedence:** the **closest `AGENTS.md`** to the files you're changing wins. Root holds global defaults only.

Fork of `jeffvestal/agent-memory` (Elasticsearch as persistent memory for Claude Code) at
`dirien/agent-memory`, extended for the talk "Give Your Coding Agent an (Elastic) Memory"
(Elastic NYC meetup, 2026-10-06): Pulumi HCL backend, APM packaging, Docker Sandboxes kit, Slidev deck.

## Commands (verified)
> Source: scripts in this repo, `slides/package.json`, `.github/workflows/publish-kit.yaml`

| Task | Command | ~Time |
|------|---------|-------|
| Lint shell | `shellcheck -x -S warning bridge hooks/*.sh scripts/*.sh lib/*.sh` (not installed here: `uv tool run --from shellcheck-py shellcheck ...`) | ~5s |
| Memory status | `pulumi env run dirien/agent-memory/runtime -- ./bridge status` | ~3s |
| Infra plan / apply | `scripts/pulumi.sh preview` / `scripts/pulumi.sh up` (sandbox: `AGENT_MEMORY_BACKEND=local`, already set here) | ~20s / 1-2 min |
| Stack output | `scripts/pulumi.sh stack output dashboard_url` | ~3s |
| Kit validate | `sbx kit validate ./kit` (host or CI only; `sbx` is not in the sandbox) | ~2s |
| Slides | see `slides/AGENTS.md` (`npm run dev`, `npm run build`) | ~2s build |

There is no test suite. Verify behaviour against the live project (queries in `DEMO.md`).

## Response Style
- Answer first, elaborate only if needed. No sycophantic openers.
- For yes/no or status questions, lead with the answer.

## Workflow
1. **Before changing code**: read the nearest `AGENTS.md`, then `README.md` / `kit/README.md` / `infra/README.md` for the area.
2. **After each change**: shellcheck the touched scripts; `scripts/pulumi.sh preview` for `infra/`.
3. **Before claiming done**: show command output as evidence (ES|QL result, preview summary, build output).

## File Map
```
bridge                  -> CLI entrypoint (bash 4.3+), sources lib/*.sh
lib/                    -> memory, tasks, sessions, messages, graph, es (curl wrapper), fallback (offline queue)
hooks/                  -> Claude Code hook scripts (SessionStart, PostToolUse, SessionEnd) + resolve-bridge.sh
.apm/                   -> APM primitives: hooks/agent-memory.json, skills/agent-memory/SKILL.md
apm.yml                 -> APM package manifest (also declares the elastic-memory MCP server)
infra/                  -> Pulumi HCL program (runtime: hcl): Serverless project, indices, API keys, dashboard, ESC env
infra/esc/              -> template for the hand-made agent-memory/elastic-cloud ESC environment
kit/                    -> Docker Sandboxes mixin kit (spec.yaml), published as ghcr.io/dirien/agent-memory-kit
scripts/                -> pulumi.sh (backend wrapper), sbx-startup.sh (kit startup), push-kit.sh (publish)
setup/dashboards/       -> Kibana dashboard JSON (source of truth for infra/dashboard.tf)
slides/                 -> Slidev deck for the talk (own AGENTS.md)
DEMO.md                 -> the demo runbook: two sandboxes, three acts, reset
.github/workflows/      -> publish-kit.yaml (validate + push kit on main and v* tags)
```

## Golden Samples (follow these patterns)
| For | Reference | Key patterns |
|-----|-----------|--------------|
| Hook script | `hooks/session-start.sh` | source `resolve-bridge.sh`, never fail (always `exit 0`), stdout becomes session context |
| ES\|QL query in bash | `lib/memory.sh` (`mem_recall`) | heredoc query, `jq -Rs` to JSON-encode, `es_request POST /_query` |
| Pulumi HCL resource from outputs | `infra/esc.tf` | `stringasset(yamlencode(...))`, `$${...}` escapes ESC interpolation |
| Kit spec | `kit/spec.yaml` | schema v2 mixin; argv-form startup; `KIT_REF` pinned, rewritten by `push-kit.sh` |

## Utilities (check before creating new)
| Need | Use | Location |
|------|-----|----------|
| Call Elasticsearch | `es_request`, `es_search`, `es_index`, `es_online` | `lib/es.sh` |
| Queue writes offline | `fallback_queue` | `lib/fallback.sh` |
| Find the bridge from a hook | `source resolve-bridge.sh` | `hooks/resolve-bridge.sh` |
| Run Pulumi with the right backend | `scripts/pulumi.sh <args>` | `scripts/pulumi.sh` |
| Settings + keys for any command | `pulumi env run dirien/agent-memory/runtime -- <cmd>` | ESC, written by `infra/esc.tf` |

## Heuristics (quick decisions)
| When | Do |
|------|-----|
| Need BRIDGE_* settings or keys | `pulumi env run dirien/agent-memory/runtime -- ...`; never create `.env` files |
| Editing a script in `bridge`/`lib`/`hooks` | keep it portable: no `sed -i`, no BSD/GNU-only flags, bash 4.3+ |
| Changing `kit/`, `scripts/sbx-startup.sh` or hooks the kit installs | bump `version` + `KIT_REF` in `kit/spec.yaml`, tag `vX.Y.Z` after pushing |
| Running Pulumi in this sandbox | `scripts/pulumi.sh`, not bare `pulumi` (see Key Decisions) |
| Verifying memory data | ES\|QL via `pulumi env run ... -- curl .../_query` (see `DEMO.md` checks) |
| Adding dependency | Ask first |

## Repository Settings
- Remote `origin` = `dirien/agent-memory` (fork), `upstream` = `jeffvestal/agent-memory`. Default branch `main`.
- Work lands directly on `main` of the fork (the owner's workflow for this talk repo); tags `v*` publish the kit.

## CI
- `.github/workflows/publish-kit.yaml`: installs `sbx`, runs `sbx kit validate` + `sbx kit push` for `ghcr.io/dirien/agent-memory-kit` on kit changes on `main` (`:latest`) and on `v*` tags. Permissions: `contents: read`, `packages: write`.

## Key Decisions
- `elastic/elasticstack` pinned to `0.16.0`: 0.16.1+ ships `elasticsearch_query_ruleset`, whose `_id` output breaks the dynamic Terraform bridge in `pulumi install`.
- In Docker Sandboxes, Pulumi state is local (`infra/.pulumi-state`, stack `local`): the credential proxy overwrites `Authorization` on `api.pulumi.com`, so update-token calls fail with 401.
- No `.env` files: the stack writes `<org>/agent-memory/runtime` (ESC) with every setting and both keys.
- Keys reach sandboxes as `sbx secret set-custom` placeholders (`sbx-cs-...`), resolved on the host from ESC; the proxy replaces only the placeholder.
- Hooks, skill and MCP server are installed only at user scope (`apm install -g`) by the kit, never committed at project level: the workspace is shared with sandboxes that must not get them.
- The MCP key is read-only (writes get 403); memories are written by `bridge` (Claude or hooks).

## Boundaries

### Always Do
- Conventional Commits (`type(scope): subject`), atomic commits, author `Engin Diri <engin.diri@ediri.de>`.
- Show command output as evidence before claiming something works.
- Wipe the memory indices after test runs (command in `DEMO.md`, Reset).

### Ask First
- `pulumi up` / `destroy` against the live Elastic project, and any ESC environment edit.
- Pushing to `main` or pushing tags (tags publish a kit to GHCR).
- Changing `sbx` secrets or kit arguments that others' sandboxes depend on.

### Never Do
- Add `Co-Authored-By` or any AI attribution trailer to commits (explicit owner instruction).
- Print, echo or commit keys: `BRIDGE_ES_API_KEY`, `ELASTIC_MCP_API_KEY`, `EC_API_KEY`, the state passphrase.
- Commit `.env`, `infra/.pulumi-state/`, `infra/Pulumi.local.yaml`, `.claude/settings.json`, `.claude/hooks/`, `.mcp.json`.
- Run a project-level `apm install` in this repo (it would register the Elastic hooks for every sandbox on the workspace).

## Codebase State
- `v0.2.2` is current: `ghcr.io/dirien/agent-memory-kit:v0.2.2` (also `latest`). Tags `v0.2.0`-`v0.2.2`; only `v0.2.0` has a GitHub release page.
- The Serverless project `agent-memory` (aws-us-east-1) is live and billed; indices were wiped after the last test run.
- ESC: `dirien/agent-memory/elastic-cloud` (hand-made: `EC_API_KEY`, state passphrase, legacy `mcp.*` copies) and `dirien/agent-memory/runtime` (Pulumi-managed).
- This build sandbox has no Elastic hooks by design; demo sandboxes get them from the kit.
- Known upstream lint warning: `lib/tasks.sh` `task_suspend_active` assigns an unused `suspended` variable.
- `slides/slides.md` is a draft outline written before the demo worked; see `slides/AGENTS.md`.

## Terminology
| Term | Means |
|------|-------|
| bridge | the `bridge` CLI (bash) that reads/writes the memory indices |
| runtime env | ESC environment `dirien/agent-memory/runtime`, written by `infra/esc.tf` |
| placeholder | `sbx-cs-...` value a sandbox sees instead of a key; the sbx proxy swaps it on the way out |
| kit | `kit/spec.yaml`, the elastic-memory Docker Sandboxes mixin |
| build sandbox | the sandbox this repo is developed in (no Elastic hooks) |
| demo sandbox | a sandbox created with the kit (`mem-a`, `mem-b` in `DEMO.md`) |

## Scoped AGENTS.md (MUST read when working in these directories)
- [slides/AGENTS.md](./slides/AGENTS.md): the Slidev deck, talk facts, style conventions, verified story material.

> **Agents**: When you read or edit files in a listed directory, you **must** load its AGENTS.md first.

## When instructions conflict
The nearest `AGENTS.md` wins. Explicit user prompts override files.
