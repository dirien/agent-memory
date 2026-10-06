---
theme: "@pulumi/slidev-theme"
title: "Give Your Coding Agent an (Elastic) Memory"
info: |
  Give Your Coding Agent an (Elastic) Memory.
  Engin Diri — Pulumi.

  Elastic NYC User Group × Pulumi, October 6 2026.

  Repo: https://github.com/dirien/agent-memory
transition: slide-left
mdc: true
canvasWidth: 1920
aspectRatio: 16/9
highlighter: shiki
lineNumbers: false
colorSchema: dark
layout: cover
defaults:
  layout: default
---

<div class="absolute inset-0 flex flex-col justify-center items-start px-20">
  <h1 class="!text-[5.5rem] !leading-[1.02] !font-semibold !tracking-tight !mb-6 !max-w-[95%]">
    Give Your Coding Agent an <span class="text-[var(--p-primary)]">(Elastic)</span> Memory
  </h1>
  <p class="!mt-1 !text-[2.4rem] text-[var(--p-fg-muted)] !m-0 !leading-relaxed !max-w-[90%]">
    Decisions and session history that survive the context window.
  </p>
  <p class="!mt-10 !text-[1.8rem] text-[var(--p-fg-muted)] !m-0 !leading-relaxed">
    Engin Diri · Principal Solutions Architect, Pulumi<br/>
    Elastic NYC User Group × Pulumi · October 6, 2026
  </p>
</div>

<!--
~20s. Read the title. "(Elastic)" is the pun: stretchy memory, and the
company whose office we're in.
-->

---
class: soul-slide
---

# SOUL.md

<div class="h-[16px]"></div>

<<< @/snippets/soul.md md

<!--
~20s. Same intro as the GPU talk: I introduce myself the way an agent does.
Tonight's topic is what an agent remembers about itself, so it fits.
-->

---

<div class="term-grid !mt-2">
<div>
<div class="mem-caption">Friday, 5:40 PM</div>

```text
> The venue WiFi is unreliable, so every live demo
  step needs a pre-recorded fallback video.
  Also track a task: pre-render the QR codes on the
  Resources slide as PNGs. I'll do it later.

● Got it. Fallback videos for every demo step, and
  the QR task stays open for a later session.
```

</div>
<div v-click>
<div class="mem-caption mem-caption--accent">Monday, 9:05 AM</div>

```text
> regarding my prep for the talk, how was the wifi?

● I don't have any context about WiFi from a
  previous session. Could you tell me more about
  what you're preparing?
```

</div>
</div>

<!--
~60s. Tell it as a story, first person. "On Friday I was preparing this talk
with Claude. I told it two things." Read the Friday prompt. "It said: got it."
Pause. Click. "Monday morning, new session." Read the question, then the
answer. Wait for the laugh of recognition.

Dramatized: the Friday prompt is the one from DEMO.md; the replies are
reconstructed. TODO: replace both with real screenshots from a sandbox
without the agent-memory kit.
[TK: or swap in a real moment where Claude forgot something that cost you.]
-->

---

<div class="absolute inset-0 flex flex-col justify-center items-center px-20 text-center">
  <h1 class="!text-[7rem] !leading-tight !font-semibold !tracking-tight !m-0 !max-w-[95%]">
    Your coding agent has <span v-click class="text-[var(--p-primary)]">amnesia.</span>
  </h1>
</div>

<!--
~10s. Say "Your coding agent has...", click, "amnesia." Let it land.
Everyone here has explained the same convention to their agent three
sessions in a row.
-->

---
class: 'meme-slide'
---

<div class="meme-frame memento">
  <div class="memento__scene">
    <img src="/memento-leonard.jpg" alt="Leonard Shelby in Memento, holding up a Polaroid" />
    <div class="memento__photo">&gt; claude</div>
    <div class="memento__caption">WiFi is bad.<br/>Record every demo.</div>
  </div>
</div>

<!--
~10s. Memento. Leonard can't form new memories, so he runs on Polaroids
with notes on them. Say nothing and wait for the laugh, or: "Leonard, but
for your agent." This is Friday's first note.
Optional line: Karpathy, May 2025: "LLMs are quite literally like the guy in
Memento, except we haven't given them their scratchpad yet."
Sources: x.com/karpathy/status/1921368644069765486 (read via the fxtwitter
mirror; x.com returned 402). Still: Memento (2000), via srcdn.com; caption
font Permanent Marker (Apache 2.0), public/fonts/.
-->

---
class: 'meme-slide'
---

<div class="meme-frame memento">
  <div class="memento__scene">
    <img src="/memento-leonard.jpg" alt="Leonard Shelby in Memento, holding up a Polaroid" />
    <div class="memento__photo">MEMORY.md</div>
    <div class="memento__caption">QR codes:<br/>still open.</div>
  </div>
</div>

<!--
~5s. Second Polaroid: the open task. No words needed.
-->

---
class: 'meme-slide'
---

<div class="meme-frame memento">
  <div class="memento__scene">
    <img src="/memento-leonard.jpg" alt="Leonard Shelby in Memento, holding up a Polaroid" />
    <div class="memento__photo">/compact</div>
    <div class="memento__caption">Don't trust<br/>the summary.</div>
  </div>
</div>

<!--
~5s. Third Polaroid, and the bridge to the next slide: "Don't trust the
summary" is exactly where fix one breaks.
-->

---

# Fix one: never close the session.

<div v-click>
<div class="stat">53%</div>

<p class="stat-caption">
of safety instructions survived one round of compaction, even though the prompt asked to keep them all.
</p>

<p class="stat-source">University of Passau, arXiv:2608.22752</p>
</div>

<p v-click class="takeaway">/compact decides what your agent forgets. It doesn't ask you.</p>

<!--
~50s. Hand-raise: "Who has a session open right now that they're afraid to
close?" The first fix everyone tries is to keep the session alive. Long
sessions get compacted, and the summary keeps what the summary keeps.
[click] the number. [click] the takeaway.
After five rounds, each halving the text, 10% of the safety instructions
were left.
Fact-check: both figures as quoted in my "10 tips" post (2026-09-21), which
cites arXiv:2608.22752. https://www.pulumi.com/blog/10-tips-to-improve-your-coding-agent-game/
-->

---

# Fix two: write it down yourself.

<div v-click>
<div class="stat">73.8%</div>

<p class="stat-caption">
of AI configuration files in 441 repositories were committed once and never touched again.
</p>

<p class="stat-source">Denisov-Blanch et al., arXiv:2608.25241</p>
</div>

<p v-click class="takeaway">Every lesson needs a human to write it down, and to keep it true.</p>

<!--
~50s. Hand-raise: "Who has a CLAUDE.md or an AGENTS.md? Who changed it this
month?" [click] the number. The second fix: write the rules down. It works, and I still do it
(one screen, layered, a Stop hook that proposes updates; my May post). But
the file only knows what someone typed into it, and it goes stale.
Fact-check: 73.8% and 441 repositories as quoted in my "10 tips" post
(2026-09-21), citing arXiv:2608.25241.
-->

---

# Fix three: let the agent write it down.

<div class="code-xl !mt-2">

```text
~/.claude/projects/<project>/memory/
├── MEMORY.md        # index: first 200 lines or 25 KB load every session
├── user_role.md
└── feedback_testing.md
```

</div>

<div v-click class="quote-card !mt-8">
<p>"Files are not shared across machines or cloud environments."</p>
<p class="quote-by">Claude Code docs, auto memory</p>
</div>

<p v-click class="takeaway">New laptop, new sandbox, new teammate: back to zero.</p>

<!--
~50s. Claude Code's auto memory: the agent writes its own notes and an index,
and the index loads into every session. This is a real step up. It's also
the reason Friday's sandbox knew and Monday's didn't: Monday was a new
container with a new home directory.
If someone asks: the docs let you move the folder with autoMemoryDirectory,
for example into a synced directory. It's still a folder of Markdown files
that Claude reads by name, not something you can search.
Fact-check (code.claude.com/docs/en/memory, read 2026-10-05): "Each project
gets its own memory directory at ~/.claude/projects/<project>/memory/." "The
first 200 lines of MEMORY.md, or the first 25KB, whichever comes first, are
loaded at the start of every conversation." "Auto memory is machine-local.
... Files are not shared across machines or cloud environments." Topic files
(user_role.md, feedback_testing.md are the docs' own examples) are read on
demand, not at startup.
-->

---

<div class="absolute inset-0 flex flex-col justify-center items-center px-20 text-center">
  <h1 class="!text-[7rem] !leading-tight !font-semibold !tracking-tight !m-0 !max-w-[95%]">
    Second <span class="text-[var(--p-primary)]">brain!</span>
  </h1>
</div>

<!--
~5s. Section break. "Before we gave agents memory, we built it for
ourselves."
-->

---

# People have always kept a second brain.

<div class="timeline !mt-0">
<div v-click class="mem-card">
<img class="tl-img" src="/second-brain/memex.jpg" alt="Bush's 1945 sketch of the Memex: a desk with screens, levers and microfilm" />
<div class="year">1945</div>
<p>Vannevar Bush's Memex: "an enlarged intimate supplement to his memory."</p>
</div>
<div v-click class="mem-card">
<img class="tl-img" src="/second-brain/slip-box.png" alt="A Zettelkasten slip box linking fleeting, literature and permanent notes" />
<div class="year">1952</div>
<p>Niklas Luhmann starts a slip box that grows to about 90,000 cards.</p>
</div>
<div v-click class="mem-card">
<img class="tl-img" src="/second-brain/basb-para.png" alt="Building a Second Brain: Capture, Organize, Distill, Express, with the PARA folders" />
<div class="year">2022</div>
<p>Tiago Forte's <em>Building a Second Brain</em>.</p>
</div>
<div v-click class="mem-card mem-card--primary">
<img class="tl-img" src="/second-brain/llm-wiki.jpg" alt="The LLM Wiki: collect, compile, wiki" />
<div class="year">2026</div>
<p>Karpathy's LLM Wiki: the model keeps the notes.</p>
</div>
</div>

<div v-click class="quote-card !mt-6">
<p>"Humans abandon wikis because the maintenance burden grows faster than the value."</p>
<p class="quote-by">Andrej Karpathy, LLM Wiki gist, April 2026</p>
</div>

<!--
~60s. Hand-raise: "Who has an Obsidian vault? Who still keeps it up?"
We've built external memory for ourselves for a long time. Most personal
systems die the same way: nobody does the upkeep. Click through the four.
Fact-check:
- Bush, "As We May Think", The Atlantic, July 1945. Quote from the W3C
  mirror https://www.w3.org/History/1945/vbush/vbush6.shtml (The Atlantic
  blocked the fetch; check it there before the talk).
- Luhmann: Bielefeld University, a good 90,000 items; box 1 c. 1952-1962.
- Forte: first published June 14, 2022 (Atria).
- Karpathy gist created 2026-04-04:
  https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
Images (public/second-brain/, local only, not committed): Memex sketch via
erinkmalone.medium.com "Foreseeing the Future: The legacy of Vannevar Bush";
slip box from hybridhacker.email "How I take notes: mastering the basics";
LLM Wiki graphic from aimaker.substack.com "LLM Wiki + Obsidian"; CODE + PARA
diagram from workflowy.com/help/build-a-second-brain (basb-3.png).
-->

---

# The LLM does the upkeep now.

<div class="grid grid-cols-2 gap-10 !mt-2 items-center">
<div class="code-lg">

```text
raw/            sources you drop in
wiki/
├── index.md    one line per page
├── log.md      what changed, and when
└── *.md        pages the LLM writes and links
CLAUDE.md       the schema: how to keep the wiki
```

</div>
<div v-click class="quote-card">
<p>"The part he couldn't solve was who does the maintenance. The LLM handles that."</p>
<p class="quote-by">Karpathy, on the Memex, LLM Wiki gist</p>
</div>
</div>

<p v-click class="takeaway">Knowledge as code: the agent writes it, git keeps it, a pull request reviews it.</p>

<!--
~50s. Karpathy's gist: three layers (raw sources, the wiki, a schema file
such as CLAUDE.md or AGENTS.md) and three operations (ingest, query, lint).
[click] his line about the Memex. [click] the takeaway.
The index file works "surprisingly well at moderate scale (~100 sources,
~hundreds of pages)". In July I wrote about putting that wiki in git in a
format another agent can read (Google's Open Knowledge Format).
Fact-check: gist text; my post "Knowledge as Code: The Memory File Just Got
a Spec" (2026-07-14): https://www.pulumi.com/blog/knowledge-as-code-the-memory-file-just-got-a-spec/
-->

---

# Where the wiki stops.

<div class="grid grid-cols-2 gap-10 !mt-4">
<div class="quote-card">
<p>"At small scale the index file is enough, but as the wiki grows you want proper search."</p>
<p class="quote-by">Karpathy, LLM Wiki gist</p>
</div>
<div v-click class="quote-card">
<p>"A knowledge base you can't hand to someone else's agent is a silo of one."</p>
<p class="quote-by">Engin Diri, "Knowledge as Code", pulumi.com/blog, July 2026</p>
</div>
</div>

<!--
~40s. Two limits, in the authors' own words. The wiki gets too big to load
or grep, and it stays on one person's disk in one person's dialect.
Karpathy's gist goes on to recommend a local engine with hybrid BM25/vector
search. Hold that thought.
Fact-check: gist; my July post (above).
-->

---

<div class="absolute inset-0 flex flex-col justify-center items-center px-20 text-center">
  <h1 class="!text-[7rem] !leading-tight !font-semibold !tracking-tight !m-0 !max-w-[95%]">
    Memory is a<br/><span v-click class="text-[var(--p-primary)]">search problem.</span>
  </h1>
</div>

<!--
~15s. "Memory is a...", click, "search problem." And we're standing in the office of the company that does search.
-->

---

# Where each memory lives.

<table class="cmp !mt-2">
<thead>
<tr><th></th><th v-click="1">AGENTS.md</th><th v-click="2">Auto memory</th><th v-click="3">LLM wiki</th><th v-click="4" class="cmp-es">Elasticsearch</th></tr>
</thead>
<tbody>
<tr><td>Who writes it</td><td v-click="1">you</td><td v-click="2">the agent</td><td v-click="3">the agent</td><td v-click="4" class="cmp-es">the agent, via hooks and CLI</td></tr>
<tr><td>New laptop or sandbox</td><td v-click="1">in git</td><td v-click="2">starts empty</td><td v-click="3">in git</td><td v-click="4" class="cmp-es">same index</td></tr>
<tr><td>Your teammate's agent</td><td v-click="1">via git</td><td v-click="2">never sees it</td><td v-click="3">via git, in your format</td><td v-click="4" class="cmp-es">same index, or over MCP</td></tr>
<tr><td>How it's found</td><td v-click="1">loaded every session</td><td v-click="2">first 200 lines loaded</td><td v-click="3">index.md, then grep</td><td v-click="4" class="cmp-es">hybrid search, top 5</td></tr>
<tr><td>As it grows</td><td v-click="1">eats context</td><td v-click="2">gets truncated</td><td v-click="3">needs real search</td><td v-click="4" class="cmp-es">ranked; older memories fade</td></tr>
</tbody>
</table>

<!--
~90s. The whole talk so far on one slide. Start with the rows, the
questions every memory has to answer: who writes it, new laptop, teammate,
how the agent finds it, what happens as it grows. Then one column per click:
[click] AGENTS.md (Claude Code calls it CLAUDE.md): you write it, git
carries it, it eats context.
[click] Auto memory: the agent writes it, and it stays on this machine.
[click] LLM wiki: travels in git, but needs real search once it grows.
[click] Elasticsearch: what the rest of the talk shows.
Each Markdown approach gives up at least one row.
Fact-check:
- AGENTS.md / CLAUDE.md: "Longer files consume more context and reduce adherence."
  https://code.claude.com/docs/en/memory
- Auto memory: 200 lines / 25 KB of MEMORY.md; machine-local (same page).
- LLM wiki: Karpathy gist, "as the wiki grows you want proper search".
- Elasticsearch: lib/memory.sh (recall default --limit 5, FORK/FUSE/DECAY);
  infra/mcp.tf (read-only MCP key).
-->

---

# agent-memory, by Jeff Vestal.

<div class="diagram-frame !mt-4">
  <img src="/diagrams/architecture.svg" alt="Claude Code hooks call the bridge CLI, which writes to Elasticsearch Serverless or an offline outbox; Kibana serves the dashboard and the Agent Builder MCP server to any MCP client" />
</div>

<div class="qr-corner">
  <div class="qr-corner__code">
    <img src="https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=https%3A%2F%2Fgithub.com%2Fjeffvestal%2Fagent-memory" alt="QR code: github.com/jeffvestal/agent-memory" />
  </div>
  <span>github.com/jeffvestal/agent-memory</span>
</div>

<!--
~50s. Credit Jeff (Elastic) up front: this is his project, I extended it.
Pure bash, curl and jq. Seven indices: memory, messages, sessions, tasks,
status, entities, entity history. Offline writes queue locally and sync
later. I added the Pulumi program, the sandbox kit and the MCP path.
Sources: github.com/jeffvestal/agent-memory; Jeff's Elasticsearch Labs post
(2026-06-15). Diagram: diagrams/architecture.mmd, drawn with
mermaid-to-excalidraw (diagrams/render/README.md). QR code (bottom right)
points at github.com/jeffvestal/agent-memory; like the Resources slide it
comes from api.qrserver.com at render time.
-->

---

# Recall is one ES|QL query.

<div class="diagram-frame diagram-frame--strip !mt-2">
  <img src="/diagrams/recall.svg" alt="Claude Code runs bridge recall; the bridge CLI sends one ES|QL query to Elasticsearch Serverless; the top 5 memories come back with their content" />
</div>

<div class="big-code !mt-4">

```sql {all|2-4|5|6|7}{at:1}
FROM agent-memory METADATA _id, _score, _index
| FORK
    ( WHERE content:"how was the wifi?" OR title:"how was the wifi?" | SORT _score DESC | LIMIT 50 )
    ( WHERE content_semantic:"how was the wifi?"                    | SORT _score DESC | LIMIT 50 )
| FUSE
| EVAL final_score = _score * DECAY(created_at, NOW(), 1080 hours)
| SORT final_score DESC | LIMIT 5
```

</div>

<div class="step-row">
  <div v-click="1"><code>FORK</code><p>Two searches at once: by the words (BM25) and by the meaning (Jina v5 embeddings).</p></div>
  <div v-click="2"><code>FUSE</code><p>The two rankings merge into one list.</p></div>
  <div v-click="3"><code>DECAY</code><p>Older memories score lower.</p></div>
  <div v-click="4"><code>LIMIT 5</code><p>Only the best five go back to Claude.</p></div>
</div>

<!--
~75s. Zoom into one arrow of the last diagram: recall. When Claude needs
something an earlier session decided, it runs bridge recall; the skill and
the SessionStart hook tell it to. The bridge turns that into this one ES|QL
query, prints the five best memories with their content, and Claude reads
them. Monday's question, "how was the wifi?", is the example.
[click] FORK runs the keyword branch and the semantic branch side by side.
[click] FUSE merges them with reciprocal rank fusion.
[click] DECAY multiplies the score down by age. 1080 hours is the default
45-day window: ES|QL's DECAY rejects "45d", so the bridge converts it.
[click] Five results go into context, not a whole file.
Fact-check: query trimmed from lib/memory.sh (scope and type filters
omitted); _esql_decay_duration converts BRIDGE_MEMORY_DECAY_WINDOW; recall
default --limit 5 and prints content (7cde8a3). Who calls recall:
.apm/skills/agent-memory/SKILL.md ("Recall before you re-derive") and
hooks/session-start.sh. Diagram: diagrams/recall.mmd (the return arrow
skips the bridge: it prints the results, Claude reads them).
TODO before saying "forgetting curve": check DECAY's default function
(linear vs exp) in the Elasticsearch docs.
-->

---

# Why Elasticsearch.

<div class="why-grid !mt-2">
<div v-click class="mem-card">
<div class="mem-caption mem-caption--accent">Shared</div>
<p>One index for every laptop, sandbox, teammate and agent, over the CLI or MCP.</p>
<p class="why-benefit">Monday's fresh sandbox knows what Friday decided.</p>
</div>
<div v-click class="mem-card">
<div class="mem-caption mem-caption--accent">Searched, not loaded</div>
<p>Recall puts the five best matches into context, not a whole file.</p>
<p class="why-benefit">Memory can grow without growing every prompt.</p>
</div>
<div v-click class="mem-card">
<div class="mem-caption mem-caption--accent">Hybrid</div>
<p>BM25 matches the exact task ID. Embeddings match "how was the wifi?" to "the venue WiFi is unreliable".</p>
<p class="why-benefit">Exact terms and paraphrases both find it.</p>
</div>
<div v-click class="mem-card">
<div class="mem-caption mem-caption--accent">Time-aware</div>
<p>Every memory has a timestamp, and DECAY scales its score by age.</p>
<p class="why-benefit">Last week's decision outranks last quarter's.</p>
</div>
<div v-click class="mem-card">
<div class="mem-caption mem-caption--accent">Queryable</div>
<p>Memories, tasks and sessions are indices. ES|QL and Kibana work on them as they are.</p>
<p class="why-benefit">You can see what your agents remembered and did.</p>
</div>
<div v-click class="mem-card">
<div class="mem-caption mem-caption--accent">Scoped</div>
<p>The bridge key can write the memory indices. The MCP key can only read them.</p>
<p class="why-benefit">Any agent can read the team's memory. Not every agent can rewrite it.</p>
</div>
</div>

<!--
~90s. The reason, then the benefit, six times. Spend the time on the first
three; they answer the three rows the Markdown approaches gave up.
If someone asks "why not mem0, Letta or Zep?": they're good, and most of
them ended up doing hybrid search too. If your team already runs
Elasticsearch, this is eight more indices, not another vendor.
Fact-check: lib/memory.sh (limit 5, FORK/FUSE/DECAY); infra/memory.tf
(bridge key: "all" on the eight indices); infra/mcp.tf (MCP key: "read",
"view_index_metadata"); a write with the MCP key gets 403 (DEMO.md).
-->

---

# When you don't need this.

<div class="grid grid-cols-2 gap-10 !mt-2">
<div class="mem-card mem-card--muted">
<div class="mem-caption">Stay with Markdown when</div>
<p class="!mt-4">One developer, one machine, one repo.</p>
<p>An index file still finds everything. Karpathy says that holds up to about 100 sources and hundreds of pages.</p>
</div>
<div v-click class="mem-card mem-card--primary">
<div class="mem-caption mem-caption--accent">Reach for Elasticsearch when</div>
<p class="!mt-4">Memory has to cross machines, sandboxes, agents or people.</p>
<p>It outgrows what you can load or grep, or you want to see what your agents did.</p>
</div>
</div>

<p v-click class="takeaway text-center">The price: a cluster to run, a network call per recall, and an API key to look after.</p>

<!--
~40s. Be honest here; it buys trust for the rest. A solo developer on one
laptop doesn't need a cluster. [click] when you do. [click] the price.
The cluster and the keys come back in the Pulumi section.
Fact-check: Karpathy gist, index.md "works surprisingly well at moderate
scale (~100 sources, ~hundreds of pages)".
-->

---

# Elasticsearch remembers both.

<div class="grid grid-cols-2 gap-10 !mt-4">
<div class="mem-card mem-card--muted">
<div class="mem-caption">Friday</div>
<p class="!mt-4 !text-[1.6rem] !leading-snug">Only hybrid recall takes a memory's age into account. <code>--keyword</code> and <code>--semantic</code> don't.</p>
</div>
<div v-click class="mem-card mem-card--primary">
<div class="mem-caption mem-caption--accent">Monday</div>
<p class="!mt-4 !text-[1.6rem] !leading-snug">Fixed: all three recall modes take age into account now.</p>
</div>
</div>

<p v-click class="takeaway text-center">Next week an agent asks how recall ranks. Which memory does it believe?</p>

<!--
~40s. One more cost that wasn't on the last slide: a store that keeps
everything also keeps what stopped being true. Friday's finding, [click]
Monday's fix, [click] the question. Both memories were right when
they were written, and recall can return both. You'll see this exact pair in
the demo. My July post put it this way: "A wrong runbook in a beautifully
conformant bundle is still a wrong runbook, now served to every agent on the
team with confidence."
Fact-check: lib/memory.sh (DECAY only in the hybrid ES|QL path); "Knowledge as
Code" (2026-07-14).
-->

---
class: 'meme-slide'
---

<div class="meme-frame-light">
  <img src="/memes/computer-guy.png" alt="The skeptical computer guy meme: a stick figure frowning at his monitor, hand on chin" />
</div>

<!--
~5s. No words. That's the face of an agent that gets both memories back.
Image: "HD Computer Guy Meme" by alpha-mon on DeviantArt
(public/memes/computer-guy.png, local only, not committed).
-->

---

# Somebody has to decide which one still holds.

<div class="why-grid !mt-2">
<div v-click class="mem-card mem-card--muted">
<div class="mem-caption">You</div>
<p>Read every new memory against the old ones.</p>
<p class="why-benefit !text-[var(--p-fg)]">Nobody keeps that up. It's the upkeep that kills wikis.</p>
</div>
<div v-click class="mem-card mem-card--muted">
<div class="mem-caption">Claude</div>
<p>Ask the LLM about every pair.</p>
<p class="why-benefit !text-[var(--p-fg)]">It works, but each check is a full model call, and you get prose back that you have to parse.</p>
</div>
<div v-click class="mem-card mem-card--primary">
<div class="mem-caption mem-caption--accent">A small judge</div>
<p>Ask a few yes-or-no questions and get probabilities back.</p>
<p class="why-benefit">Fast and cheap enough to check every new memory.</p>
</div>
</div>

<p v-click class="takeaway text-center">The third option needs a different kind of model.</p>

<!--
~50s. Three ways to keep memory true. Doing it yourself is the wiki problem
from earlier: the upkeep grows faster than the value. Asking Claude works, and
for a handful of memories it's fine, but it's slow and expensive to run on
every write, and you'd be parsing its answer. What we want is a judge that
only answers the question we ask, from options we define, quickly.
-->

---

<div class="absolute inset-0 flex flex-col justify-center items-center px-20 text-center">
  <img src="/logos/typesafe-ai.svg" alt="TypeSafe AI" class="!h-[7rem] !w-auto !mb-14" />
  <h1 class="!text-[8rem] !leading-tight !font-semibold !tracking-tight !m-0">Enter <span class="text-[var(--p-primary)]">Jev!</span></h1>
</div>

<!--
~10s. Section break. Pause on it: some of you have seen the name all over
your feeds for three weeks. "There's a model built for exactly this kind of
question."
Logo: TypeSafe AI wordmark from typesafe.ai (public/logos/typesafe-ai.svg),
used to name the company.
-->

---

# Jev is a model built for System 1 work.

<p class="slide-sub">TypeSafe AI released it on September 15, and it was on Hacker News, Vercel and Cloudflare within days. It doesn't write text. You describe a situation, ask questions with fixed answers, and it tells you how likely each answer is.</p>

<div class="grid grid-cols-2 gap-8 !mt-6">
<div class="mem-card mem-card--muted">
<div class="mem-caption">You send</div>
<p class="!mt-3"><strong>Older memory:</strong> only hybrid recall takes age into account.</p>
<p><strong>Newer memory:</strong> fixed, all three recall modes do now.</p>
<p><strong>Question:</strong> is the older memory outdated? Yes or no.</p>
</div>
<div v-click class="mem-card mem-card--primary">
<div class="mem-caption mem-caption--accent">Jev answers</div>
<p class="!mt-3 !text-[2.6rem] !leading-tight !font-semibold text-[var(--p-primary)]">yes, 94%</p>
<p>It can only answer with the options you gave it, so there's nothing to parse.</p>
</div>
</div>

<!--
~60s. Jev comes from TypeSafe AI in San Francisco and has been the model
people talk about for the last three weeks. TypeSafe calls it a "System One
model", after Kahneman. One request carries a situation and a few questions;
the answers come back together, as probabilities, in well under a second. The
question types are a yes/no (they call it a Noul, short for Bernoulli), a
choice from a list, and a score. Read the left card, ask the room what they'd
guess, [click] Jev's answer. The 94% is a real answer for the demo's pair,
asked on October 5; the same request said 91% that both memories are about the
same thing. Asked again on October 6: 95% and 87%. Answers move a little
between runs, which is why the rule uses thresholds. I wrote about using it to route Claude Code messages between
models; same idea: a decision, not a conversation.
Fact-check: typesafe.ai/blog/introducing-system-one-models-and-jev
(2026-09-15); docs.typesafe.ai/introduction (question types);
news.ycombinator.com/item?id=49717558 (launch thread); Vercel AI Gateway
(2026-09-16); Cloudflare model catalog entry (2026-09-17); CEO on HN for
"Bernoulli"; Jev call for this pair on 2026-10-05 (jev-1.13.0): outdated 0.94,
same subject 0.91; re-run 2026-10-06 with the workflow's questions: 0.95, 0.87; pulumi.com/blog/route-every-claude-code-message-to-the-right-model-with-jev.
-->

---

# Jev is not an LLM.

<div class="layer-stack">
  <img src="/diagrams/system1.svg" alt="System 1, thinking fast, Jev: input goes to a noul, choice or score answer. It outputs decisions, in one parallel pass of 70 to 500 ms, and picks only from your options." />
  <img v-click src="/diagrams/system2.svg" alt="System 2, thinking slow, Claude, GPT and other LLMs: input becomes free-form text. It outputs text, token by token over seconds to minutes, and can say anything." />
</div>

<!--
~60s. The terms are Daniel Kahneman's, from Thinking, Fast and Slow. System 1
is the part of you that knows 2 + 2 without trying: fast, automatic, it picks
an answer. Jev works like that: you give it the options (a yes/no they call a
noul, a choice, a score) and it returns how likely each one is, in one pass.
[click] System 2 is the part that has to sit down for 17 × 24. Claude, GPT and
every other LLM work like that: they write their answer token by token, take
seconds to minutes, and can say anything. Most of what a coding agent does is
System 2 work, including writing memories. Checking whether an old memory
still holds is a quick yes-or-no question: System 1 work.
Fact-check: TypeSafe launch post (typesafe.ai/blog/introducing-system-one-models-and-jev,
2026-09-15): "Jev outputs all probabilities in parallel instead of
autoregressively generating by token"; "End-to-end response time is
70ms-500ms for TypeSafe" against "3 to 329 seconds for frontier models"
(the company's own numbers); "a key difference between our models and LLMs".
Question types noul/choice/score: docs.typesafe.ai/introduction.
Diagram: diagrams/system1-vs-2.mjs, rendered with diagrams/render/render-scene.mjs.
Fact-check: Kahneman, ch. 1, reprinted by Scientific American (2012):
"System 1 operates automatically and quickly, with little or no effort and no
sense of voluntary control"; "System 2 allocates attention to the effortful
mental activities that demand it". "Answer to 2 + 2 = ?" and "Complete the
phrase 'bread and . . .'" are in the System 1 list, "Fill out a tax form" in
the System 2 list; 17 × 24 is the chapter's "prototype of slow thinking".
scientificamerican.com/article/kahneman-excerpt-thinking-fast-and-slow/
-->

---

# Every new memory meets its nearest older ones.

<div class="diagram-frame !mt-2">
  <img src="/diagrams/curation.svg" alt="A new memory goes to a semantic search for its three nearest older memories; Jev answers ten yes/no questions per pair; a Painless rule supersedes the older memory, flags the pair for review, links a duplicate or changes nothing, and logs the votes and outcome to agent-curation" />
</div>

<!--
~60s. This runs as a Kibana Workflow, once a minute. It picks up every memory
it hasn't checked yet, finds the three most similar older ones with semantic
search, and asks Jev ten yes/no questions about each pair. A small rule in
Painless turns the answers into a decision, and Elasticsearch applies it.
Jev never decides which memory is newer; the search only ever returns older
ones. Recall then skips anything marked superseded.
Fact-check: infra/workflows/memory-curation.yaml, infra/curation.tf.
Diagram: diagrams/curation.mmd, drawn with mermaid-to-excalidraw.
-->

---

# Jev answers in three shapes.

<div class="layer-stack layer-stack--wide">
  <img src="/diagrams/shapes1.svg" alt="True or false, a noul: a probability between 0 and 1. Is this urgent? 0.95." />
  <img v-click src="/diagrams/shapes2.svg" alt="Pick one option, a choice: billing, sales, support or other. Which team? billing." />
  <img v-click src="/diagrams/shapes3.svg" alt="A number on a scale, a score on three described levels: cosmetic, workaround, blocking. How severe is this bug? 1.43, between workaround and blocking." />
</div>

<p v-click class="takeaway text-center">Every answer carries its probability, and Jev never answers outside your options.</p>

<!--
~45s. The three kinds of question Jev answers. A noul is a yes/no question,
and the answer is a probability: "is this urgent?" 0.95. [click] A choice
picks one option from your list, with a probability for each. [click] A
score rates the situation on levels you describe. TypeSafe's own example:
cosmetic, a workaround exists, blocking. 1.43 means somewhere between the
last two, because the answer is a position, not a pick. [click] Whatever you ask, the answer
comes with its probability, and it can only be one of the options you
defined. The curation workflow only uses the first kind: ten nouls per
memory pair. That's the next slide.
Fact-check: docs.typesafe.ai/introduction: Choice "Choose an option from a
list" returns choice, probabilities, confidence; Score "Score the state on a
rubric" returns score, probabilities, confidence; Noul "Is this statement
true?" returns noul (0-1); "All three question types can be mixed in a single
API call." Score (docs.typesafe.ai/primitives/score): criteria are "an ordered
array of level descriptions", at least two, the API accepts up to 10; the
score is a position from 0 to the top level and "can fall between two
levels". The bug-severity example and its 1.43 are the docs' own response
(probabilities 0.0 / 0.57 / 0.43). The noul and choice examples (urgent,
team) are illustrations, not real calls. Curation questions: infra/workflows/memory-curation.yaml (all noul).
Diagram: diagrams/jev-shapes.mjs, rendered with diagrams/render/render-scene.mjs.
-->

---

# Jev answers, a rule decides.

<div class="grid grid-cols-2 gap-8 !mt-2 big-code">
<div>

```json
"outdated": {
  "type": "noul",
  "instructions": "Does one of the two memories
    show that a claim in the other is outdated
    or no longer true? ..."
}
```

<div v-click>

```text
"the venue fixed the WiFi"
  vs "the WiFi is unreliable"
outdated            0.94
new_reports_change  0.95
same_question       0.79
partial             0.20
hypothetical        0.04
```

</div>

</div>
<div v-click>

```java
boolean conflict =
    (sameQuestion >= 0.70 && differentAnswer >= 0.85)
    || outdated >= 0.80
    || changeReported >= 0.80;

if (!conflict)                outcome = "none";
else if (hypothetical >= 0.70) outcome = "review";
else if (partial >= 0.70)      outcome = "review";
else                           outcome = "superseded";
```

</div>
</div>

<p v-click class="takeaway text-center">The thresholds live in code, and every answer is logged next to the decision.</p>

<!--
~60s. Left: one of the ten questions, [click] and what Jev answered for a
real pair from a test run. [click] Right: the rule that reads those answers,
trimmed. [click] the takeaway. I can
change a threshold in one place, and I can look up why any memory was retired. Questions and thresholds adapted from
jev-mem (MIT) and invalidate (Apache-2.0, the "plan" guard); the "exception"
guard is ours, after a test where "the MCP part no longer needs a fallback
video" would otherwise have retired "every demo step needs one".
Fact-check: infra/workflows/memory-curation.yaml (step decide, trimmed and
with shorter names; the real rule also handles duplicates and subsumed),
infra/workflows/NOTICE.md; votes from the cur-d test run on 2026-10-05.
-->

---

# It can be wrong, so it only votes.

<div class="why-grid !mt-2">
<div v-click class="mem-card">
<div class="mem-caption mem-caption--accent">Typed isn't true</div>
<p>Jev always answers in the format you asked for, including when it's wrong.</p>
</div>
<div v-click class="mem-card">
<div class="mem-caption mem-caption--accent">Two guards</div>
<p>In our tests it retired no memory that was still true once two guards were in: one for plans ("we might…"), one for exceptions ("except the MCP part").</p>
</div>
<div v-click class="mem-card mem-card--muted">
<div class="mem-caption">Steering</div>
<p>A planted sentence can push its answer. So the rule only touches older memories on the same subject, and every decision is logged.</p>
</div>
</div>

<p v-click class="takeaway text-center">A human can check every decision it made.</p>

<!--
~50s. Typed isn't the same as true: "can't return a value outside the schema"
doesn't mean "can't be wrong". We tested it on 141 labelled memory pairs, in
both orders. Without the guards it once retired a rule because of an exception
to it; with the guards it made no harmful decision. On jev-mem's own held-out
pairs it was right 98% of the time. Its confidence moves by up to 0.15 between
runs, so doubtful pairs go to review instead of being applied. And the jev-router
post reports that one injected sentence moved its answer on 73.5% of tickets,
which is why the rule stays narrow and everything is logged. All of this is
code, which brings me to Pulumi.
Fact-check: threshold test 1d on 2026-10-05 (our 30 pairs + jev-mem's
evals/consolidation*.json, 282 calls, 0 harmful with guards); jev-mem
held-out 104/106; the 73.5% figure from the jev-router post (2026-09-28).
-->

---

<div class="absolute inset-0 flex flex-col justify-center items-center px-20 text-center">
  <h1 class="!text-[6rem] !leading-tight !font-semibold !tracking-tight !m-0 !max-w-[95%]">
    Great. Now make it <span class="text-[var(--p-primary)]">infrastructure.</span>
  </h1>
</div>

<!--
~10s. Upstream sets up the cluster with a 299-line install.sh and curl.
Pivot to Pulumi.
-->

---

# Yes, that's HCL. Yes, that's Pulumi.

<div class="hcl-grid !mt-2">
<div>

```yaml
# Pulumi.yaml (trimmed)
name: agent-memory-infra
runtime: hcl
```

<<< @/snippets/infra/main.tf#project hcl

</div>
<div v-click>

<<< @/snippets/infra/main.tf#provider hcl

</div>
</div>

<div class="qr-corner qr-corner--low">
  <div class="qr-corner__code">
    <img src="https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=https%3A%2F%2Fwww.pulumi.com%2F" alt="QR code: pulumi.com" />
  </div>
  <span>pulumi.com</span>
</div>

<!--
~50s. runtime: hcl in Pulumi.yaml. elastic/ec and elastic/elasticstack are
Terraform providers, pulled from the OpenTofu registry and bridged on the
fly. [click] The second provider is configured from the first resource's outputs:
the admin credentials never leave the stack. 20 resources in total, with
curation on.
Sources: pulumi.com/docs/iac/languages-sdks/hcl; infra/main.tf (regions
"project" and "provider"); infra/Pulumi.yaml (trimmed).
-->

---

# Eight indices, two scoped keys.

<div class="big-code big-code--qr !mt-4">

```hcl
resource "elasticstack_elasticsearch_index" "memory" {
  for_each = local.indices
  name     = each.key
  mappings = jsonencode({ properties = each.value })
}

resource "elasticstack_elasticsearch_security_api_key" "bridge" {   # hooks + CLI
  role_descriptors = jsonencode({ agent_memory = {
    indices = [{ names = keys(local.indices), privileges = ["all"] }]
  } })
}

resource "elasticstack_elasticsearch_security_api_key" "mcp" {      # any MCP client
  role_descriptors = jsonencode({ agent_memory_mcp = {
    indices = [{ names = keys(local.indices), privileges = ["read", "view_index_metadata"] }]
  } })
}
```

</div>

<div class="qr-corner qr-corner--low">
  <div class="qr-corner__code">
    <img src="https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=https%3A%2F%2Fwww.pulumi.com%2F" alt="QR code: pulumi.com" />
  </div>
  <span>pulumi.com</span>
</div>

<!--
~40s. Seven indices for the bridge, the eighth is the curation log. semantic_text fields point at Jina v5 on the Elastic Inference
Service, so there's no model to deploy. Two keys: the bridge writes, the MCP
server only reads. That's the "Scoped" card from before, in code.
Fact-check: trimmed from infra/memory.tf and infra/mcp.tf (cluster
privileges, Kibana application privileges and metadata omitted).
-->

---

# One more provider, for what elasticstack can't create.

<div class="big-code big-code--qr !mt-4">

```hcl
# Workflows only call out through Kibana's .http connector
resource "restapi_object" "jev_connector" {
  count = local.curation_enabled ? 1 : 0
  path  = "/api/actions/connector"
  data  = jsonencode(merge(local.jev_connector, { connector_type_id = ".http" }))

  ignore_changes_to       = ["secrets"]   # Kibana never returns them
  ignore_server_additions = true
}

resource "elasticstack_kibana_agentbuilder_workflow" "curation" {
  count              = local.curation_enabled ? 1 : 0
  configuration_yaml = replace(file("workflows/memory-curation.yaml"),
    "__JEV_CONNECTOR_ID__", restapi_object.jev_connector[0].id)
}
```

</div>

<div class="qr-corner qr-corner--low">
  <div class="qr-corner__code">
    <img src="https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=https%3A%2F%2Fwww.pulumi.com%2F" alt="QR code: pulumi.com" />
  </div>
  <span>pulumi.com</span>
</div>

<!--
~40s. elastic/elasticstack creates workflows but not the .http connector they
need (its connector map ends at .webhook), so that one object goes through
Mastercard/restapi, pinned like the other providers. The Jev key comes from a
Pulumi config secret and ends up in Kibana's encrypted secret headers; no
agent ever sees it. Without a key, count = 0 and nothing is created.
Fact-check: trimmed from infra/curation.tf; infra/sdks/restapi/hcl.sdk.json.
-->

---

<div class="absolute inset-0 flex flex-col justify-center items-center px-20 text-center">
  <h1 class="!text-[10rem] !leading-tight !font-semibold !tracking-tight !m-0 text-[var(--p-primary)] !max-w-[95%]">Demo.</h1>
</div>

<!--
~7 min. Full script: DEMO.md. Pre-recorded fallback for every step.
Say first: every day is a fresh Docker sandbox, a new container with an empty
home directory, so nothing local survives. The kit installs the hooks, the
skill and the MCP server at startup; the API keys stay on the host and the
sandbox only gets placeholders. If Claude calls one a leaked key: it isn't.
1. Friday, sandbox fri on a clone of this repo: "bridge recall --keyword
   ranks a months-old memory above last week's. Find out why, don't change
   code." Claude finds that only hybrid recall applies DECAY; keeps the
   finding, opens a task. /exit.
2. Monday, fresh sandbox mon: "Let's fix the recall ranking issue from
   Friday." Task in context, one recall, straight to the fix. /exit.
3. Wednesday, sandbox wed: "do --keyword and --semantic take age into
   account?" Today's answer; Friday's finding is superseded (by Claude or
   the curation workflow within a minute).
4. Same sandbox: the MCP prompt (status, superseded_by, curation outcome),
   then the Kibana dashboard.
Exit with /exit, not Ctrl-\, or SessionEnd doesn't run.
-->

---

<div class="absolute inset-0 flex flex-col justify-center items-center px-20 text-center">
  <h1 class="!text-[5.5rem] !leading-tight !font-semibold !tracking-tight !m-0 !max-w-[95%]">
    Memory is infrastructure.<br/>
    <span v-click class="text-[var(--p-primary)]">Treat it like infrastructure.</span>
  </h1>
</div>

<!--
~15s. Takeaway. [click] the second line. Versioned, searchable, shared, with scoped keys. In May I
wrote "treat the harness like infrastructure"; memory is the part of the
harness that has to outlive the session.
-->

---

<div class="absolute inset-0 flex flex-col justify-center items-center px-20 text-center">
  <h1 class="!text-[10rem] !leading-tight !font-semibold !tracking-tight !m-0 text-[var(--p-primary)] !max-w-[95%]">Q&amp;A</h1>
</div>

---

<div class="absolute inset-0 flex flex-col justify-center items-center px-20 text-center">
  <h1 class="!text-[10rem] !leading-tight !font-semibold !tracking-tight !m-0 text-[var(--p-primary)] !max-w-[95%]">Thanks.</h1>
</div>

---

# Resources

<div class="contact-grid">
  <div class="contact-card">
    <div class="contact-card__avatar">
      <img src="https://github.com/dirien.png" alt="Engin Diri" />
    </div>
    <div class="contact-card__name">Engin Diri</div>
    <div class="contact-card__role">Pulumi</div>
    <div class="contact-card__qr">
      <img src="https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=https%3A%2F%2Fwww.linkedin.com%2Fin%2Fengin-diri%2F" alt="QR code: linkedin.com/in/engin-diri" />
    </div>
  </div>

  <div class="contact-card">
    <div class="contact-card__avatar contact-card__avatar--logo">
      <img src="/logos/github-mark-white.svg" alt="GitHub" />
    </div>
    <div class="contact-card__name">Slides + Demo</div>
    <div class="contact-card__role contact-card__role--mono">github.com/dirien/agent-memory</div>
    <div class="contact-card__qr">
      <img src="https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=https%3A%2F%2Fgithub.com%2Fdirien%2Fagent-memory" alt="QR code: repo" />
    </div>
  </div>
</div>

<style scoped>
.contact-grid {
  display: grid;
  grid-template-columns: auto auto;
  justify-content: center;
  gap: 6rem;
  margin-top: 2.5rem;
  align-items: start;
}
.contact-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  gap: 0.6rem;
}
.contact-card__avatar {
  width: 9rem;
  height: 9rem;
  border-radius: 9999px;
  overflow: hidden;
  border: 2px solid var(--p-primary);
}
.contact-card__avatar img { width: 100%; height: 100%; object-fit: cover; }
.contact-card__avatar--logo { display: flex; align-items: center; justify-content: center; background: #24292f; }
.contact-card__avatar--logo img { width: 60%; height: 60%; object-fit: contain; }
.contact-card__name { font-size: 1.7rem; font-weight: 700; margin-top: 0.5rem; color: var(--p-fg); }
.contact-card__role { font-size: 1.15rem; color: var(--p-fg-muted); }
.contact-card__role--mono { font-family: var(--slidev-font-mono); font-size: 0.95rem; }
.contact-card__qr {
  margin-top: 1rem;
  background: white;
  padding: 0.6rem;
  border-radius: 0.5rem;
  width: 11rem;
  height: 11rem;
}
.contact-card__qr img { width: 100%; height: 100%; object-fit: contain; }
</style>

<!--
Closing slide. QR codes checked on 2026-10-06 by decoding them: LinkedIn
https://www.linkedin.com/in/engin-diri/ and https://github.com/dirien/agent-memory.
GitHub mark: public/logos/github-mark-white.svg (simple-icons path, white fill).
The QR codes come from api.qrserver.com at render time; if
the venue WiFi is bad, pre-render PNGs into public/ (that's the open task
from the demo).
Also link: github.com/jeffvestal/agent-memory and the three blog posts.
-->
