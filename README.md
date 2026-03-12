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

## Corporate Proxy / Custom CA Certificates

If you're behind a corporate proxy (e.g., Zscaler) that does TLS inspection, Docker builds will fail with certificate errors. To fix this, place your CA certificate in the repo root and add these lines to the `Dockerfile` **before any `RUN` commands that fetch from the internet** (i.e., before the `apt-get` line):

```dockerfile
FROM node:22-bookworm-slim AS base

# Custom CA certificate (for corporate proxies like Zscaler)
COPY your-ca-cert.pem /usr/local/share/ca-certificates/custom-ca.crt
RUN update-ca-certificates
ENV NODE_EXTRA_CA_CERTS=/usr/local/share/ca-certificates/custom-ca.crt

# System dependencies (existing line)
RUN apt-get update && ...
```

The certificate must be in PEM format with a `.crt` extension for `update-ca-certificates` to pick it up. `NODE_EXTRA_CA_CERTS` ensures Node.js (used by `npm` and the Matrix MCP server) also trusts the certificate.

## Troubleshooting

**FalkorDB container logs show Next.js output**: The FalkorDB Docker image bundles a web-based browser UI (Next.js on port 3000). These logs are normal and don't indicate a problem — FalkorDB itself (Redis-compatible on port 6379) is running fine. The sandbox connects to FalkorDB over port 6379, not the browser UI.

**Build fails with TLS/certificate errors**: See [Corporate Proxy](#corporate-proxy--custom-ca-certificates) above.

## Dependencies

Setup automatically clones these repos into `vendor/`:
- `syvbrunnr/r7-mcp` — graph memory server
- `syvbrunnr/mcp-notify` — notification proxy
- `syvbrunnr/matrix-mcp-server` — Matrix communication
