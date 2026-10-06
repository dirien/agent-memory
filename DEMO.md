# Demo runbook: a bug you only debug once

The story is ordinary developer work on a real codebase, this repo:

- **Friday**, sandbox `fri`: you notice `bridge recall --keyword` ranks a
  months-old memory above last week's. Claude finds out why (only hybrid
  recall applies the time decay), you're about to leave, so it keeps the
  finding and opens a task.
- **Monday**, sandbox `mon`: a new machine, so a new container, a new home
  directory and empty auto-memory. "Let's fix the recall ranking issue from
  Friday" goes straight to the fix: the open task is in the session's context
  and the root cause comes back with one recall. No re-investigation.
- **Wednesday**, sandbox `wed`: the Friday finding is no longer true. Either
  Claude retired it with `forget --superseded-by` on Monday, or the
  memory-curation workflow did within a minute (Jev votes, Painless decides).
  "Does keyword recall look at age?" gets today's answer, not Friday's.
- Finally the same memory over the Elastic MCP server, and Kibana.

Nothing is scripted into the memory: the facts are real (`lib/memory.sh`
applies `DECAY` only in the hybrid ES|QL path; `--keyword` sorts by score with
`updated_at` as a tie-break, `--semantic` ignores age), and Claude stores them
because the agent-memory skill tells it to. Don't fix this in `main` before
the talk, or Friday has nothing to find. The demo clone leaves out this file
and `slides/`, which describe the bug: a `grep` on Friday must find the code,
not the answer.

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

# The project Claude works on: a fresh clone of this repo, without DEMO.md and
# slides/ (both spell out the bug Claude is meant to find on Friday)
rm -rf ~/demo/agent-memory && git clone -q --no-checkout https://github.com/dirien/agent-memory ~/demo/agent-memory \
  && git -C ~/demo/agent-memory sparse-checkout set --no-cone '/*' '!/DEMO.md' '!/slides/' \
  && git -C ~/demo/agent-memory checkout -q main
cd ~/workshops/give-your-coding-agent-an-elastic-memory   # for scripts/demo-sandbox.sh
```

If a `set-custom` says the variable already exists, the secret is set from an
earlier run; keep it, or repoint it as described in
[`kit/README.md`](kit/README.md#run-it).

`scripts/demo-sandbox.sh <name> <workspace>` creates each sandbox with the
settings from `$E` and the kits (`KIT` defaults to
`ghcr.io/dirien/agent-memory-kit:latest`, whose `KIT_REF` is pinned to the
commit it was published from). It's plain bash, so zsh can't trip over it.

The backend has the memory-curation workflow deployed (`infra/curation.tf`,
needs `typesafe_api_key` in the stack config): it runs every minute and
supersedes, links or flags memories that a newer one contradicts. The indices
start empty (see Reset).

Exit every Claude session with `/exit`: that runs the SessionEnd hook. Detaching
(`Ctrl-\`) leaves the session running and does not.

## Act 1: Friday, sandbox `fri`

```bash
scripts/demo-sandbox.sh fri ~/demo/agent-memory && sbx run --name fri
```

Smoke checks in the new session (prefix with `!` to run them in the shell):

```text
! bridge status                  # online, exit 0
! echo "$BRIDGE_ES_API_KEY"       # sbx-cs-… placeholder, not the key
/mcp                             # elastic-memory connected
```

```text
I noticed `bridge recall --keyword` ranks a months-old memory above one from last week, while plain `bridge recall` gets the order right. Find out why. Don't change any code, I'm about to head out.
```

Expected: Claude reads `lib/memory.sh` and explains that only the hybrid
ES|QL path multiplies the score by `DECAY(created_at, ...)`; `--keyword` sorts
by `_score` with `updated_at` only as a tie-break, and `--semantic` has no
recency at all.

```text
Good find. I'll fix it on Monday, keep what you found and leave the fix as an open task.
```

Expected: one `bridge remember` with the root cause (file and lines) and a
`bridge task start`. Then `/exit`: the SessionEnd hook suspends the task.

## Act 2: Monday, sandbox `mon`

Same project folder, new machine:

```bash
scripts/demo-sandbox.sh mon ~/demo/agent-memory && sbx run --name mon
```

```text
Let's fix the recall ranking issue from Friday.
```

Expected: the suspended task is already in the session's context; one
`bridge recall` brings back Friday's root cause, and Claude goes straight to
`lib/memory.sh`: a time decay on `created_at` (the same
`BRIDGE_MEMORY_DECAY_WINDOW`) for the `--keyword` and `--semantic` queries,
checked with `./bridge recall --keyword`. It closes the task and remembers the
new state. Talk over the edit; it takes a minute or two.

Then `/exit`. Within about a minute Friday's finding is superseded: by Claude
(`bridge forget <id> --superseded-by <id>`, as the skill says) or by the
curation workflow.

## Act 3: Wednesday, sandbox `wed`

```bash
scripts/demo-sandbox.sh wed ~/demo/agent-memory && sbx run --name wed
```

```text
Before I touch recall: do --keyword and --semantic take a memory's age into account?
```

Expected: yes, since Monday's fix, and nothing about Friday's "only hybrid
decays", because recall hides superseded memories.

## Act 4: the same memory over MCP (still in `wed`)

```text
Use only the elastic-memory MCP server, not the bridge CLI or Bash. Show the memories about recall ranking with their status and superseded_by, and the agent-curation decisions with their outcome.
```

Expected: `elastic-memory` calls only; Friday's finding with
`status=superseded` and `superseded_by` pointing at Monday's memory. If the
curation workflow did it, `agent-curation` has the pair with
`outcome=superseded` and Jev's votes. Then the Kibana dashboard
(`AGENT_MEMORY_BACKEND=local scripts/pulumi.sh stack output dashboard_url` in
this checkout, which holds the stack state; not in `~/demo`).

## Reset

```bash
/exit                                   # in each session
sbx rm fri mon wed
rm -rf ~/demo/agent-memory && git clone -q --no-checkout https://github.com/dirien/agent-memory ~/demo/agent-memory \
  && git -C ~/demo/agent-memory sparse-checkout set --no-cone '/*' '!/DEMO.md' '!/slides/' \
  && git -C ~/demo/agent-memory checkout -q main
```

Wipe the indices before the talk (from this repo, keys from ESC):

```bash
pulumi env run dirien/agent-memory/runtime -- bash -c '
  for idx in agent-memory agent-messages agent-sessions agent-tasks agent-status agent-curation claude-entities claude-entity-history; do
    curl -s -X POST -H "Authorization: ApiKey $BRIDGE_ES_API_KEY" -H "Content-Type: application/json" \
      "$BRIDGE_ES_URL/$idx/_delete_by_query?refresh=true" -d "{\"query\":{\"match_all\":{}}}"
  done'
```

## Good to know on stage

- Each request through the sandbox proxy takes about a second, so the task shows
  as `suspended` a few seconds after `/exit`, and a new write needs a moment
  before search sees it.
- The curation workflow runs every minute and only judges memories without
  `curated_at`; each new memory is compared with its three nearest older
  neighbours. Every decision lands in `agent-curation` with its `outcome`.
- Who wrote what: `source: bridge-cli` memories come from Claude calling
  `bridge remember`, `source: auto-memory` ones from the hooks syncing Claude's
  own memory files. The MCP key is read-only; a write with it gets `403`.
- Printing `BRIDGE_ES_API_KEY` or `ELASTIC_MCP_API_KEY` shows the `sbx-cs-…`
  placeholder. That's the point; there is nothing to rotate.
- If `elastic-memory` doesn't connect (no `ELASTIC_KIBANA_HOST` or placeholder
  in the environment), Claude falls back to the `bridge` CLI on its own.
- The fix Claude writes on Monday is real but stays in `~/demo/agent-memory`;
  Reset throws it away so Friday has something to find next time.
