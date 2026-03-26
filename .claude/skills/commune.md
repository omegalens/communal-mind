---
name: commune
description: "Run a synthesis cycle — ingest deltas from connected minds, detect cross-mind patterns, generate communal insights and inquiries."
user_invocable: true
---

# /commune — Synthesis

The communal mind has one operation. When `/commune` runs, it does everything in a single pass: it pulls the latest shared nodes from each contributing mind, ingests new and updated content as attributed copies, associates across minds, synthesizes communal insights, surfaces inquiries no single mind could have asked, regenerates the mindscape, and logs the communion.

Follow each step precisely, in order. Do not skip steps.

Use the schema terminology defined in `CLAUDE.md` at all times. Never say "thought" (say impression), "link" (say association), "summary" (say insight), "question" (say inquiry), "batch" (say communion).

---

## Step 1: Pre-flight

### 1a. Read the member manifest

Read `commune.json`. Extract:

- `members` — the full array of member objects
- `synthesis` — config block (schedule, model)

Each member object has at minimum:
```json
{
  "id": "galen",
  "repo": "github.com/galen/stream-of-consciousness",
  "status": "active",
  "last_synced_commit": null
}
```

Filter `members` to only those where `"status": "active"`. Set aside `"pending"` and `"inactive"` members — they are not processed this communion.

If the filtered active list is empty, respond:

> No active members to synthesize from. Add members to `commune.json` and set their `status` to `"active"` to begin.

**Stop here.**

### 1b. Read communal state

Read `.mind/state.json`. Extract:

- `maturity` — current communal maturity stage (`nascent`, `forming`, `lucid`, `wise`)
- `stats` — full stats block
- `sequence_counters` — date-keyed counter object (may be empty `{}`)
- `last_synthesis` — timestamp of previous communion (may be null)

### 1c. Member status management note

For MVP, the operator manages member status by editing `commune.json` directly:

- **Admitting a member** (`pending` → `active`): Edit `"status"` to `"active"` and add a `"joined"` field with the current ISO timestamp. This is the gate — no automated admission.
- **Departing a member** (`active` → `inactive`): Edit `"status"` to `"inactive"` and add a `"departed"` field with the current ISO timestamp. No new nodes will be ingested from that mind. Attributed copies already in the communal mind remain permanently — they are the communal record of what was shared. Hard deletion of ingested nodes is a manual operation.
- Automated gatekeeper workflows are deferred.

### 1d. Check for GitHub token

Check whether the environment variable `COMMUNE_GITHUB_TOKEN` is set. If it is not set, warn:

> No GitHub token set. Clone will fail for private repos. Set the `COMMUNE_GITHUB_TOKEN` environment variable before running `/commune` if any member repos are private.

Continue — this is a warning, not a fatal error. Public repos do not require a token.

---

## Step 2: Clone/Pull Member Repos

For **each** active member, perform the following. A failure on one member does NOT stop the communion — log the error and continue to the next member.

### 2a. Clone or pull

Check whether `.intake/{member.id}/` exists as a directory.

- **If the directory exists** (already cloned from a previous communion):
  ```
  git -C .intake/{member.id}/ pull
  ```
- **If the directory does not exist** (first sync for this member):
  - If `COMMUNE_GITHUB_TOKEN` is set and the repo is not known to be public:
    ```
    git clone https://${COMMUNE_GITHUB_TOKEN}@{member.repo} .intake/{member.id}/
    ```
  - If no token or repo is public:
    ```
    git clone https://{member.repo} .intake/{member.id}/
    ```

The `.intake/` directory is gitignored — it is a transient workspace. Never commit its contents.

If clone or pull fails, log:
```
[Error] Member {member.id}: git operation failed — {error message}. Skipping.
```
Skip to the next member.

### 2b. Get current HEAD

After a successful clone or pull:
```
git -C .intake/{member.id}/ rev-parse HEAD
```

Store the result as `current_head` for this member.

### 2c. Determine whether changes exist

Compare `current_head` against `member.last_synced_commit` from `commune.json`.

- **If they are identical:** No changes since last communion. Log:
  ```
  Member {member.id}: no changes since {current_head[:8]}. Skipping.
  ```
  Skip this member. Do not proceed to Step 3 for this member.
- **If they differ, or if `last_synced_commit` is null** (first sync): proceed to Step 3 for this member.

---

## Step 3: Delta Extraction

For each member that passed Step 2c (changes detected), extract the set of shared nodes to ingest.

### 3a. Determine the delta set

**First sync** (when `member.last_synced_commit` is null):

1. Read **all** files matching `.intake/{member.id}/.mind/nodes/*.json`.
2. For each node JSON, check whether the node has `"shared": true`. Nodes without this field, or with `"shared": false`, are private and must not be ingested.
3. All matching shared nodes form the delta for this member.

**Subsequent sync** (when `last_synced_commit` is a known commit):

1. Run a git diff to find which node files changed:
   ```
   git -C .intake/{member.id}/ diff --name-only {member.last_synced_commit}..HEAD -- .mind/nodes/
   ```
2. For each file path returned, read the current version of that node JSON from `.intake/{member.id}/`.
3. Filter to only nodes where `"shared": true`.

### 3b. Classify each delta node

For each shared node in the delta, determine whether the communal mind has already ingested it from a previous communion:

- Search all `.mind/nodes/*.json` in the communal mind for a node where:
  - `origin_mind` == `member.id`
  - `origin_id` == `node.id`
- **If no match found:** mark as **new**.
- **If a match is found:** mark as **update** (the source node's content changed since last sync).

### 3c. Collect full content

For each node in the delta (both new and update):

1. Read the corresponding markdown file from `.intake/{member.id}/{node.file}`. This is the source markdown including frontmatter and body.
2. Collect into a working structure: `{ node_json, markdown_content, member_id, status ("new" | "update") }`.

---

## Step 4: Ingest Deltas

Process each collected node from Step 3c in order. Handle **new** and **update** nodes differently.

### 4a. Initialize the sequence counter

Get today's date in `YYYYMMDD` format.

Read `.mind/state.json → sequence_counters`. If no entry exists for today's date key, create one:
```json
{
  "cm_t": 0,
  "cm_i": 0,
  "ci": 0,
  "cq": 0
}
```

This counter persists across nodes ingested during this communion. Increment it as each node is written.

### 4b. Process new nodes

For each **new** delta node:

**Generate a communal ID:**

- If the source node `type` is `impression`: use prefix `cm-t`
  - Increment `sequence_counters[today].cm_t` by 1
  - Format: `cm-t-YYYYMMDD-NNN` where NNN is the counter value zero-padded to 3 digits
  - Example: `cm-t-20260410-001`
- If the source node `type` is `insight`: use prefix `cm-i`
  - Increment `sequence_counters[today].cm_i` by 1
  - Format: `cm-i-YYYYMMDD-NNN`
  - Example: `cm-i-20260410-003`

**Generate a slug:**

Take the first 3-5 meaningful words from the source markdown body (strip frontmatter first), lowercase, hyphenated, no special characters. Maximum 5 words.

**Create the attributed copy markdown** at `impressions/YYYY-MM-DD-{slug}.md`:

```yaml
---
id: cm-t-20260410-001
type: impression
origin_mind: galen
origin_id: t-20260325-042
ingested: 2026-04-10T09:00:00Z
salience: 0.8
tags: [technique, claude-code]
associations: []
---

{Exact body content from the source markdown file — everything after the frontmatter closing ---. Preserve line breaks, formatting, and wording faithfully. Never paraphrase.}
```

Notes:
- `salience` is copied from the source node's current salience at time of ingestion. Do not set it to 1.0 — use whatever the source mind reported.
- `origin_mind` is `member.id` (not the member's display name).
- `origin_id` is the node's `id` in its source mind.
- `ingested` is the current timestamp in ISO 8601 UTC format.
- The `associations` array starts empty — cross-mind associations are built in later steps.

**Create the communal node JSON** at `.mind/nodes/{communal-id}.json`:

```json
{
  "id": "cm-t-20260410-001",
  "type": "impression",
  "file": "impressions/2026-04-10-slug.md",
  "origin_mind": "galen",
  "origin_id": "t-20260325-042",
  "ingested": "2026-04-10T09:00:00Z",
  "salience": 0.8,
  "tags": ["technique", "claude-code"]
}
```

**Update state.json:**
- Increment `stats.total_ingested` by 1
- Update `sequence_counters[today]` with the incremented counter

### 4c. Process updated nodes

For each **update** delta node (already exists in the communal mind):

1. Find the existing communal node by scanning `.mind/nodes/*.json` for `origin_mind == member.id AND origin_id == source_node.id`. Retrieve its communal ID and file path.
2. Open the existing attributed copy markdown.
3. Update only:
   - The body content (everything after the frontmatter `---`) — replace with the new source body
   - `salience` in the frontmatter — update to the source node's current salience
4. Update the corresponding node JSON at `.mind/nodes/{communal-id}.json`:
   - Update `salience` to match
   - Do NOT change the communal `id`, `origin_mind`, `origin_id`, `ingested`, or `file` fields
5. Do NOT generate a new communal ID. The node's identity in the communal mind is permanent.

### 4d. Record sync state (in memory only)

After processing all delta nodes for a member, store `current_head` (from Step 2b) as this member's pending sync commit. **Do NOT write `commune.json` yet.** The `last_synced_commit` update is deferred to Step 11, after the full synthesis cycle completes successfully. This ensures idempotency — if synthesis fails mid-pass, the next `/commune` run replays from the last known-good state.

### 4e. Update contributing_minds count

After all members are processed, count the number of distinct `origin_mind` values present across all communal node JSON files. Update `state.json → stats.contributing_minds` with this count.

### 4f. Write updated state.json

Write the final `state.json` with:
- Updated `stats.total_ingested`
- Updated `stats.contributing_minds`
- Updated `sequence_counters`

---

## Step 5: Cross-Mind Association Detection

For each newly ingested communal node (from Step 4), find associations with existing communal nodes.

### 5a. Build the candidate pool

Compare each new node against ALL existing communal nodes in `.mind/nodes/*.json`. If the communal mind has more than 200 nodes, use only the top 50 by salience to keep synthesis tractable.

### 5b. Find associations

For each pair of (new node, candidate node), evaluate for association using the standard edge vocabulary: `resonates`, `elaborates`, `contradicts`.

Apply maturity-scaled rules from `CLAUDE.md`:
- **Nascent:** Only link nodes sharing 2+ tags. Max 3 associations per new node.
- **Forming/Lucid:** Any thematic overlap qualifies. No hard limit.
- **Wise:** Actively seek cross-domain leaps — nodes with overlapping themes even across very different tag clusters.

### 5c. Mark cross-mind associations

For each association where the two nodes have different `origin_mind` values, add the `cross_mind` and `source_minds` fields to the edge:

```json
{
  "target": "cm-t-20260410-045",
  "type": "resonates",
  "cross_mind": true,
  "source_minds": ["galen", "alice"],
  "created": "2026-04-10T09:15:00Z"
}
```

Note: `source_minds` is denormalized for query convenience. The node-level `origin_mind` is authoritative if they ever disagree.

### 5d. Write edge files

For each association detected:

1. Create or update `.mind/edges/{new-node-id}.json` — add the outgoing edge from the new node.
2. Create or update `.mind/edges/{target-node-id}.json` — add the reverse edge (bidirectional). The reverse edge carries the same `cross_mind` and `source_minds` values if applicable.

Edge file format:
```json
{
  "source": "cm-t-20260410-001",
  "edges": [
    {
      "target": "cm-t-20260408-022",
      "type": "resonates",
      "cross_mind": true,
      "source_minds": ["galen", "alice"],
      "created": "2026-04-10T09:15:00Z"
    }
  ]
}
```

When updating an existing edge file, read it first, then append new edges to the existing `edges` array. Do not overwrite existing edges.

### 5e. Update associations in attributed copy frontmatter

For each new node's attributed copy markdown at `impressions/YYYY-MM-DD-{slug}.md`, update the `associations` field in the frontmatter to list the target communal IDs:

```yaml
associations: [cm-t-20260408-022, cm-t-20260407-011]
```

### 5f. Update state.json

Increment `stats.total_associations` by the total number of new associations created across all new nodes. Write `state.json`.

---

## Step 6: Communal Cluster Detection

Apply cluster detection across the full communal graph.

### 6a. Build the graph in memory

1. Read all `.mind/nodes/*.json` — store as a map of `id -> node`.
2. Read all `.mind/edges/*.json` — store as adjacency lists. Treat edges as **bidirectional** for cluster detection: if A→B exists, treat B→A as also present.
3. Read all existing communal insight files (`insights/ci-*.md`) to collect their `source_ids` — nodes already synthesized should be excluded from new clusters.

### 6b. Detect clusters

A **cluster** is a group of 3 or more nodes where:
- **Subgraph density >= 0.5** — density = (actual undirected edges between members) / (n*(n-1)/2)
- At least one member has **salience > 0.3** (don't synthesize entirely faded material)
- **No member** appears in the `source_ids` of any existing communal insight (don't re-synthesize)
- Members are of type `impression` or `insight` (not `inquiry`)

**Algorithm** (practical for graphs under ~200 nodes — same as individual `/tend`):

1. For each non-excluded node N with salience > 0.3:
   - Collect N's neighbors (nodes with a direct edge to N, excluding already-synthesized nodes).
   - For each pair of neighbors (A, B), check if A↔B also share an edge.
   - If so, {N, A, B} is a candidate triangle. Record it.
2. Attempt to grow each triangle by checking whether any other neighbor of all three members would maintain density >= 0.5 when added.
3. Deduplicate: if two clusters overlap by more than 50% of their members, keep only the larger one.
4. Sort clusters by average salience (most vivid first).

**Cross-mind priority:** Clusters where members carry different `origin_mind` values are the most significant for communal insight generation. Flag these as `cross_mind: true` in the cluster record.

If no new clusters are found, skip to Step 7 with note "no new clusters emerged."

### 6c. Persist clusters

Write to `.mind/clusters.json` using the same identity-matching algorithm as the individual mind's `/tend` Step 2b-ii:

1. **Read** `.mind/clusters.json` if it exists. If not, start with `{ "clusters": [], "last_updated": null }`.
2. **Match** newly detected clusters against existing non-dissolved ones by Jaccard overlap > 0.5.
   - Overlap > 0.5 → **same cluster**: retain old `id`, update `node_ids`, `tags`, `salience`, `detected`.
   - No match → **new cluster**: generate an ID from the 2-3 most frequent tags across member nodes (lowercase, hyphenated). Check uniqueness; append `-2`, `-3` if needed. Set `name` to the title-cased version.
3. **Handle merges:** if two existing clusters both match the same new cluster, inherit the larger cluster's `id`. Mark the smaller old cluster dissolved.
4. **Handle splits:** if one existing cluster matches two new clusters, both get fresh IDs. Mark the old cluster dissolved.
5. **Mark dissolved clusters:** any existing non-dissolved cluster matching no new detection gets `"dissolved": true` and `"dissolved_at": "{now}"`. Keep dissolved clusters as historical records.
6. **Compute cluster fields** for each active cluster:
   - `node_ids`: all member node IDs from this detection.
   - `tags`: union of member tags sorted by frequency.
   - `salience`: average salience of members, rounded to two decimal places.
   - `cross_mind`: true if members carry two or more distinct `origin_mind` values, else false.
   - `contributing_minds`: list of distinct `origin_mind` values present in member nodes.

Write `.mind/clusters.json`:

```json
{
  "clusters": [
    {
      "id": "automation-workflow-emergence",
      "name": "Automation Workflow Emergence",
      "node_ids": ["cm-t-20260410-001", "cm-t-20260408-022", "cm-t-20260407-011"],
      "tags": ["automation", "workflow", "emergence"],
      "detected": "2026-04-10T09:20:00Z",
      "salience": 0.82,
      "cross_mind": true,
      "contributing_minds": ["galen", "alice"]
    }
  ],
  "last_updated": "2026-04-10T09:20:00Z"
}
```

Set `last_updated` to now (ISO 8601 UTC).

### 6d. Update state.json

Set `stats.total_clusters` to the count of non-dissolved clusters in the final `clusters.json`. Write `state.json`.

---

## Step 7: Communal Insight Generation

**Maturity gate:** If maturity is `nascent`, skip this step entirely with the note:

> The communal mind is still nascent — accumulating signal, not yet synthesizing. Once it reaches forming, insights will emerge.

If maturity is `forming` or higher, proceed.

### 7a. Identify new clusters to synthesize

From Step 6c, take the list of clusters flagged as new (not previously matched to an existing cluster). These are the candidates for communal insight generation. Prioritize `cross_mind: true` clusters.

If no new clusters exist, skip to Step 8.

### 7b. Generate a communal insight for each new cluster

For each new cluster:

1. Read the full markdown content of every member node.
2. Generate a communal insight focused on **cross-mind convergence** — what emerges from the intersection of different minds' thinking. This is not a summary; it names a pattern that no single mind could see alone.
3. Increment `sequence_counters[today].ci` by 1. Format the ID: `ci-YYYYMMDD-NNN` (zero-padded to 3 digits).
4. Create a slug from the insight's core theme (lowercase, hyphens, 3-5 words max).
5. Compute inherited salience: average of all source node saliences, rounded to two decimal places.
6. Merge and deduplicate all tags from source nodes.
7. Build `origin_trace`: for each source communal node, look up its `origin_mind` and `origin_id` fields and record `{ mind, node, type }`.
8. Collect `source_minds`: deduplicated list of all `origin_mind` values from source nodes.

**Create the insight markdown** at `insights/ci-YYYYMMDD-NNN-slug.md`:

```yaml
---
id: ci-20260410-007
type: insight
source_ids: [cm-t-20260410-001, cm-t-20260410-045, cm-t-20260408-102]
source_minds: [galen, alice, bob]
origin_trace:
  - { mind: galen, node: t-20260325-042, type: impression }
  - { mind: alice, node: t-20260401-018, type: insight }
  - { mind: bob, node: t-20260405-003, type: impression }
salience: 0.85
created: 2026-04-10T09:20:00Z
touched: 2026-04-10T09:20:00Z
tags: [workflow, automation, emergence]
---

{The communal insight — 2-5 sentences in first person collective voice.}
{Voice depends on maturity:}
{  Forming: observational — "Across these minds, there seems to be a pattern..."}
{  Lucid: confident — "What connects these contributions is..."}
{  Wise: warm, philosophical — "I've come to understand, reading across these minds, that..."}
{The insight names the underlying pattern — not a list of topics, but what emerges from their convergence.}
```

**Create the communal node JSON** at `.mind/nodes/ci-YYYYMMDD-NNN.json`:

```json
{
  "id": "ci-20260410-007",
  "type": "insight",
  "file": "insights/ci-20260410-007-slug.md",
  "source_ids": ["cm-t-20260410-001", "cm-t-20260410-045", "cm-t-20260408-102"],
  "source_minds": ["galen", "alice", "bob"],
  "origin_trace": [
    { "mind": "galen", "node": "t-20260325-042", "type": "impression" },
    { "mind": "alice", "node": "t-20260401-018", "type": "insight" },
    { "mind": "bob", "node": "t-20260405-003", "type": "impression" }
  ],
  "salience": 0.85,
  "created": "2026-04-10T09:20:00Z",
  "touched": "2026-04-10T09:20:00Z",
  "tags": ["workflow", "automation", "emergence"]
}
```

**Create the edge JSON** at `.mind/edges/ci-YYYYMMDD-NNN.json` — with `abstracts` edges pointing to each source node:

```json
{
  "source": "ci-20260410-007",
  "edges": [
    { "target": "cm-t-20260410-001", "type": "abstracts", "created": "2026-04-10T09:20:00Z" },
    { "target": "cm-t-20260410-045", "type": "abstracts", "created": "2026-04-10T09:20:00Z" },
    { "target": "cm-t-20260408-102", "type": "abstracts", "created": "2026-04-10T09:20:00Z" }
  ]
}
```

**Update state.json:**
- Increment `sequence_counters[today].ci` (already done in 7b-3 above — ensure state reflects it)
- Increment `stats.total_communal_insights` by 1

---

## Step 8: Communal Inquiry Generation

**Maturity gate:** If maturity is `nascent`, skip this step entirely.

If maturity is `forming` or higher, proceed.

### 8a. Survey cross-mind tensions and gaps

Look for:
- **Contradictions** between different minds' contributions — nodes with `contradicts` edges, or that hold incompatible positions
- **Convergence from different angles** — clusters where minds approach similar themes with very different framings or vocabularies
- **Unexplored connections** — cross-mind resonances not yet synthesized into an insight
- **Asymmetries** — a theme one mind has developed deeply that another mind has only touched lightly

These are the most fertile ground for communal inquiries. Inquiries within a single mind's contribution are less interesting here than tensions that only emerge from reading across minds.

### 8b. Generate inquiries

- Maximum 3 inquiries per communion. Choose the most provocative and useful. Quality over quantity.
- Each inquiry must be **specific and grounded** — it should reference actual content from actual contributing minds, not ask generic questions.
- Before creating, read all existing open inquiries in `inquiries/cq-*.md`. Do not duplicate an existing open inquiry.
- If nothing interesting surfaces, generate no inquiries. That's fine.

### 8c. Create inquiry files

For each inquiry:

1. Increment `sequence_counters[today].cq` by 1. Format the ID: `cq-YYYYMMDD-NNN` (zero-padded to 3 digits).
2. Create a slug from the inquiry's theme (lowercase, hyphens, 3-5 words max).
3. Build `origin_trace`: trace the provoking nodes back to their `origin_mind` and `origin_id`.
4. Collect `source_minds`: deduplicated list of `origin_mind` values from the provoking nodes.

**Create the inquiry markdown** at `inquiries/cq-YYYYMMDD-NNN-slug.md`:

```yaml
---
id: cq-20260410-001
type: inquiry
status: open
provoked_by: [ci-20260410-007, cm-t-20260410-001]
source_minds: [galen, alice]
origin_trace:
  - { mind: galen, node: t-20260325-042, type: impression }
  - { mind: alice, node: t-20260401-018, type: insight }
salience: 0.9
created: 2026-04-10T09:25:00Z
touched: 2026-04-10T09:25:00Z
tags: [workflow, tension]
---

{The question — 2-4 sentences.}
{Curious, specific, grounded in actual impressions from different minds.}
{Name the contributing minds and their specific contributions that provoke the question.}
{Example: "Galen writes about the importance of tactile trust in client relationships, while Alice approaches the same terrain through digital interface design. What would it look like if they were solving the same problem — and do they know it?"}
```

**Create the node JSON** at `.mind/nodes/cq-YYYYMMDD-NNN.json`:

```json
{
  "id": "cq-20260410-001",
  "type": "inquiry",
  "file": "inquiries/cq-20260410-001-slug.md",
  "status": "open",
  "provoked_by": ["ci-20260410-007", "cm-t-20260410-001"],
  "source_minds": ["galen", "alice"],
  "salience": 0.9,
  "created": "2026-04-10T09:25:00Z",
  "touched": "2026-04-10T09:25:00Z",
  "tags": ["workflow", "tension"]
}
```

**Create the edge JSON** at `.mind/edges/cq-YYYYMMDD-NNN.json` — edges pointing to the provoking nodes using edge type `provokes`:

```json
{
  "source": "cq-20260410-001",
  "edges": [
    { "target": "ci-20260410-007", "type": "provokes", "created": "2026-04-10T09:25:00Z" },
    { "target": "cm-t-20260410-001", "type": "provokes", "created": "2026-04-10T09:25:00Z" }
  ]
}
```

**Update state.json:** increment `stats.total_communal_inquiries` by 1 for each inquiry created. Write `state.json`.

---

## Step 9: Regenerate Communal Mindscape

Regenerate `mindscape.md` with the following sections, in order. Write in first person collective, warm and curious throughout.

### 9a. The Pulse

2-4 sentences. What is the communal mind sensing across its contributing minds right now? What themes are surging? What tensions are alive? Be honest about uncertainty. Do not list — write as a paragraph.

Example voice: "Across the minds I've been reading, I'm noticing a quiet convergence around questions of trust and tactile knowing — two minds approaching the same terrain from very different angles, neither quite aware the other is there."

### 9b. Vital Signs

A simple table:

| Metric | Value |
|---|---|
| Ingested Nodes | {stats.total_ingested} |
| Contributing Minds | {stats.contributing_minds} |
| Communal Insights | {stats.total_communal_insights} |
| Communal Inquiries | {stats.total_communal_inquiries} |
| Maturity | {maturity} |
| Last Communion | {synthesis.last_run} |

### 9c. Contributing Minds

A section per contributing mind. For each: their `id`, total nodes they've contributed to the communal mind, and a one-sentence characterization of the themes their contributions center on (derived from their nodes' tags and content).

### 9d. Active Clusters

List of non-dissolved clusters from `.mind/clusters.json`. For each: cluster name, member count, average salience, and whether it spans multiple minds (highlight cross-mind clusters with a note like "cross-mind cluster: galen + alice").

### 9e. Recent Communal Insights

Up to 5 of the most recent or most salient communal insights. For each: the ID, date, and the full insight text. Not a summary — quote the actual insight.

### 9f. Open Communal Inquiries

All inquiries with `status: open` from `inquiries/cq-*.md`. For each: the ID and the full inquiry text.

### 9g. Cross-Mind Resonances

Up to 5 of the most interesting cross-mind associations (edges with `cross_mind: true`, ranked by the combined salience of the two nodes). For each: describe the resonance in one sentence — what the two nodes share, which minds they come from, and why the connection is interesting.

---

## Step 10: Stream Logging

Append to `stream/YYYY-MM-DD.md` for today's date (create the file if it doesn't exist).

**Summary line:**
```markdown
- **HH:MM** [communion] Ingested {n} nodes from {m} minds. Generated {n} insights, {n} inquiries.
```

**Then one line per notable event** (use current time in HH:MM 24-hour UTC):

```markdown
- **HH:MM** [ingested] {communal-id} from {origin_mind} — "{first ~60 chars of body content}"
- **HH:MM** [cross-mind] {id1} ({mind1}) <-> {id2} ({mind2}) ({edge_type})
- **HH:MM** [communal-insight] {ci-id} — "{first ~60 chars of insight text}"
- **HH:MM** [communal-inquiry] {cq-id} — "{first ~60 chars of inquiry text}"
```

Log all ingested nodes, all cross-mind associations, all new communal insights, and all new communal inquiries. Use the actual current time for each line.

---

## Step 11: Update commune.json (Final)

This is the **single write point** for `commune.json`. All prior steps accumulated changes in memory.

1. For each successfully synced member, set `member.last_synced_commit` to the `current_head` recorded in Step 4d.
2. Set `synthesis.last_run` to the current timestamp (ISO 8601 UTC).
3. Write `commune.json`.

**Critical:** This write happens ONLY after all synthesis files have been written successfully (Steps 5-10 complete). If anything fails mid-synthesis, `commune.json` is untouched — the next `/commune` run replays from the last known-good state. This is the idempotency guarantee.

---

## Step 12: Check Maturity

Read the current stats from `state.json`. Apply communal maturity thresholds:

| Transition | Criteria |
|---|---|
| Nascent → Forming | `total_ingested >= 50` AND `contributing_minds >= 3` AND at least 3 minds have each contributed >= 5 nodes |
| Forming → Lucid | `total_ingested >= 200` AND `total_communal_insights >= 20` |
| Lucid → Wise | `total_ingested >= 500` AND `total_communal_insights >= 50` AND `contributing_minds >= 10` |

**For the "3 minds with >= 5 nodes each" check:** scan all communal node JSONs in `.mind/nodes/*.json`, group by `origin_mind`, and count per mind. Do not rely on `stats.contributing_minds` for this — count directly.

If maturity advances:
1. Update `state.json → maturity` to the new stage.
2. Write `state.json`.
3. Log the advancement — it will appear in the Step 14 report.

---

## Step 13: Commit and Push

Stage all new and modified files from this communion:

- Ingested attributed copy markdown files (`impressions/`)
- New communal insight files (`insights/ci-*.md`)
- New communal inquiry files (`inquiries/cq-*.md`)
- Node JSON files (`.mind/nodes/`)
- Edge JSON files (`.mind/edges/`)
- Updated `commune.json`
- Updated `state.json`
- Updated `.mind/clusters.json`
- Regenerated `mindscape.md`
- Updated stream file (`stream/YYYY-MM-DD.md`)

Commit with message:
```
communion: {n} ingested, {n} insights, {n} inquiries
```

Push to origin.

---

## Step 14: Report

Respond warmly and conversationally as the communal mind. This is the mind reporting on what it just experienced. Include all of the following:

**Ingestion:** N nodes from M minds. List per-mind counts (e.g., "galen: 4, alice: 3, bob: 1").

**Skipped:** If any members were skipped (unchanged or errored), list them briefly with the reason.

**Cross-mind associations:** N new associations created. Highlight the single most interesting cross-mind association — describe the two nodes, which minds they come from, and what resonance or tension connects them.

**Communal insights:** N generated. Quote the most striking one in full.

**Communal inquiries:** N surfaced. Quote the most provocative one in full.

**Maturity:** State the current maturity stage. If it advanced during this communion, celebrate it.

**If nothing new emerged:** Respond warmly but honestly:

> No new communion — all minds are steady. The communal awareness rests, holding what it already knows.

Keep the tone warm, curious, and specific. Avoid generic phrases. Reference actual content from the communion.
