---
name: agent-memory
description: "Persistent memory in Elasticsearch via the `bridge` CLI. Use before re-deriving a decision, convention, or fix from an earlier session; when the user says 'remember', 'last time', 'we decided', or 'pick up where we left off'; after making a decision worth keeping; and when handing work to another session or agent."
---

# agent-memory

Your context window resets between sessions. This project keeps decisions,
session history, tasks and indexed markdown in Elasticsearch, reachable through
the `bridge` CLI. One recall query is cheaper than re-reading files or asking
the user again.

## Recall before you re-derive

| Need | Command |
|---|---|
| Something you or an earlier session decided | `bridge recall "<what you're looking for>"` |
| Only one kind of memory | `bridge recall "<query>" --type decision` |
| Content of indexed project docs | `bridge graph search "<query>"` |
| What happened recently | `bridge history --last 7d` |
| Unfinished work from a previous session | `bridge task open` (the session start already lists it) |

`bridge recall` is hybrid (BM25 + Jina v5 semantic, fused with ES|QL
FORK/FUSE) and decays older memories, so phrase the query the way you would ask
a colleague, not as keywords. It skips memories that were superseded or are
duplicates of another one.

## Remember what is worth keeping

Store a memory when you settle something a future session would otherwise
re-litigate: an architecture choice, a convention the user corrected, the root
cause of a bug, a credential *location* (never the value).

```bash
bridge remember decision "Use Pulumi HCL for the Elastic stack; pin the terraform-provider plugin to 1.3.0" \
  --title "IaC choice" --tags pulumi,elastic
```

Types: `decision`, `feedback`, `project`, `reference`, `observation`.
Add `--scope shared` when other agents should see it.

Do not store secrets, tokens, or anything the repo or git history already records.

## When a stored fact changes

Remember the new state first, then retire the old memory and link it to the
new one, so the history stays readable:

```bash
bridge remember decision "terraform-provider 1.5.0 fixed the _id error; drop the 1.3.0 pin" --title "Provider pin removed"
bridge forget <old_memory_id> --superseded-by <new_memory_id>
```

If you're not sure an older memory is now wrong, only remember the new one.
Where the memory-curation workflow runs, it compares every new memory with its
older neighbours within about a minute and supersedes, links or flags them.

## Track multi-step work

```bash
bridge task start "Wire Kibana dashboard" --priority high
bridge task update <task_id> --note "panels render, metric labels wrong"
bridge task done <task_id> --outcome "dashboard deployed via Pulumi"
```

A session that ends mid-task suspends it automatically (SessionEnd hook), so the
next session sees it in its opening context and with `bridge task open`.

## What the hooks already do

- **SessionStart**: syncs `~/.claude/projects/<project>/memory/*.md` into the
  `agent-memory` index and sends a heartbeat.
- **PostToolUse** (Write/Edit): indexes every markdown file you write as a
  searchable entity.
- **SessionEnd**: logs the session end and suspends in-flight tasks.

If `bridge status` says offline, writes queue locally and `bridge sync` flushes
them later. Don't block on it.
