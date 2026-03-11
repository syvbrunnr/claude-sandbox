# Claude Sandbox

Containerized Claude Code with [r7](https://github.com/syvbrunnr/r7-mcp) graph memory and [Matrix](https://github.com/syvbrunnr/matrix-mcp-server) communication.

## Quick Start

```bash
# 1. Clone and enter
git clone https://github.com/syvbrunnr/claude-sandbox.git && cd claude-sandbox

# 2. Configure
./setup.sh              # clones dependencies, creates .env from template
vim .env                # fill in your credentials

# 3. Build and run
./setup.sh              # builds containers
./start.sh              # launches Claude Code
```

## Configuration

All config lives in `.env`:

| Variable | Required | Description |
|----------|----------|-------------|
| `CLAUDE_CODE_OAUTH_TOKEN` | Yes | Auth token (run `claude setup-token` on host) |
| `MATRIX_HOMESERVER_URL` | No | Matrix server URL |
| `MATRIX_USER_ID` | No | Your agent's Matrix ID |
| `MATRIX_ACCESS_TOKEN` | No | Matrix access token |
| `FALKORDB_PASSWORD` | No | Graph DB password (default: `changeme`) |

## What's Included

- **[r7-mcp](https://github.com/syvbrunnr/r7-mcp)** — Persistent graph memory. Stores knowledge, tasks, identity, conventions.
- **[matrix-mcp-server](https://github.com/syvbrunnr/matrix-mcp-server)** — Matrix chat communication (if credentials provided).
- **[mcp-notify](https://github.com/syvbrunnr/mcp-notify)** — Push notifications from MCP servers.
- **FalkorDB** — Graph database (runs in Docker).
- **Default seed** — Curated set of 39 nodes covering core conventions, identity bootstrap, and graph usage patterns.

## First Boot

On first launch, your agent will:
1. Call `r7_boot` (loaded automatically via the boot rule)
2. Seed the graph with default conventions and patterns
3. Choose a name for itself

The graph is persistent — it survives container restarts via Docker volumes.

## Dependencies

Setup automatically clones these repos into `vendor/`:
- `syvbrunnr/r7-mcp` — graph memory server
- `syvbrunnr/mcp-notify` — notification proxy
- `syvbrunnr/matrix-mcp-server` — Matrix communication
