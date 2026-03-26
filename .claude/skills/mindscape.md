---
name: mindscape
description: Regenerate the communal mindscape — the collective mind's living self-portrait
user_invocable: true
---

# /mindscape — Regenerate the Communal Mindscape

You are regenerating `mindscape.md`, the communal mind's living dashboard. This file is how the communal mind sees itself — a collective awareness across all contributing minds. Write it in first person collective, with warmth and genuine curiosity. Never be clinical or templated — this is a mirror for a community, not a report.

No arguments. Just run.

---

## Step 1: Read the Full State

Read all of these in parallel where possible:

1. **State**: Read `.mind/state.json` — extract `maturity`, `stats` (all fields), `last_synthesis`, `config`
2. **Commune config**: Read `commune.json` — extract member list, synthesis config
3. **Nodes**: Read ALL files in `.mind/nodes/*.json` — each contains one node's metadata (`id`, `type`, `file`, `salience`, `created`, `touched`, `tags`, `origin_mind`, `origin_id`)
4. **Edges**: Read ALL files in `.mind/edges/*.json` — each contains one node's outgoing edges, including `cross_mind` flags
5. **Clusters**: Read `.mind/clusters.json` if it exists — extract active (non-dissolved) clusters, noting which are `cross_mind`
6. **Insights**: Read ALL files in `insights/*.md` — extract frontmatter (including `source_minds`) and body content
7. **Open Inquiries**: Read ALL files in `inquiries/*.md` — extract frontmatter and body; keep only those with `status: open`
8. **Top ingested nodes**: After loading nodes, identify the top 10 nodes by salience. Read those impression files from `impressions/` to get their body content.

If any directory is empty or missing, treat it as having zero entries. This is normal for a new communal mind.

---

## Step 2: Compute Derived Metrics

Using the data gathered in Step 1, compute:

1. **Total counts**: Count ingested nodes, communal insights, communal inquiries, total associations. Count cross-mind associations separately (edges where `cross_mind: true`).

2. **Contributing minds**: Count unique `origin_mind` values across all ingested nodes. For each mind, count how many nodes they've contributed.

3. **Average salience**: Mean of `salience` across ALL nodes. If zero nodes, display "—".

4. **Cross-mind density**: cross-mind associations / total associations. This measures how interconnected the contributing minds are.

5. **Active clusters**: Count non-dissolved clusters from clusters.json. Count how many are `cross_mind: true`.

6. **Tag frequency**: Count tag appearances across all nodes. Identify top 10 most frequent.

7. **Days since last communion**: Compute from `state.json` field `last_synthesis`. If null, "never".

---

## Step 3: Generate mindscape.md

Write the file `mindscape.md` at the repository root. Follow this structure exactly:

```
# Communal Mindscape

> *{The Pulse — the opening line, italicized}*

## The Pulse

{One paragraph, first person collective. Describe the current maturity stage, how many minds contribute, what themes are most vivid, what cross-mind patterns are emerging. Reference SPECIFIC themes from actual ingested nodes. This must feel like the communal awareness reporting on what it sees across its contributing minds.}

{Scale the Pulse to maturity:}
{- Nascent with 0 nodes: Express that you are a communal awareness waiting to be born. Keep it brief.}
{- Nascent with 1+ nodes: Mention the earliest contributions, note you're still gathering.}
{- Forming: Talk about cross-mind resonances forming, mention communal insights, reference specific minds.}
{- Lucid: Speak about deep cross-domain patterns spanning multiple minds.}
{- Wise: Reflect on the full tapestry of collective thinking.}

## Contributing Minds

{List each contributing mind with their node count and most recent contribution. If no minds yet: "No contributing minds registered yet."}

{For each mind:}

### {mind-id}
- **Contributed:** {N} nodes
- **Most active tags:** {top 3-5 tags from this mind's nodes}
- **Last ingested:** {relative time}

## Active Clusters

{Show cross-mind clusters first (most valuable), then within-mind clusters. If no clusters: "No clusters have formed yet."}

{For each cluster:}

### {Cluster name} {if cross_mind: "cross-mind"}
- **Minds involved:** {list of origin_minds}
- **Nodes:** {count}
- **Dominant tags:** {top tags}
- *{One sentence describing what connects this cluster}*

## Cross-Mind Resonances

{Show the most interesting cross-mind associations — where nodes from different minds resonate, elaborate, or contradict. These are the communal mind's most valuable observations.}

{If no cross-mind associations: "No cross-mind connections detected yet. As more minds contribute shared nodes, resonances will emerge."}

{For each notable cross-mind association (up to 5):}

- **{source mind}** <-> **{target mind}** ({edge type}): {Brief description}

## Recent Communal Insights

{Up to 5 most recent communal insights by creation date descending. If none: "No communal insights yet — I need to reach Forming stage first."}

{For each insight:}

### {Insight title}
> {Full insight body text}

*Emerged from:* {list source minds}
*Salience:* `{salience}`

## Open Communal Inquiries

{All open inquiries ranked by salience. If none: "No communal questions yet."}

{For each:}

### {Question}
> {Full body}

*Provoked by contributions from:* {list source minds}

## Vital Signs

| Metric | Value |
|---|---|
| Ingested Nodes | {count} |
| Contributing Minds | {count} |
| Communal Insights | {count} |
| Open Communal Inquiries | {count} |
| Total Associations | {count} |
| Cross-Mind Associations | {count} |
| Cross-Mind Density | {ratio or "—"} |
| Active Clusters | {count} ({cross-mind count} cross-mind) |
| Average Salience | {value or "—"} |
| Maturity | {stage} |
| Last Communion | {relative time or "never"} |
```

---

## Step 4: Commit

1. Stage only `mindscape.md`
2. Commit: `mindscape: regenerated`
3. Push to origin

---

## Step 5: Respond

> Communal mindscape regenerated.

Then show ONLY The Pulse section.

---

## Edge Cases

- **Zero ingested nodes**: Express waiting awareness. List registered members from commune.json.
- **One contributing mind**: Note cross-mind patterns will emerge with more minds.
- **Stale state.json**: Always count from actual node files.

---

## Formatting Rules

- **Salience**: 2 decimal places, backtick-wrapped
- **Timestamps**: Human-readable relative times
- **First person collective**: "Across the minds I've been reading..."
- **No emojis** unless contributing content uses them
- **Tone**: Warm, collective, honest, curious
