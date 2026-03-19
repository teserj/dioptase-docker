# Embedded Dev Container

A Docker-based development environment for embedded systems work, with USB/serial device access and Claude Code pre-installed.

## Prerequisites

### 1. Claude Code Authentication on Host

Claude Code must be authenticated on the host before running the container. The container inherits credentials via bind-mounts — no in-container login is required.

**Install Claude Code on host:**
```bash
npm install -g @anthropic-ai/claude-code
```

**Authenticate:**
```bash
claude
```
Complete the OAuth flow (Claude.ai Pro subscription or API key). This creates:
- `~/.claude/` — settings and credentials directory
- `~/.claude.json` — session state

Both are required. Verify they exist before running the container:
```bash
ls -la ~/.claude/ ~/.claude.json
```

### 2. Docker

Docker Engine must be installed and running on the host.

### 3. (Optional) ANTHROPIC_API_KEY

If using API key authentication instead of OAuth, export it in your host shell:
```bash
export ANTHROPIC_API_KEY=$(cat ~/.secrets/anthropic_api_key)
```
Store the key in a file with `chmod 600` — never paste it inline to avoid shell history exposure.

---

## Build

```bash
./docker.build
```

To install additional apt packages, create `user-packages.txt` (one package per line) before building:
```
git
tmux
```

## Run

```bash
./docker.run
```

This mounts:
- `/dev` — full host device tree for hot-plug USB/serial access
- `/run/udev` — udev metadata for device attribute queries
- `$(pwd)` → `/workspace` — current directory as the working directory
- `~/.claude` and `~/.claude.json` — Claude Code credentials from host

## USB and Serial Device Access

The container runs with `--privileged` and a live bind-mount of `/dev`, so USB and serial devices are accessible in real time — including devices plugged or power-cycled after the container starts.

Serial devices (e.g. `/dev/ttyUSB0`) appear automatically when a USB-to-UART dongle is connected. Monitor plug events with:
```bash
udevadm monitor --subsystem-match=tty
```

## Included Tools

| Tool | Purpose |
|------|---------|
| `claude` | Claude Code AI assistant |
| `sigrok` / `pulseview` | Logic analyzer |
| `picocom` / `minicom` | Serial terminal |
| `clangd` / `clang-format` | C/C++ language server and formatter |
| `python3` | Scripting |
| `usbutils` (`lsusb`) | USB device inspection |
