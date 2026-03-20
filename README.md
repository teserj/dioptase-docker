# Embedded Dev Container

A Docker-based development environment for embedded systems work, with USB/serial device access and Claude Code pre-installed.

## Prerequisites

### 1. Docker

Docker Engine must be installed and running on the host.

### 2. GitHub SSH Key

An SSH key linked to your GitHub account is required to access the Claude marketplace and install extensions from `github.com/anthropics`. The container uses SSH agent forwarding — no in-container setup is needed.

**Ensure your key is loaded in the host ssh-agent:**
```bash
ssh-add ~/.ssh/id_ed25519
```
If you don't have a key yet: `ssh-keygen -t ed25519 -C "your_email@example.com"`, then run the above.

**Add your public key to GitHub** (one-time):
1. Copy it: `cat ~/.ssh/id_ed25519.pub`
2. Go to **GitHub → Settings → SSH and GPG keys → New SSH key** and paste it

**Verify the connection on the host:**
```bash
ssh -T git@github.com
```
Expected response: `Hi <username>! You've successfully authenticated...`

Once verified on the host, the same identity is available inside the container via the forwarded agent socket.

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
- `claude-user/` → `/home/node/.claude` — Claude Code settings and credentials (auto-created)
- `claude-user.json` → `/home/node/.claude.json` — Claude session state (auto-created)

On first run, authenticate inside the container:
```bash
claude
```
Credentials are saved to `claude-user/` and persist across container restarts.

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
