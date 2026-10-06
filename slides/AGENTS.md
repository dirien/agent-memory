<!-- FOR AI AGENTS - Human readability is a side effect, not a goal -->
<!-- Managed by agent: keep sections and order; edit content, not structure -->
<!-- Last updated: 2026-10-06 | Last verified: 2026-10-06 -->

# AGENTS.md: slides/

Slidev deck for **"Give Your Coding Agent an (Elastic) Memory"**, Engin Diri (Pulumi).
Root rules in `../AGENTS.md` apply (Conventional Commits, no `Co-Authored-By`, never print keys).

## Overview

The talk, from https://luma.com/ai-agents-nyc:

| | |
|---|---|
| Event | "Coding Agents with Elastic Memory + The Evolution to Stateless Serverless", Elastic NYC User Group × Pulumi |
| When / where | Tuesday 2026-10-06, 6:00-8:00 PM, Elastic NYC office, 1250 Broadway, floor 16 |
| Slot | first talk, 6:30 PM; the second talk (Ines Potier, Elastic, stateless vs stateful Serverless) starts 7:10 PM, so ~40 min including Q&A |
| Abstract gist | agents lose context between sessions; Claude Code's markdown memory is local; agent-memory stores decisions and session history in Elasticsearch, shared across machines, deployed with Pulumi |

## Setup
From `slides/`: `npm install --no-audit --no-fund --maxsockets=6 --fetch-retries=5`. Plain `npm install`
hit ECONNRESET behind the sandbox proxy once and left a half-extracted package; if `slidev` fails to
start, delete `node_modules` and run the install again.

## Commands
| Task | Command | ~Time |
|------|---------|-------|
| Dev server | `npm run dev` (serves on port 3030; from a sandbox the user must publish the port) | - |
| Build (the check) | `npm run build` | ~2s |
| PDF | `npm run export` (needs `npx playwright install chromium` first) | - |

`npm run build` is the verification step after every change: it fails on broken snippet imports and bad markdown.

## Structure
```
slides.md          -> the deck (one file)
style.css          -> overlay on @pulumi/slidev-theme: +40% font size, h1 pinned top, .big-code/.code-lg/.code-xl, .mem-card/.mem-caption, .meme-slide/.meme-frame, .soul-slide; story slides: .term-grid, .stat, .takeaway, .quote-card, .timeline, .cmp, .why-grid(--two), .hcl-grid, .memento, .diagram-frame(--strip), .stat-row, .step-row, .qr-corner
diagrams/*.mmd     -> Mermaid sources of the Excalidraw diagrams in public/diagrams/*.svg
diagrams/render/   -> mermaid-to-excalidraw renderer (headless Chromium); see its README to regenerate
snippets/soul.md   -> the SOUL.md intro slide content (reused from the GPU talk)
snippets/infra     -> symlink to ../../infra; Slidev refuses snippet paths outside slides/, so import infra code as <<< @/snippets/infra/<file>.tf hcl
public/fonts/      -> Inter + Monaspace Neon
public/logos/      -> Pulumi logos (dark/light), TypeSafe AI wordmark (slide 24), GitHub mark (Resources)
public/diagrams/   -> Excalidraw SVGs (architecture, recall, curation), generated from diagrams/*.mmd
public/memento-leonard.jpg -> film still for the Memento slides; local only, gitignored (public repo)
```
Theme: `@pulumi/slidev-theme` 0.4.0 (layouts: cover, default, section, two-cols, image-left, image-right, code, diagram, diagram-left, diagram-right, quote, statement, end). Mermaid is pinned to v11 because the theme's Mermaid styling targets v11.

## Style (from the owner's previous deck)
Reference: `dirien/stop-wasting-gpus-how-we-built-a-golden-path-for-gpu-sharing-on-kubernetes`, `slides/slides.md`.
- Frontmatter: `colorSchema: dark`, `canvasWidth: 1920`, `aspectRatio: 16/9`, `transition: slide-left`, `mdc: true`, `highlighter: shiki`, `lineNumbers: false`.
- Statement slides: centered absolute `div`, one `h1` (`!text-[5.5rem]` to `!text-[10rem]`), key words in `<span class="text-[var(--p-primary)]">`.
- Meme slides: `class: 'meme-slide'`, image in `.meme-frame`, no words.
- Content slides: short declarative `# Title ending with a period.`, cards and `v-click` reveals, code in `<div class="big-code">`, one primary-coloured takeaway line.
- Speaker notes on every slide (`<!-- ... -->`): timing first (`~10s.`), what to say and when to pause, then `Fact-check:` / `Sources:` lines.
- Close: `Q&A`, `Thanks.`, `Resources` (contact cards + QR codes).

## Draft status
Story arc (2026-10-05): opening Friday/Monday → amnesia → three fixes everyone tries → second brains and Karpathy's LLM wiki → "Memory is a search problem" → where each memory lives, agent-memory, ES|QL recall, why Elasticsearch, when you don't need it → **keeping memory true** (a wrong memory reaches every agent; System 2 writes, System 1 decides; curation diagram; Jev votes, Painless decides; why Jev; typed isn't true) → Pulumi (incl. the restapi connector slide) → demo (DEMO.md: a bug you only debug once; the sandboxes and placeholder keys are explained in its intro) → close. Don't cite third-party YouTube creators on slides. ~30 min of noted timing.
Open items:
- Slide 3 (Friday/Monday) and the Memento captions still tell the WiFi story; the demo is now the recall-ranking bug. Align them or keep the WiFi hook.
- Slide 3 replies are reconstructed; replace with real screenshots.
- Slides 5-7: the Memento still (`public/memento-leonard.jpg`, from srcdn.com) is local only, not committed (public repo).
- Check ES|QL `DECAY`'s default function (linear vs exp) before calling it a forgetting curve.
- QR codes (slide 17 and Resources) load from `api.qrserver.com` at render time; targets decoded and verified 2026-10-06. Pre-render them as PNGs into `public/` if the venue WiFi is bad.
- `infra/main.tf` carries `# #region project` / `# #region provider` markers for the HCL slide; keep them when editing that file.

## Verified story material (use these, don't invent numbers)
| Beat | Fact | Evidence |
|------|------|----------|
| Memory lost its body | upstream memory-sync ran `sed '1,/^---$/d'` twice: every synced memory had empty content; `type` nested under `metadata:` was never read | commit `a802511` |
| Recall was broken | ES\|QL `DECAY` rejects `"45d"`; needs a time duration (`1080 hours`), so default hybrid recall failed on every query | `acb536f` |
| Dashboard rejected | Kibana's dashboards API has no `treemap` panel type; became a `pie` with explicit defaults to stop drift | `17acb64` |
| Pulumi HCL + any TF provider, almost | `elastic/elasticstack` 0.16.1+ has a required `_id` attribute; `terraform-provider` 1.4.0 turned that into a hard error (pulumi-terraform-bridge#3597), 1.3.0 still loads it; running 0.16.5 on 1.3.0 | issue pulumi/pulumi-terraform-provider#117 |
| HCL shape | list-of-object properties are blocks (`dynamic "panels"`), single objects are arguments | `b148192` |
| Config as ESC, not `.env` | `pulumiservice_environment` writes `agent-memory/runtime` from stack outputs; `pulumi env run ... -- claude` | `adb86b9`, `../infra/esc.tf` |
| Sandbox proxy vs Pulumi | proxy overwrites `Authorization` on `api.pulumi.com`, update-token calls get 401, so state is local in sandboxes | `fc357ce`, `../kit/README.md` |
| Keys never enter the box | `set-custom` placeholder replaced only on matching hosts; any other `ApiKey` value got 401; survived a key rotation | `../kit/README.md` |
| MCP env gotcha | Claude Code expands `${VAR}` in MCP config from the process environment only; `settings.json` `env` didn't reach it (tested with `claude -p`) | `7415694` |
| Timeouts behind a proxy | each proxied request ~1 s; bridge's 2 s online probe made the first SessionStart look offline; `BRIDGE_CHECK_TIMEOUT` | `2dac697` |
| Title-only recall | a fresh sandbox found the right memory but only saw its title; recall now prints content, SessionStart lists open tasks | `7cde8a3`, `3462297` |
| Placeholder mistaken for a leak | Claude called `sbx-cs-...` a live credential; the hook now says it's a placeholder | `76515b9` |
| Who writes what | Claude via `bridge remember` (`source: bridge-cli`), hooks via auto-memory sync (`source: auto-memory`); MCP key is read-only, write = 403 | `../DEMO.md` |
| Stack size | 20 resources with curation on: Serverless project, 8 indices (the bridge's 7 + `agent-curation`), 2 API keys, dashboard, ESC env, Jev connector, curation workflow, 4 providers, stack | `scripts/pulumi.sh stack` (2026-10-06) |
| MCP surface | Kibana Agent Builder MCP server exposes 22 tools; demo uses execute/generate ES\|QL | `tools/list` on the endpoint |

Credit the base project: agent-memory by Jeff Vestal (Elastic), `github.com/jeffvestal/agent-memory`.

## Examples
Statement slide, as used in `slides.md`:
```md
<div class="absolute inset-0 flex flex-col justify-center items-center px-20 text-center">
  <h1 class="!text-[7rem] !leading-tight !font-semibold !tracking-tight !m-0 !max-w-[95%]">
    Memory is a <span class="text-[var(--p-primary)]">search problem.</span>
  </h1>
</div>
```
Real code on a slide (stays in sync with `infra/`):
```md
<div class="big-code !mt-4">

<<< @/snippets/infra/dashboard.tf hcl

</div>
```

## Security
- Slides and notes never contain key values, and no `sbx-cs-...` placeholders either (they look like keys on screen).
- Endpoint hosts of the live project are fine to show; API keys, the state passphrase and `.pulumi-state` contents are not.
- Terminal recordings for the fallback videos: record with the placeholders, never with `pulumi env run` output that prints secrets.

## Checklist
- [ ] `npm run build` passes (paste the output)
- [ ] every new claim has a `Fact-check:` / `Sources:` line in the notes
- [ ] every slide has timing in its notes; the total fits ~30 min plus Q&A
- [ ] code slides import from `snippets/infra/` instead of copying code

## When stuck
| Problem | Fix |
|---------|-----|
| `Code snippet path escapes the project root` | import through `snippets/infra/...`, not `../infra/...` |
| a layout name doesn't work | layouts and their props: `node_modules/@pulumi/slidev-theme/README.md` |
| Mermaid renders unstyled | keep `mermaid` on v11; the theme's styling targets v11 |
| unsure whether a fact is true | check the Verified story material table, then the commit it cites (`git show <sha>`) |

## Boundaries
- Ask before restructuring the deck or cutting sections; the owner wants to discuss the slides.
- Every number or claim on a slide needs a line in that slide's `Fact-check:` / `Sources:` notes.
- Run `npm run build` after edits and show its output.
- Don't commit `node_modules/`, `dist/`, `.slidev/` (gitignored).
