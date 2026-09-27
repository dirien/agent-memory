# Demo runbook: two sandboxes, one memory

The story: on **Friday** you work with Claude in sandbox `mem-a`. It learns a
constraint and you leave a task half done. On **Monday** you open a brand-new
sandbox `mem-b`: new container, new home directory, so Claude's local
auto-memory is empty. Claude still knows the constraint and finds the open task,
because both live in Elasticsearch. Then you ask the same memory questions
through the Elastic MCP server, without the `bridge` CLI.

## What's verified, what isn't yet

Rehearsed on 2026-09-27 with headless `claude -p` sessions in one sandbox,
moving the local auto-memory aside between sessions, and checked in
Elasticsearch after each step:

- Act 1: Claude saved the constraint to its own auto-memory (Write tool), the
  PostToolUse hook synced it to `agent-memory` within the session (type
  `project`, full body), `bridge task start` created the task, and the SessionEnd
  hook suspended it.
- Act 2: with an empty local memory folder, Claude answered from Elasticsearch:
  the constraint, the suspended task by ID, and what's still open.
- Act 3: with `ELASTIC_KIBANA_HOST` and `ELASTIC_MCP_API_KEY` in the process
  environment, Claude used only `platform_core_execute_esql` and returned both
  tables.

Not verified yet (needs `sbx` on the host, which is what this run is for):
`sbx kit validate`, the kit's startup step (bridge on PATH, `apm install`), the
`set-custom` placeholder for the MCP key, the interactive MCP approval, the
SessionEnd reason for `/exit`, and the `machine` name a new sandbox reports.

## 0. Before you start (host)

```bash
cd ~/workshops/give-your-coding-agent-an-elastic-memory   # this repo on the host

sbx version                      # kit schema v2 needs sbx >= 0.38.0
sbx kit validate ./kit
sbx settings set kit.allowedSources '["docker.io/","ghcr.io/dirien/","github.com/dirien/"]'
sbx secret ls                    # the global `pulumi` secret must exist (ESC reads)

set -a; . ./.mcp.env; set +a     # ELASTIC_KIBANA_HOST + ELASTIC_MCP_API_KEY
sbx secret set-custom --host '*.kb.us-east-1.aws.elastic.cloud' \
  --env ELASTIC_MCP_API_KEY --value "$ELASTIC_MCP_API_KEY"
```

`.env` and `.mcp.env` already exist in the workspace (written by
`scripts/write-env.sh`), and the Elasticsearch indices start empty.

Exit every Claude session with `/exit`: that runs the SessionEnd hook. Detaching
(`Ctrl-\`) leaves the session running and does not.

## Act 1: Friday, sandbox `mem-a`

```bash
sbx create --name mem-a --skills=off \
  --env ELASTIC_KIBANA_HOST="$ELASTIC_KIBANA_HOST" \
  --kit ghcr.io/dirien/infrastructure-kit:v0.10.5 --kit ./kit \
  claude .
sbx run --name mem-a
```

`--name` matters: without it the sandbox is named `claude-<folder>`, the same as
the sandbox this repo was built in, and `sbx run` would re-attach to that one.

Smoke checks in the new session (prefix with `!` to run them in the shell):

```text
! bridge status                  # ES connectivity: online, 7 indices
! echo "$ELASTIC_MCP_API_KEY"     # a placeholder, not the key
/mcp                             # approve elastic-memory; it should show connected
```

Then give Claude this prompt:

```text
I'm preparing my talk "Give Your Coding Agent an (Elastic) Memory" for the Elastic NYC meetup on October 6.
Two things for later sessions:
1. The venue WiFi is unreliable, so every live demo step needs a pre-recorded fallback video. Treat that as a hard constraint for the demo.
2. Track a task: pre-render the QR codes on the Resources slide as PNGs. I'll do the actual work in a later session, so leave it open.
Don't change any files in the repository.
```

Swap in a real constraint if you have one; the mechanics don't depend on the
wording. When Claude is done, `/exit`.

**Check** (Claude in the build session runs these, or use `bridge`):

```sql
// 1 memory, source auto-memory (or bridge-cli if Claude used `bridge remember`)
FROM agent-memory | KEEP created_at, type, source, title
// 1 task, status suspended
FROM agent-tasks | KEEP task_id, status, title, machine
// task created, session-end, task suspended
FROM agent-sessions | KEEP timestamp, action, summary, machine | SORT timestamp
```

## Act 2: Monday, sandbox `mem-b`

Same command, new name. The workspace is the same; the home directory, and with
it `~/.claude/projects/.../memory/`, is not.

```bash
sbx create --name mem-b --skills=off \
  --env ELASTIC_KIBANA_HOST="$ELASTIC_KIBANA_HOST" \
  --kit ghcr.io/dirien/infrastructure-kit:v0.10.5 --kit ./kit \
  claude .
sbx run --name mem-b
```

```text
Pick up where we left off on the talk prep. What's still open, and which constraints did we agree on for the demo? Don't change any files.
```

Expected: Claude names the WiFi / fallback-video constraint and the suspended QR
task (with its ID). In the rehearsal it also pointed out that its local memory
folder was empty, so the answer came from Elasticsearch. It gets there through
the SessionStart hook's hint and `bridge recall` / `bridge task list`.

**Check**: `bridge history --last 1h` lists events from both machines.

## Act 3: the same memory over MCP (still in `mem-b`)

```text
Use only the elastic-memory MCP server, not the bridge CLI or Bash. Run ES|QL to show (1) every memory with its type, source and title, and (2) tasks grouped by status. Reply with two small markdown tables and the exact ES|QL queries you ran.
```

Expected: a `platform_core_execute_esql` call per query, and tables matching
Act 1. Then open the Kibana dashboard (`dashboard_url` stack output) to show the
same data.

## Reset

```bash
/exit                                   # in each session
sbx rm mem-a mem-b
sbx secret ls                           # remove the custom secret if you like
```

Wipe the indices before the talk (from any shell with `.env` loaded):

```bash
set -a; . ./.env; set +a
for idx in agent-memory agent-messages agent-sessions agent-tasks agent-status claude-entities claude-entity-history; do
  curl -s -X POST -H "Authorization: ApiKey $BRIDGE_ES_API_KEY" -H 'Content-Type: application/json' \
    "$BRIDGE_ES_URL/$idx/_delete_by_query?refresh=true" -d '{"query":{"match_all":{}}}'
done
```

## Things we saw while rehearsing

- Headless `claude -p` sessions end with SessionEnd reason `other`.
- A `claude mcp list` run in the project also logged a `session-end` event.
- `bridge` writes need a second or two before search sees them (Serverless refresh).
- If `ELASTIC_MCP_API_KEY` isn't in Claude's environment, `elastic-memory`
  fails to connect and Claude falls back to the `bridge` CLI on its own.
