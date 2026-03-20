# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Docker-based development environment for embedded systems work. It packages Claude Code, embedded dev tools (sigrok, picocom, clangd), and a network firewall into a container that exposes host USB/serial devices at runtime.

## Build & Run

```bash
./docker.build          # builds image tagged 'embedded-dev'
./docker.run            # runs container with device and credential mounts
```

To add apt packages before building, create `user-packages.txt` (one package per line) in the repo root — the Dockerfile installs them at build time.

The run script automatically handles:
- SSH agent forwarding (macOS uses fixed socket; Linux reads `$SSH_AUTH_SOCK`)
- Claude credentials (`claude-user/` directory and `claude-user.json` in repo root)
- USB/serial device access via `/dev` bind-mount

## Architecture

### Container Identity & Permissions
- Runs as the `node` user (UID 1000) — not root
- `node` is in the `dialout` group for serial device access
- `node` has passwordless sudo only for `/usr/local/bin/init-firewall.sh`
- Claude Code is installed globally via npm into `/usr/local/share/npm-global`

### Network Sandbox (`init-firewall.sh`)
The firewall script runs at container startup (before the shell) and sets an allowlist-only outbound policy. Allowed destinations:
- GitHub IPs (fetched dynamically from `api.github.com/meta` — web, api, git ranges)
- `registry.npmjs.org`, `api.anthropic.com`, `sentry.io`, `statsig.anthropic.com`, `statsig.com`
- VS Code marketplace/blob storage
- Host subnet (auto-detected via default route)
- DNS (UDP 53) and SSH (TCP 22)

All other outbound traffic is rejected. The script verifies the firewall by confirming `example.com` is unreachable and `api.github.com` is reachable before exiting.

To add a new allowed domain, edit the domain list in `init-firewall.sh` and rebuild the container.

### Workspace Mount
`$(pwd)` on the host is mounted to `/workspace` inside the container — run `./docker.run` from the directory you want to work in.

### Claude Credentials
- `claude-user/` (auto-created if missing) → `/home/node/.claude`
- `claude-user.json` (auto-created as `{}` if missing) → `/home/node/.claude.json`

These persist across container restarts without rebuilding.
