<!-- FOR AI AGENTS - Human readability is a side effect, not a goal -->
<!-- Managed by agent: keep sections and order; edit content, not structure -->
<!-- Last updated: 2026-10-06 | Last verified: 2026-10-06 -->

# AGENTS.md

**Precedence:** the **closest `AGENTS.md`** to the files you're changing wins. Root holds global defaults only.

Fork of `jeffvestal/agent-memory` (Elasticsearch as persistent memory for Claude Code) at
`dirien/agent-memory`, extended for the talk "Give Your Coding Agent an (Elastic) Memory"
(Elastic NYC meetup, 2026-10-06): Pulumi HCL backend, memory curation with TypeSafe Jev, APM packaging,
Docker Sandboxes kit, Slidev deck.

## Commands (verified)
> Source: scripts in this repo, `slides/package.json`, `.github/workflows/publish-kit.yaml`

| Task | Command | ~Time |
|------|---------|-------|
| Lint shell | `shellcheck -x -S warning bridge hooks/*.sh scripts/*.sh lib/*.sh` (not installed here: `uv tool run --from shellcheck-py shellcheck ...`) | ~5s |
| Memory status | `pulumi env run dirien/agent-memory/runtime -- ./bridge status` | ~3s |
| Infra plan / apply | `scripts/pulumi.sh preview` / `scripts/pulumi.sh up` (sandbox: `AGENT_MEMORY_BACKEND=local`, already set here) | ~20s / 1-2 min |
| Stack output | `scripts/pulumi.sh stack output dashboard_url` | ~3s |
| Demo sandbox | `scripts/demo-sandbox.sh <name> <workspace>` (host only, plain bash; see `DEMO.md`) | ~1 min |
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
infra/curation.tf       -> memory curation: Jev .http connector (restapi) + Kibana Workflow; off without typesafe_api_key
infra/workflows/        -> memory-curation.yaml (the workflow), NOTICE.md (questions adapted from jev-mem, invalidate)
infra/esc/              -> template for the hand-made agent-memory/elastic-cloud ESC environment
kit/                    -> Docker Sandboxes mixin kit (spec.yaml), published as ghcr.io/dirien/agent-memory-kit
scripts/                -> pulumi.sh (backend wrapper), sbx-startup.sh (kit startup), push-kit.sh (publish), demo-sandbox.sh (DEMO.md)
setup/dashboards/       -> Kibana dashboard JSON (source of truth for infra/dashboard.tf)
slides/                 -> Slidev deck for the talk (own AGENTS.md)
DEMO.md                 -> the demo runbook: three sandboxes (fri, mon, wed), four acts, reset
.github/workflows/      -> publish-kit.yaml (validate + push kit on main and v* tags)
```

## Golden Samples (follow these patterns)
| For | Reference | Key patterns |
|-----|-----------|--------------|
| Hook script | `hooks/session-start.sh` | source `resolve-bridge.sh`, never fail (always `exit 0`), stdout becomes session context |
| ES\|QL query in bash | `lib/memory.sh` (`mem_recall`) | heredoc query, `jq -Rs` to JSON-encode, `es_request POST /_query` |
| Pulumi HCL resource from outputs | `infra/esc.tf` | `stringasset(yamlencode(...))`, `$${...}` escapes ESC interpolation |
| Kit spec | `kit/spec.yaml` | schema v2 mixin; argv-form startup; `KIT_REF` pinned, rewritten by `push-kit.sh` |
| Kibana Workflow | `infra/workflows/memory-curation.yaml` | scheduled trigger; Jev via the `.http` connector; Painless `decide` step returns the outcome; every pair logged to `agent-curation` |

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
| Tuning curation | thresholds and questions in `infra/workflows/memory-curation.yaml` (`decide` step), `scripts/pulumi.sh up`, then check `outcome` in `agent-curation` |
| Adding dependency | Ask first |

## Repository Settings
- Remote `origin` = `dirien/agent-memory` (fork), `upstream` = `jeffvestal/agent-memory`. Default branch `main`.
- Work lands directly on `main` of the fork (the owner's workflow for this talk repo); tags `v*` publish the kit.

## CI
- `.github/workflows/publish-kit.yaml`: installs `sbx`, runs `sbx kit validate` + `sbx kit push` for `ghcr.io/dirien/agent-memory-kit` on kit changes on `main` (`:latest`) and on `v*` tags. Permissions: `contents: read`, `packages: write`.

## Key Decisions
- `elastic/elasticstack` 0.16.5 runs on the `terraform-provider` **1.3.0** bridge plugin, pinned in `infra/sdks/elasticstack/hcl.sdk.json`: 1.4.0 rejects the required `_id` attribute of `elasticsearch_query_ruleset` (0.16.1+), see pulumi/pulumi-terraform-provider#117. Don't run `pulumi install` in `infra/` until that's fixed; it re-resolves to 1.4.0 and fails.
- In Docker Sandboxes, Pulumi state is local (`infra/.pulumi-state`, stack `local`): the credential proxy overwrites `Authorization` on `api.pulumi.com`, so update-token calls fail with 401.
- No `.env` files: the stack writes `<org>/agent-memory/runtime` (ESC) with every setting and both keys.
- Keys reach sandboxes as `sbx secret set-custom` placeholders (`sbx-cs-...`), resolved on the host from ESC; the proxy replaces only the placeholder.
- Hooks, skill and MCP server are installed only at user scope (`apm install -g`) by the kit, never committed at project level: the workspace is shared with sandboxes that must not get them.
- The MCP key is read-only (writes get 403); memories are written by `bridge` (Claude or hooks).
- Memory curation is opt-in: with `typesafe_api_key` set (Pulumi config secret), `infra/curation.tf` creates a Kibana `.http` connector to Jev and a workflow that runs every minute. For each memory without `curated_at` it finds the three nearest older memories, asks Jev ten yes/no questions per pair, and a Painless rule decides (superseded, review, duplicate, subsumed, none). Jev votes; the thresholds in the workflow decide.
- `elastic/elasticstack` can't create the `.http` connector, so it goes through `Mastercard/restapi` 3.0.0 on `terraform-provider` 1.4.0, pinned in `infra/sdks/restapi/hcl.sdk.json`.
- Recall hides retired memories: `status: superseded` (curation or `bridge forget --superseded-by`), legacy `type: superseded`, and anything with `duplicate_of`. Nothing is deleted.

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
- Print, echo or commit keys: `BRIDGE_ES_API_KEY`, `ELASTIC_MCP_API_KEY`, `EC_API_KEY`, the state passphrase, the Jev key (`typesafe_api_key`).
- Commit `.env`, `infra/.pulumi-state/`, `infra/Pulumi.local.yaml`, `.claude/settings.json`, `.claude/hooks/`, `.mcp.json`.
- Run a project-level `apm install` in this repo (it would register the Elastic hooks for every sandbox on the workspace).
- Commit `slides/public/memento-leonard.jpg` (a film still; gitignored, local only).

## Codebase State
- Kit: `:latest` is published from `main` with `KIT_REF` pinned to that commit; the demo uses it (`scripts/demo-sandbox.sh`). The last tag, `v0.2.2`, predates memory curation. Tags `v0.2.0`-`v0.2.2`; only `v0.2.0` has a GitHub release page.
- The demo backend was torn down after the talk (2026-10-06, `scripts/pulumi.sh destroy`, 20 resources: Serverless project `agent-memory`, curation on). The empty stack `local` stays in `infra/.pulumi-state`; `scripts/pulumi.sh up` rebuilds everything. The curation test project was destroyed the same day.
- ESC: `dirien/agent-memory/elastic-cloud` (hand-made: `EC_API_KEY`, state passphrase, legacy `mcp.*` copies) (kept, `up` needs it) and `dirien/agent-memory/runtime` (Pulumi-managed: deleted with the stack, recreated by `up`).
- This build sandbox has no Elastic hooks by design; demo sandboxes get them from the kit.
- Known upstream lint warning: `lib/tasks.sh` `task_suspend_active` assigns an unused `suspended` variable.
- `slides/slides.md` is the talk deck (39 slides, ~30 min of noted timing); see `slides/AGENTS.md`.

## Terminology
| Term | Means |
|------|-------|
| bridge | the `bridge` CLI (bash) that reads/writes the memory indices |
| runtime env | ESC environment `dirien/agent-memory/runtime`, written by `infra/esc.tf` |
| placeholder | `sbx-cs-...` value a sandbox sees instead of a key; the sbx proxy swaps it on the way out |
| kit | `kit/spec.yaml`, the elastic-memory Docker Sandboxes mixin |
| build sandbox | the sandbox this repo is developed in (no Elastic hooks) |
| demo sandbox | a sandbox created with the kit (`fri`, `mon`, `wed` in `DEMO.md`) |
| curation | the Kibana Workflow that supersedes, flags or links memories a newer one contradicts (`infra/curation.tf`) |
| Jev | TypeSafe AI's "System One" model: answers fixed-choice questions with probabilities; the curation workflow's judge |
| retired memory | `status: superseded` or `duplicate_of` set; hidden from recall, still in the index |

## Scoped AGENTS.md (MUST read when working in these directories)
- [slides/AGENTS.md](./slides/AGENTS.md): the Slidev deck, talk facts, style conventions, verified story material.

> **Agents**: When you read or edit files in a listed directory, you **must** load its AGENTS.md first.

## When instructions conflict
The nearest `AGENTS.md` wins. Explicit user prompts override files.
