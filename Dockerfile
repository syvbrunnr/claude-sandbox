FROM node:22-bookworm-slim AS base

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git gnupg jq openssh-client python3 \
    && rm -rf /var/lib/apt/lists/*

# Go (for building r7-mcp and mcp-notify)
RUN GOVERSION=1.24.1 \
    && GOARCH=$(dpkg --print-architecture) \
    && curl -fsSL "https://go.dev/dl/go${GOVERSION}.linux-${GOARCH}.tar.gz" \
       -o /tmp/go.tar.gz \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

# Claude Code native binary
RUN CLAUDE_GCS="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases" \
    && CLAUDE_VERSION=$(curl -fsSL "$CLAUDE_GCS/latest") \
    && curl -fsSL -o /usr/local/bin/claude "$CLAUDE_GCS/$CLAUDE_VERSION/linux-$(dpkg --print-architecture)/claude" \
    && chmod +x /usr/local/bin/claude \
    && echo "Installed Claude Code $CLAUDE_VERSION"

# tsx for matrix-mcp-server stdio transport
RUN npm install -g tsx

# ── Build r7-mcp ──
FROM base AS r7-builder
COPY vendor/r7-mcp/ /tmp/r7-mcp/
RUN cd /tmp/r7-mcp && CGO_ENABLED=0 go build -o /r7-mcp ./cmd/r7-mcp/

# ── Build mcp-notify ──
FROM base AS notify-builder
COPY vendor/mcp-notify/ /tmp/mcp-notify/
RUN cd /tmp/mcp-notify \
    && go build -o /mcp-notify ./cmd/mcp-notify/ \
    && go build -o /mcp-notify-proxy ./cmd/mcp-notify-proxy/

# ── Final image ──
FROM base
COPY --from=r7-builder /r7-mcp /usr/local/bin/r7-mcp
COPY --from=notify-builder /mcp-notify /usr/local/bin/mcp-notify
COPY --from=notify-builder /mcp-notify-proxy /usr/local/bin/mcp-notify-proxy

# Build matrix-mcp-server
COPY vendor/matrix-mcp-server/ /opt/matrix-mcp-server/
RUN cd /opt/matrix-mcp-server && npm ci && npm run build

# Copy sandbox files
COPY seeds/ /opt/claude-sandbox/seeds/
COPY .claude/ /opt/claude-sandbox/.claude/
COPY CLAUDE.md /opt/claude-sandbox/CLAUDE.md
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create claude user
RUN useradd -m -s /bin/bash claude

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
