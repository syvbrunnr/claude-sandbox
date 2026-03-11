#!/bin/bash
set -e

echo "=== Claude Sandbox Startup ==="

HOME="/home/claude"
export HOME

# Ensure directories
mkdir -p "$HOME/.claude/rules" "$HOME/.local/bin" "$HOME/.npm"
chown -R claude:claude "$HOME"

# Claude Code symlink
ln -sf /usr/local/bin/claude "$HOME/.local/bin/claude"
export PATH="$HOME/.local/bin:$PATH"

# Copy r7 boot rule (idempotent)
cp /opt/claude-sandbox/.claude/rules/r7_boot.md "$HOME/.claude/rules/r7_boot.md"
chown claude:claude "$HOME/.claude/rules/r7_boot.md"

# Skip onboarding, set theme
CLAUDE_JSON="$HOME/.claude.json"
python3 -c "
import json, os
path = '$CLAUDE_JSON'
data = {}
if os.path.exists(path):
    with open(path) as f:
        data = json.load(f)
data['theme'] = data.get('theme') or 'dark'
data['hasCompletedOnboarding'] = True
data['lastOnboardingVersion'] = '999.0.0'
data['autoUpdates'] = False
data['installMethod'] = 'native'
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
"
chown claude:claude "$CLAUDE_JSON"

# Generate MCP config
WORKDIR="${CLAUDE_WORKDIR:-/workspace}"
mkdir -p "$WORKDIR"
chown claude:claude "$WORKDIR"

python3 << 'PYEOF'
import json, os

config = {
    "mcpServers": {
        "r7": {
            "type": "stdio",
            "command": "/usr/local/bin/r7-mcp",
            "args": [],
            "env": {
                "FALKORDB_HOST": os.environ.get("FALKORDB_HOST", "localhost"),
                "FALKORDB_PORT": os.environ.get("FALKORDB_PORT", "6379"),
                "FALKORDB_PASSWORD": os.environ.get("FALKORDB_PASSWORD", ""),
            }
        },
        "matrix-server": {
            "type": "stdio",
            "command": "node",
            "args": ["/opt/matrix-mcp-server/dist/stdio-server.js"],
            "env": {
                "MATRIX_HOMESERVER_URL": os.environ.get("MATRIX_HOMESERVER_URL", ""),
                "MATRIX_USER_ID": os.environ.get("MATRIX_USER_ID", ""),
                "MATRIX_ACCESS_TOKEN": os.environ.get("MATRIX_ACCESS_TOKEN", ""),
            }
        }
    }
}

# Remove matrix-server if no credentials provided
if not config["mcpServers"]["matrix-server"]["env"]["MATRIX_ACCESS_TOKEN"]:
    del config["mcpServers"]["matrix-server"]
    print("Matrix MCP: skipped (no MATRIX_ACCESS_TOKEN)")
else:
    print("Matrix MCP: configured")

with open("/tmp/container-mcp.json", "w") as f:
    json.dump(config, f, indent=2)

workdir = os.environ.get("CLAUDE_WORKDIR", "/workspace")
mcp_path = os.path.join(workdir, ".mcp.json")
with open(mcp_path, "w") as f:
    json.dump(config, f, indent=2)

names = ", ".join(config["mcpServers"].keys())
print(f"MCP config: {len(config['mcpServers'])} server(s): {names}")
PYEOF

# Write env file for su session (avoids embedding secrets in command line)
ENV_FILE="/tmp/claude-env.sh"
cat > "$ENV_FILE" << EOF
export HOME=/home/claude
export PATH=/home/claude/.local/bin:/usr/local/bin:\$PATH
export CLAUDE_CODE_OAUTH_TOKEN="$CLAUDE_CODE_OAUTH_TOKEN"
export CLAUDE_CONFIG_DIR=/home/claude/.claude
EOF
chmod 600 "$ENV_FILE"
chown claude:claude "$ENV_FILE"

# Copy CLAUDE.md to workspace (project-level instructions for Claude Code)
if [ -f /opt/claude-sandbox/CLAUDE.md ] && [ ! -f "$WORKDIR/CLAUDE.md" ]; then
    cp /opt/claude-sandbox/CLAUDE.md "$WORKDIR/CLAUDE.md"
    chown claude:claude "$WORKDIR/CLAUDE.md"
fi

cd "$WORKDIR"
echo "Working directory: $WORKDIR"
echo "Token: ${#CLAUDE_CODE_OAUTH_TOKEN} chars"
echo "======================================="

exec su -s /bin/bash claude -c "
    source /tmp/claude-env.sh
    cd ${WORKDIR}
    exec /usr/local/bin/mcp-notify \
        --mcp-config /tmp/container-mcp.json \
        --skip-permissions \
        -- \"\$@\"
" -- "$@"
