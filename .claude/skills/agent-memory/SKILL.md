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
| Unfinished work from a previous session | `bridge task list --status suspended` |

`bridge recall` is hybrid (BM25 + Jina v5 semantic, fused with ES|QL
FORK/FUSE) and decays older memories, so phrase the query the way you would ask
a colleague, not as keywords.

## Remember what is worth keeping

Store a memory when you settle something a future session would otherwise
re-litigate: an architecture choice, a convention the user corrected, the root
cause of a bug, a credential *location* (never the value).

```bash
bridge remember decision "Use Pulumi HCL for the Elastic stack; pin elasticstack to 0.16.0" \
  --title "IaC choice" --tags pulumi,elastic
```

Types: `decision`, `feedback`, `project`, `reference`, `observation`.
Add `--scope shared` when other agents should see it.

Do not store secrets, tokens, or anything the repo or git history already records.

## Track multi-step work

```bash
bridge task start "Wire Kibana dashboard" --priority high
bridge task update <task_id> --note "panels render, metric labels wrong"
bridge task done <task_id> --outcome "dashboard deployed via Pulumi"
```

A session that ends mid-task suspends it automatically (SessionEnd hook), so the
next session finds it with `bridge task list --status suspended`.

## What the hooks already do

- **SessionStart**: syncs `~/.claude/projects/<project>/memory/*.md` into the
  `agent-memory` index and sends a heartbeat.
- **PostToolUse** (Write/Edit): indexes every markdown file you write as a
  searchable entity.
- **SessionEnd**: logs the session end and suspends in-flight tasks.

If `bridge status` says offline, writes queue locally and `bridge sync` flushes
them later. Don't block on it.
