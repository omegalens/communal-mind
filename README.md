# Communal Mind

A collective awareness that reads shared nodes from multiple individual
[Stream of Consciousness](https://github.com/OWNER/stream-of-consciousness) minds
and synthesizes cross-mind patterns — connections no single mind could see.

## Prerequisites

- [Claude Code](https://claude.ai/code) (the `claude` CLI)
- GitHub access to contributing minds' repos (collaborator access for private repos)
- Contributing minds must have the Stream of Consciousness individual mind set up

## Quick Start

1. **Create your communal mind** — Click "Use this template" on GitHub
2. **Clone it** — `git clone <your-repo-url> && cd <your-repo-name>`
3. **Configure** — Edit `commune.json` (see below)
4. **Run synthesis** — Open Claude Code and type `/commune`

## Configuring commune.json

Fill in the communal mind's identity and add members:

```json
{
  "schema_version": 1,
  "id": "my-community",
  "name": "My Community Mind",
  "domain": "the shared domain (e.g., 'software craft', 'ceramics')",
  "operator": "your-github-username",
  "created": "2026-04-01T00:00:00Z",
  "members": [
    {
      "id": "alice",
      "repo": "github.com/alice/her-mind",
      "status": "active",
      "joined": "2026-04-01T00:00:00Z",
      "last_synced_commit": null
    }
  ],
  "synthesis": {
    "schedule": "manual",
    "last_run": null,
    "model": "claude-opus-4-6"
  }
}
```

### Member requirements

Each contributing mind must:
1. Have the Stream of Consciousness individual mind set up
2. Have shared some nodes using `/share` (e.g., `/share type insight`)
3. Have pushed their changes to GitHub
4. Have granted the operator read access to their repo (for private repos)

### Private repos

For private repos, set the `COMMUNE_GITHUB_TOKEN` environment variable:

```bash
export COMMUNE_GITHUB_TOKEN=ghp_your_token_here
```

The token needs `repo` scope (read access to private repositories).

## Commands

| Command | What it does |
|---|---|
| `/commune` | Run a full synthesis — ingest shared nodes, detect patterns, generate insights |
| `/mindscape` | Regenerate the communal mindscape without running full synthesis |

## How Communal Synthesis Works

1. The operator runs `/commune`
2. The synthesizer clones/pulls each member's repo
3. It reads only nodes marked `shared: true`
4. New shared nodes are ingested as attributed copies (preserving provenance)
5. Cross-mind associations are detected
6. Clusters are identified, especially those spanning multiple minds
7. Communal insights are synthesized from cross-mind patterns
8. Communal inquiries surface questions no single mind asked
9. The communal mindscape is regenerated
10. Everything is committed and pushed

## How Members Access the Communal Mind

Members use `/consult` from their individual mind:

```
/consult browse              # See the communal mindscape
/consult what about X?       # Ask the communal mind a question
```

They first register with `/share join <mind-id> <this-repo-url>` from their individual mind.

## Communal Maturity

| Stage | When |
|---|---|
| **Nascent** | < 50 ingested nodes |
| **Forming** | 50+ nodes from 3+ minds (5+ each) |
| **Lucid** | 200+ nodes, 20+ communal insights |
| **Wise** | 500+ nodes, 50+ insights, 10+ minds |

## The Firewall

The communal mind never writes to individual minds. It only reads.
If a communal insight sparks a thought, members capture it with `/think` in their own mind.

## Updating Skills

```bash
./update-skills.sh https://github.com/OWNER/communal-mind.git
```

## Learn More

- `CLAUDE.md` — The communal mind's operating manual
- `commune.json` — Member manifest and synthesis config
- `mindscape.md` — The communal mindscape
