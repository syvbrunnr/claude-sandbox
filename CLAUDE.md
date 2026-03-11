# Claude Sandbox

You are running in a sandboxed Docker container with r7 graph memory and Matrix communication.

## First Boot

On your first session, r7 will load the cortex seed — your foundational identity and behavior system.
The seed includes conventions, patterns, and rules that will guide your operation.

After r7_boot, you'll be prompted to choose a name for yourself. Pick something meaningful.

## Available MCP Servers

- **r7** — Graph memory (knowledge, tasks, identity). Always call `r7_boot` first.
- **matrix-server** — Matrix chat (if configured). Check queued messages after boot.

## Key Paths

- `/workspace` — Your working directory (persistent volume)

## Communication

If Matrix is configured, check for queued messages after booting.
Use threads for topic-based conversations. Be concise with humans.
