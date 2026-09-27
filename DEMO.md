# Demo runbook: two sandboxes, one memory

The story: on **Friday** you work with Claude in sandbox `mem-a`. It learns a
constraint and you leave a task half done. On **Monday** you open a brand-new
sandbox `mem-b`: new container, new home directory, so Claude's local
auto-memory is empty. Claude still knows the constraint and finds the open task,
because both live in Elasticsearch. Then you ask the same memory questions
through the Elastic MCP server, without the `bridge` CLI.

## 0. Before you start (host)

```bash
sbx version                      # kit schema v2 needs sbx >= 0.38.0
sbx settings set kit.allowedSources '["docker.io/","ghcr.io/dirien/","github.com/dirien/"]'
sbx secret ls                    # the global `pulumi` secret must exist

E=dirien/agent-memory/runtime    # written by the Pulumi program (infra/esc.tf)
PULUMI_BIN="$(command -v pulumi)" # sbx wants an absolute path for --command

# Keys stay on the host: the sandbox gets placeholders, sandboxd resolves the real
# values from ESC when a request to the matching host needs them. One-time setup.
sbx secret set-custom --host '*.es.us-east-1.aws.elastic.cloud' --env BRIDGE_ES_API_KEY \
  --command "$PULUMI_BIN env get $E elastic.bridgeApiKey --value string --show-secrets | tr -d '\n'"
sbx secret set-custom --host '*.kb.us-east-1.aws.elastic.cloud' --env ELASTIC_MCP_API_KEY \
  --command "$PULUMI_BIN env get $E elastic.mcpApiKey --value string --show-secrets | tr -d '\n'"

# Settings aren't secret; pass them at creation.
v() { pulumi env get "$E" "elastic.$1" --value string; }
MEM_ENV=(--env BRIDGE_ES_URL="$(v esUrl)" --env BRIDGE_AGENT_ID="$(v agentId)" --env ELASTIC_KIBANA_HOST="$(v kibanaHost)")
KITS=(--kit ghcr.io/dirien/infrastructure-kit:v0.10.5 --kit ghcr.io/dirien/agent-memory-kit:v0.2.2)

mkdir -p /tmp/nyc-demo           # any project; the kit brings agent-memory itself
```

If a `set-custom` says the variable already exists, the secret is set from an
earlier run; keep it, or repoint it as described in
[`kit/README.md`](kit/README.md#run-it).

The Elasticsearch indices start empty (see Reset). There are no `.env` files
anywhere.

Exit every Claude session with `/exit`: that runs the SessionEnd hook. Detaching
(`Ctrl-\`) leaves the session running and does not.

## Act 1: Friday, sandbox `mem-a`

```bash
sbx create --name mem-a --skills=off "${MEM_ENV[@]}" "${KITS[@]}" claude /tmp/nyc-demo
sbx run --name mem-a
```

Smoke checks in the new session (prefix with `!` to run them in the shell):

```text
! bridge status                  # online, 7 indices; agent-status has the session's heartbeat
! echo "$BRIDGE_ES_API_KEY"       # sbx-cs-… placeholder, not the key
/mcp                             # elastic-memory connected
```

Then give Claude this prompt:

```text
I'm preparing my talk "Give Your Coding Agent an (Elastic) Memory" for the Elastic NYC meetup on October 6.
Two things for later sessions:
1. The venue WiFi is unreliable, so every live demo step needs a pre-recorded fallback video. Treat that as a hard constraint for the demo.
2. Track a task: pre-render the QR codes on the Resources slide as PNGs. I'll do the actual work in a later session, so leave it open.
Don't change any files in the repository.
```

Claude stores the constraint with `bridge remember` and starts the task with
`bridge task start`. When it's done, `/exit`: the SessionEnd hook logs the
session end and suspends the task.

**Check** (from any shell with the runtime environment, or over MCP):

```sql
// 1 memory, source bridge-cli (or auto-memory if Claude used its own memory)
FROM agent-memory | KEEP created_at, type, source, title
// 1 task, status suspended
FROM agent-tasks | KEEP task_id, status, title, machine
// task created, session-end (prompt_input_exit), task suspended
FROM agent-sessions | KEEP timestamp, action, summary, machine | SORT timestamp
```

## Act 2: Monday, sandbox `mem-b`

Same command, new name. The project folder is the same; the home directory, and
with it Claude's local auto-memory, is not.

```bash
sbx create --name mem-b --skills=off "${MEM_ENV[@]}" "${KITS[@]}" claude /tmp/nyc-demo
sbx run --name mem-b
```

```text
regarding my prep for the talk, how was the wifi?
```

Expected: one `bridge recall`, then the constraint in Claude's own words: the
venue WiFi is unreliable, so every live demo step needs a pre-recorded fallback
video. `recall` prints each memory's content, not just its title.

```text
And what's still open from that session?
```

Expected: the suspended QR task with its ID. The SessionStart hook already put
the open tasks into the session's context, so Claude answers without searching.

## Act 3: the same memory over MCP (still in `mem-b`)

```text
Use only the elastic-memory MCP server, not the bridge CLI or Bash. Run ES|QL to show (1) every memory with its type, source and title, and (2) tasks grouped by status. Reply with two small markdown tables and the exact ES|QL queries you ran.
```

Expected: `elastic-memory` calls only (usually Generate ES|QL, then Execute
ES|QL), and tables matching Act 1. Then open the Kibana dashboard to show the
same data (`scripts/pulumi.sh stack output dashboard_url` from the clone).

## Reset

```bash
/exit                                   # in each session
sbx rm mem-a mem-b
```

Wipe the indices before the talk (from the agent-memory clone, keys from ESC):

```bash
pulumi env run dirien/agent-memory/runtime -- bash -c '
  for idx in agent-memory agent-messages agent-sessions agent-tasks agent-status claude-entities claude-entity-history; do
    curl -s -X POST -H "Authorization: ApiKey $BRIDGE_ES_API_KEY" -H "Content-Type: application/json" \
      "$BRIDGE_ES_URL/$idx/_delete_by_query?refresh=true" -d "{\"query\":{\"match_all\":{}}}"
  done'
```

## Good to know on stage

- Each request through the sandbox proxy takes about a second, so the task shows
  as `suspended` a few seconds after `/exit`, and a new write needs a moment
  before search sees it.
- Who wrote what: `source: bridge-cli` memories come from Claude calling
  `bridge remember`, `source: auto-memory` ones from the hooks syncing Claude's
  own memory files. The MCP key is read-only; a write with it gets `403`.
- With a single memory in the index, semantic recall returns it for any query:
  the nearest neighbour always comes back.
- Printing `BRIDGE_ES_API_KEY` or `ELASTIC_MCP_API_KEY` shows the `sbx-cs-…`
  placeholder. That's the point; there is nothing to rotate.
- If `elastic-memory` doesn't connect (no `ELASTIC_KIBANA_HOST` or placeholder
  in the environment), Claude falls back to the `bridge` CLI on its own.
