#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Check setup
if [ ! -f .env ]; then
    echo "Run ./setup.sh first."
    exit 1
fi

# Ensure FalkorDB is running
if ! docker compose ps falkordb --status running -q 2>/dev/null | grep -q .; then
    echo "Starting FalkorDB..."
    docker compose up -d falkordb
    sleep 2
fi

# Bump inotify limits (needed for file watchers)
docker run --rm --privileged --pid=host alpine sysctl -w \
    fs.inotify.max_user_watches=524288 \
    fs.inotify.max_user_instances=512 \
    > /dev/null 2>&1 || true

# Run Claude Code interactively
exec docker compose run --rm -it claude "$@"
