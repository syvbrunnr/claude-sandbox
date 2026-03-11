#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Claude Sandbox Setup ==="

# Check prerequisites
for cmd in docker git; do
    if ! command -v $cmd &>/dev/null; then
        echo "Error: $cmd is required but not installed."
        exit 1
    fi
done

if ! docker compose version &>/dev/null; then
    echo "Error: docker compose is required (Docker Desktop includes it)."
    exit 1
fi

# Check .env
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "Created .env from .env.example — please edit it with your credentials."
        echo ""
        echo "Required:"
        echo "  CLAUDE_CODE_OAUTH_TOKEN  — run 'claude setup-token' to generate"
        echo ""
        echo "Optional:"
        echo "  MATRIX_*                 — Matrix credentials (leave blank to skip)"
        echo ""
        echo "Then run this script again."
        exit 0
    else
        echo "Error: .env.example not found."
        exit 1
    fi
fi

# Verify token is set
source .env
if [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
    echo "Error: CLAUDE_CODE_OAUTH_TOKEN is not set in .env"
    echo "Run 'claude setup-token' on your host to generate one."
    exit 1
fi

# Vendor dependencies (clone from GitHub if not present)
echo ""
echo "Checking dependencies..."

mkdir -p vendor

vendor_repo() {
    local name=$1 url=$2 dir="vendor/$name"
    if [ -d "$dir" ]; then
        echo "  $name: already present"
    else
        echo "  $name: cloning from $url..."
        git clone --depth 1 "$url" "$dir"
    fi
}

vendor_repo r7-mcp https://github.com/syvbrunnr/r7-mcp.git
vendor_repo mcp-notify https://github.com/syvbrunnr/mcp-notify.git
vendor_repo matrix-mcp-server https://github.com/syvbrunnr/matrix-mcp-server.git

# Build and start
echo ""
echo "Building containers..."
docker compose build

echo ""
echo "Starting services..."
docker compose up -d falkordb
echo "Waiting for FalkorDB to be ready..."
sleep 2

echo ""
echo "=== Setup Complete ==="
echo "Run './start.sh' to launch Claude Code."
