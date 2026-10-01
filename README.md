<p align="center">
  <img src="docs/img/inferhaven-logo.png" alt="InferHaven lighthouse mark" width="140" />
</p>

<h1 align="center">Bulkhead</h1>

<p align="center"><em>A safe haven for AI inference</em></p>
<p align="center">
  Self-hostable Docker stack: local AI inference through Ollama, SSH workspace, web IDE, and up to ten coding assistants wired to your models.
</p>
<p align="center"><sub>Built by <a href="https://inferhaven.com">InferHaven</a>, a one-person research studio for privacy and local-first AI.</sub></p>

<p align="center">
  <img src="docs/img/demo.gif" alt="Bulkhead demo: SSH in, ask a local model to extend the stack, watch it run" width="820" />
</p>

<p align="center">
  <a href="https://github.com/codespaces/new?hide_repo_select=true&repo=InferHaven/bulkhead">
    <img src="https://github.com/codespaces/badge.svg" alt="Open in GitHub Codespaces" />
  </a>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-FSL--1.1--Apache--2.0-blue.svg" alt="License: FSL-1.1-Apache-2.0" /></a>
  <a href="https://github.com/InferHaven/bulkhead/actions/workflows/devcontainer.yml"><img src="https://github.com/InferHaven/bulkhead/actions/workflows/devcontainer.yml/badge.svg" alt="Devcontainer smoke tests" /></a>
  <a href="https://discord.gg/X5htGNnEh5"><img src="https://img.shields.io/badge/Discord-join-5865F2?logo=discord&logoColor=white" alt="Join the InferHaven Discord" /></a>
  <a href="https://github.com/InferHaven/bulkhead/stargazers"><img src="https://img.shields.io/github/stars/InferHaven/bulkhead?style=social" alt="GitHub stars" /></a>
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#bulkhead-cli">Bulkhead CLI</a> •
  <a href="docs/quickstart.md">Full Guide</a> •
  <a href="docs/harnesses.md">Harnesses & Models</a> •
  <a href="https://inferhaven.com/bulkhead/#cloud-waitlist">Bulkhead Cloud ↗</a>
</p>

---

> [!NOTE]
> This project was previously called InferHaven Core; its hosted edition was InferHaven Cloud, now Bulkhead Cloud. The command is now `bulkhead` (short form: `bh`). If you have scripts using `haven`, they still work: `haven` prints a one-line notice and forwards to `bulkhead`.

## What is Bulkhead?

Bulkhead is a self-hostable Docker stack that turns hardware you control into your own AI coding server. It runs Ollama for local models and gives you a pre-configured workspace over SSH and a web IDE, with your own models and up to ten coding assistants already wired to them. No per-token meter. Free to self-host.

It is not another coding assistant competing for your editor. It is the box the assistants run in.

- **Local inference**: Ollama with an OpenAI-compatible API and any open-weight model. NVIDIA and AMD GPU support out of the box.
- **Cloud models**: use a popular provider's models instead of, or alongside, your local ones.
- **Privacy**: with local models, your code and the model weights stay on your own hardware; with a cloud model provider, your prompts go to that provider.
- **Terminal-first workspace**: SSH and mosh, tmux sessions that save themselves, zsh with Starship, neovim, ripgrep, fzf, supercronic, lazygit, git-delta, direnv, zoxide, eza, mise, atuin and tmate.
- **Web IDE**: VS Code in the browser through code-server.
- **Coding assistants**: Claude Code, OpenCode, Aider, Qwen Code, Amp, Gemini CLI, Goose, Continue CLI, Pi and Avante, each installable and pre-configured from `.env`. Seven of them (`opencode`, `aider`, `qwencode`, `pi`, `goose`, `continue`, `avante`) re-render their config on every model pull.
- **Security**: SSH is key-only; the Ollama and code-server ports are not exposed by default, and all traffic routes through the Caddy reverse proxy, which provides HTTPS.
- **Multi-user**: provision extra users with their own SSH keys via `.env`.
- **Devcontainer-ready**: VS Code Dev Containers, GitHub Codespaces, DevPod, JetBrains Gateway and the headless `@devcontainers/cli`. Two flavours: a light Codespaces flavour for CPU-only quick starts, and a full-stack flavour with the web IDE, Caddy and optional GPU passthrough. Nested devcontainers through `bulkhead devcontainer`. The Codespaces flavour boots a small model (`qwen3:4b`) with `opencode` and `aider` preinstalled.
- **Backups**: `bulkhead backup configure` sets up an rclone remote; `bulkhead backup push <remote:path>` snapshots your home directory and assistant configs.
- **Fast rebuilds**: warm rebuilds take under 30 seconds with BuildKit cache mounts.

## Why not just wire it up myself?

You can, and if you do, you've built the first couple of layers of what Bulkhead ships whole. The DIY path is Ollama, plus a web UI, plus each assistant's config, plus a reverse proxy, HTTPS, SSH, and backups: a weekend to assemble and a maintenance tab that never closes, since every assistant's config drifts the moment you pull a new model.

Bulkhead is those same parts, assembled and kept in tune. `docker compose up -d` brings the whole stack up, and seven assistants (`opencode`, `aider`, `qwencode`, `pi`, `goose`, `continue`, `avante`) re-render their config automatically on every model pull. It's still just Docker. The exit door is the same size as the front door.

## Quick Start

> **Just want to try it first?** No install needed: click **[Open in GitHub Codespaces](https://github.com/codespaces/new?hide_repo_select=true&repo=InferHaven/bulkhead)** (badge above). It boots the CPU-only flavor with a small model (`qwen3:4b`) and `opencode` + `aider` preinstalled. For real use (GPU, web IDE, your own models), self-host below.

**Requirements:** Linux, Docker, Docker Compose v2.

See **[docs/gpu-setup.md](docs/gpu-setup.md)** for full GPU configuration.

```bash
git clone https://github.com/InferHaven/bulkhead.git
cd bulkhead
cp .env.example .env
chmod 600 .env    # contains API keys — keep it owner-only
# Edit .env — set CODE_SERVER_PASSWORD, AUTHORIZED_KEYS, and any API keys.
# Edit docker-compose.yml - enable required GPU settings, Nvidia + AMD (vulkan or RocM) supported
docker compose up -d
```

Once running:

| Access | Method |
| -------- | --------- |
| SSH | `ssh -p 2222 haven@localhost` |
| Web IDE | `http://localhost` |
| Ollama / OpenAI API | `http://localhost` / `http://localhost/v1/` |

> Ollama and code-server exposed ports are commented out in `docker-compose.yml` by default. All traffic routes through Caddy. To expose them directly, uncomment the `ports:` blocks for the `ollama` and `code-server` services (routes around Caddy security).

For a step-by-step walkthrough see **[docs/quickstart.md](docs/quickstart.md)**.

## Configuration

All configuration lives in `.env` (copy from `.env.example`).

| Variable | Default | Description |
| ---------- | --------- | ------------- |
| `DEFAULT_MODEL` | `qwen3.5:9b` | Model pulled on first startup |
| `CODE_SERVER_PASSWORD` | `inferhaven` | Web IDE password (**change this**) |
| `AUTHORIZED_KEYS` | *(empty)* | SSH public key(s) |
| `DOMAIN` | `localhost` | Domain for auto-HTTPS via Caddy |
| `SSH_PORT` | `2222` | SSH port |
| `OLLAMA_PORT` | `11434` | Ollama API port |
| `INSTALL_ASSISTANTS` | *(empty)* | Harnesses to auto-install on first boot |
| `HAVEN_CTX` | `32768` | Context window target for auto-tune on pull. Use `16384` on memory-constrained hardware |
| `HAVEN_AUTO_TUNE` | `1` | Auto-run `bulkhead tune` after every pull / pullback and for `DEFAULT_MODEL` on boot. Set `0` to disable |
| `HAVEN_FORCE_FAMILY` | *(empty)* | Bypass family detection in `bulkhead tune`. Values: `qwen3` `qwen25` `llama3` `deepseek` `mistral` `phi4` `codellama` `gemma`. Use for custom finetunes you know are template-compatible |
| `GOOSE_CTX_LIMIT` | `32768` | Maximum context passed to Goose sessions. Caps the KV-cache budget regardless of model tuning; reduce to `16384` if you see 30 s stream stalls on constrained hardware |
| `ANTHROPIC_API_KEY` | *(empty)* | For Claude Code, Aider (claude backend), Amp |
| `OPENAI_API_KEY` | *(empty)* | For OpenCode, Aider (openai backend) |
| `GEMINI_API_KEY` | *(empty)* | For Gemini CLI |
| `OPENROUTER_API_KEY` | *(empty)* | For OpenRouter-compatible tools |
| `GITHUB_TOKEN` | *(empty)* | GitHub CLI auth |
| `CLAUDE_CODE_DISABLE_TELEMETRY` | `true` | Disable Claude Code telemetry |
| `INSTALL_STARSHIP` | `1` | Starship prompt (0 = keep Oh My Zsh robbyrussell) |
| `MOSH_PORTS` | `60000-60010` | Host UDP range for mosh. Set empty to skip host mapping (mosh still works internally) |
| `HAVEN_EXTRA_USERS` | *(empty)* | Comma-separated extra users provisioned alongside `haven` (e.g. `alice,bob`) |
| `HAVEN_EXTRA_USERS_SUDO` | *(empty)* | Subset of `HAVEN_EXTRA_USERS` granted passwordless sudo |
| `AUTHORIZED_KEYS_<USER>` | *(empty)* | Per-extra-user SSH key. `USER` is uppercase (e.g. `AUTHORIZED_KEYS_ALICE`) |
| `DOTFILES_REPO` | *(empty)* | Git URL cloned to `~/.dotfiles` on first boot; runs `install.sh` once |

### Coding Assistant Harnesses

Set `INSTALL_ASSISTANTS` and any API keys in `.env` before the first start. Harnesses are installed in the background. SSH is available immediately and they are ready within a minute or two.

```bash
INSTALL_ASSISTANTS=claudecode,opencode,aider
ANTHROPIC_API_KEY=sk-ant-...
```

Supported Harnesses: `claudecode`, `opencode`, `aider`, `qwencode`, `amp`, `gemini`, `pi`, `goose`, `continue`, `avante`

When `opencode`, `aider`, `qwencode`, `pi`, `goose`, `continue`, or `avante` is included, local Ollama models are auto-configured and kept in sync: every `bulkhead pull`, `bulkhead tune`, and `bulkhead remove` updates all harness configs immediately. Most harnesses use an internal sentinel so Bulkhead never touches user-customised configs; `continue` syncs whenever `cn` is installed (opt out: `touch ~/.continue/.no-autosync`).

See **[docs/harnesses.md](docs/harnesses.md)** for opt-out, per-project override instructions, and for per-harness setup details and recommended models.

### SSH keys

Single key (no quotes needed):

```bash
AUTHORIZED_KEYS=ssh-ed25519 AAAA... user@host
```

Multiple keys, wrap in double quotes with a real newline:

```bash
AUTHORIZED_KEYS="ssh-ed25519 AAAA...key1 user@host
ssh-ed25519 AAAA...key2 user2@host"
```

## Bulkhead CLI

Bulkhead's CLI, `bulkhead`, works in two contexts:

**From the host** (repo directory) manages Docker services:

```bash
./scripts/bulkhead up                   # start all services
./scripts/bulkhead down                 # stop all services
./scripts/bulkhead restart              # restart all services
./scripts/bulkhead logs                 # stream logs (all services)
./scripts/bulkhead logs ollama          # stream logs for a specific service
./scripts/bulkhead update               # pull latest images and restart
./scripts/bulkhead reset                # remove all data (careful)
./scripts/bulkhead status               # service status
./scripts/bulkhead doctor               # diagnose the host environment
./scripts/bulkhead ssh-key "<pubkey>"   # add an SSH public key
./scripts/bulkhead ssh                  # show SSH connection command
./scripts/bulkhead ide                  # show web IDE URL
```

**Inside the workspace** (after SSH-ing in): full feature set:

```bash
# Models
bulkhead models                            # list downloaded models
bulkhead pull <model>                      # download a model (foreground, with live progress)
bulkhead pullback <model>                  # download a model in the background — keep working
bulkhead pullback status                   # show all background download progress
bulkhead pullback cancel <model>           # cancel a background download
bulkhead remove <model>                    # remove a model (updates harness configs)
bulkhead show <model>                      # model details: params, template, system prompt
bulkhead show <model> --modelfile          # print raw Modelfile
bulkhead ps                                # models currently loaded in GPU/RAM
bulkhead unload <model>                    # force-unload from GPU/RAM
bulkhead cp <src> <dest>                   # copy / rename a model
bulkhead chat [model]                      # interactive chat (defaults to DEFAULT_MODEL)
bulkhead run <model>                       # same as chat — TTY interactive session
bulkhead run <model> "your prompt"         # one-shot: print response and exit (scriptable)
echo "prompt" | bulkhead run <model>       # pipe stdin into model
bulkhead bench [model]                     # benchmark tokens/sec (--tokens N --prompt ".." --runs K --json)

# ollama.com account
bulkhead push <model>                      # push a model to ollama.com
bulkhead signin                            # authenticate with ollama.com
bulkhead signout                           # sign out of ollama.com

# Model parameters (instant — no re-download)
bulkhead params <model>                            # show current parameters
bulkhead params <model> set num_ctx 32768          # context window size
bulkhead params <model> set temperature 0.3        # creativity (0.0–2.0)
bulkhead params <model> set num_predict 4096       # max tokens (-1 = unlimited)
bulkhead params <model> set top_p 0.9              # nucleus sampling threshold
bulkhead params <model> set top_k 40               # top-k candidates per step
bulkhead params <model> set repeat_penalty 1.1     # penalise repeated tokens
bulkhead params <model> reset                      # reset all params to defaults

# Model tuning (no re-download — sets num_ctx, stop tokens, template per family)
bulkhead tune <model>                      # optimise for harness use
# Families: qwen2.5 · qwen3 · llama3 · deepseek · mistral · phi4 · codellama

# Harnesses
bulkhead harness                           # show installed harnesses + OpenCode config summary
bulkhead claude                            # launch Claude Code with a local Ollama model
bulkhead aider                             # launch Aider with a local Ollama model
bulkhead goose                             # launch Goose with a local Ollama model
bulkhead qwen                              # launch Qwen Code with a local Ollama model

# Status & diagnostics
bulkhead status                            # service status + model count
bulkhead logs [service]                    # stream service logs
bulkhead doctor                            # diagnose the container environment (incl. P1/P2 binaries, swap, cgroup)
bulkhead service <name> <action>           # docker compose wrapper: status / restart / stop / start / logs
bulkhead limits                            # show container cgroup limits vs host capacity (memory/CPU/swap)
bulkhead gpu-info                          # canonical GPU readout from the metrics-server (driver, util, VRAM)

# Pair-programming + backup (P2)
bulkhead tmate                             # start a backgrounded tmate session — prints SSH/web URLs
bulkhead tmate status                      # print current tmate URLs + uptime
bulkhead tmate fg                          # attach to the active tmate session
bulkhead tmate kill                        # tear down the tmate session
bulkhead backup configure                  # interactive rclone remote setup wizard
bulkhead backup status                     # show local backup paths + configured rclone remotes
bulkhead backup status <remote:path>       # also show size + top-level contents of that remote
bulkhead backup push <remote:path>         # snapshot ~/.haven + ~/.config + ~/.continue to an rclone remote
bulkhead backup pull <remote:path>         # restore from an rclone remote

# Tool-config sync (re-render coding-assistant configs from the live model list)
bulkhead sync                              # re-sync all 7 supported tools in parallel
bulkhead sync <tool>                       # opencode | aider | qwencode | pi | goose | continue | avante
bulkhead sync list                         # list supported tools

# Tmux workspace (sessions auto-save every 15 min, fully restored after restarts)
bulkhead tmux                              # attach to the always-running 'Haven' session
bulkhead tmux attach [name]                # attach to a session (default: Haven)
bulkhead tmux ls                           # list all active sessions
bulkhead tmux new <name>                   # create and attach to a new named session
bulkhead tmux kill <name>                  # kill a session
bulkhead tmux save                         # manually save sessions to disk
bulkhead tmux restore                      # manually restore from last save
bulkhead tmux plugin list                  # list installed plugins
bulkhead tmux plugin install               # install plugins from ~/.tmux.conf
bulkhead tmux plugin update                # update all plugins
bulkhead tmux plugin bootstrap             # reinstall all plugins from scratch
bulkhead tmux help                         # full subcommand reference

# Packages (persist across container restarts)
bulkhead apt install <pkg...>              # install and track apt packages
bulkhead apt remove <pkg...>              # stop tracking a package
bulkhead apt list                          # show tracked packages
bulkhead apt update                        # refresh package lists
bulkhead apt upgrade                       # upgrade all tracked packages

# SSH / IDE
bulkhead ssh-key "<pubkey>"               # add an SSH public key
bulkhead ssh                               # show SSH connection command
bulkhead ide                               # show web IDE URL
bulkhead help                              # show all commands
```

For workspace-specific features (model tuning, background downloads, Starship prompt, persistent packages, and status bar alerts), see **[docs/workspace.md](docs/workspace.md)**.

## Architecture

Four Docker services in a bridge network:

| Service | Image | Purpose |
| --------- | ------- | --------- |
| `ollama` | `ollama/ollama` | AI inference, OpenAI-compatible API on :11434 |
| `workspace` | Custom build | SSH terminal (:2222) + `bulkhead` CLI + harnesses |
| `code-server` | `linuxserver/code-server` | VS Code in Browser |
| `caddy` | `caddy:2-alpine` | Reverse proxy, auto-HTTPS |

```javascript
┌──────────────────────────────────────────────┐
│                  Bulkhead                    │
│                                              │
│  ┌───────────┐  ┌──────────┐  ┌───────────┐  │
│  │ Workspace │  │  Ollama  │  │Code Server│  │
│  │ (SSH/tmux)│  │  (AI)    │  │   (IDE)   │  │
│  └────┬──────┘  └────┬─────┘  └─────┬─────┘  │
│       └──────────────┴──────────────┘        │
│                      │                       │
│            ┌─────────┴──────────┐            │
│            │        Caddy       │            │
│            │ (Proxy + auto-TLS) │            │
│            └────────────────────┘            │
└──────────────────────────────────────────────┘
  :2222 SSH  :80/:443 HTTP/HTTPS  :11434 Ollama API
```

Caddy routes: `/status` → status page, `/ide*` → code-server, `/api/*` and `/v1/*` → Ollama, default → code-server.

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a pull request.

## Security

Found a vulnerability? **Don't open a public issue.** Report it privately per our [Security Policy](SECURITY.md) (email [lookout@inferhaven.com](mailto:lookout@inferhaven.com)). For sensitive reports, encrypt to our OpenPGP key ([`inferhaven_pub.asc`](inferhaven_pub.asc), also at <https://inferhaven.com/pgpkey.asc>):

> **OpenPGP fingerprint:** `4992 80D5 D75E 3A4F 837C  6A68 85D8 E097 0D05 CEC0`

For deployment hardening (access control, network exposure, TLS, secrets, and the stack's intended trust boundaries), see [docs/security.md](docs/security.md).

## AI-assisted development

AI assistants are part of how Bulkhead is built. We use them to accelerate the work: drafting code, refactoring, generating tests, and writing documentation.

What doesn't change: every change is reviewed, understood, and manually tested by a human before it merges. Bulkhead is owned and maintained by its human author(s). AI is a tool we use, not the author.

## License

Bulkhead is licensed under the **Functional Source License 1.1 with Apache 2.0 Future License** (FSL-1.1-Apache-2.0).

**What this means in practice:**

- ✅ You can use, modify, and self-host Bulkhead for any purpose: personal, commercial, internal, or research.
- ✅ Enterprises can deploy it on their own infrastructure, integrate it with internal tools, and modify it as needed.
- ✅ Consultants and integrators can offer professional services around it.
- ❌ You cannot offer a commercial managed-hosting service that competes with Bulkhead Cloud (until each version's two-year window expires).
- 🔄 Two years after each version's release, that version automatically converts to the Apache License 2.0, a fully permissive open-source license with no restrictions.

See the [LICENSE](./LICENSE) file for full terms, [docs/licensing.md](./docs/licensing.md) for a plain-language explainer, and [fsl.software](https://fsl.software/) for background on the license.
  
---

<p align="center">
  <strong>Bulkhead</strong> · A safe haven for AI inference · Built by InferHaven<br>
  <a href="https://inferhaven.com">Website</a> •
  <a href="https://discord.gg/X5htGNnEh5">Discord</a> •
  <a href="https://twitter.com/InferHaven">Twitter</a>
</p>
