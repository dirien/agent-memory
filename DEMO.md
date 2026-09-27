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

Then run for real on 2026-09-27 in two fresh sandboxes, `mem-a` and `mem-b`
(both created with `--kit ghcr.io/dirien/infrastructure-kit:v0.10.5 --kit ./kit`),
each step checked in Elasticsearch from a third session:

- `sbx secret set-custom --command "pulumi env get ..."` stored the MCP key as a
  placeholder (`sbx-cs-…`); inside the sandbox `ELASTIC_MCP_API_KEY` held only the
  placeholder, and `/mcp` showed `elastic-memory` connected and authenticated
  (22 tools) after the one-time approval. A request with any other `ApiKey`
  value got `401`; after rotating the key in Pulumi + ESC, the placeholder kept
  working without touching the sbx secret.
- SessionStart ran in each fresh sandbox; the heartbeat reports the sandbox
  name (`mem-a`, `mem-b`) as `machine`.
- Act 1: Claude stored the constraint with `bridge remember` this time (the
  rehearsal had used auto-memory; both land in `agent-memory`), created the QR
  task, and `/exit` logged `session-end` with reason `prompt_input_exit`; the
  task was `suspended` two seconds later.
- Act 2: asked only "regarding my prep for the talk, how was the wifi?", `mem-b`
  called `elastic-memory` and answered with the constraint; every detail matched
  the stored document, and the constraint exists nowhere in the repo.
- Act 3: MCP only (Generate ES|QL, then Execute ES|QL); both tables matched the
  same queries run directly against Elasticsearch.

Still unchecked: the kit startup step's own effects (the `bridge` symlink in
`~/.local/bin`, its `apm install` run). The hooks find `bridge` through the
project directory either way.

## 0. Before you start (host)

```bash
cd ~/workshops/give-your-coding-agent-an-elastic-memory   # this repo on the host

sbx version                      # kit schema v2 needs sbx >= 0.38.0
sbx kit validate ./kit
sbx settings set kit.allowedSources '["docker.io/","ghcr.io/dirien/","github.com/dirien/"]'
sbx secret ls                    # the global `pulumi` secret must exist (ESC reads)

# The MCP key lives in ESC (mcp.apiKey); sbx resolves it on the host when needed,
# the sandbox only sees a placeholder. sbx wants an absolute path for --command.
E=dirien/agent-memory/elastic-cloud
PULUMI_BIN="$(command -v pulumi)"
sbx secret set-custom --host '*.kb.us-east-1.aws.elastic.cloud' --env ELASTIC_MCP_API_KEY \
  --command "$PULUMI_BIN env get $E mcp.apiKey --value string --show-secrets | tr -d '\n'"
ELASTIC_KIBANA_HOST="$(pulumi env get $E mcp.kibanaHost --value string)"
```

If `sbx` rejects the `--command` check, store the value instead:
`--value "$(pulumi env get $E mcp.apiKey --value string --show-secrets)"`.
To put the key into ESC in the first place (after `pulumi up`):
`scripts/pulumi.sh stack output mcp_api_key --show-secrets | tr -d '\n' | pulumi env set $E mcp.apiKey --secret -f -`.

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
