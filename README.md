# Dotfiles — Claude Code + Vertex AI + Google ADK + Gemini CLI

Portable development environment for AI-accelerated development across macOS and Linux.
Manages Claude Code configuration, GCP Vertex AI authentication, Google ADK skills,
Gemini CLI integration, and office document generation — all via GNU Stow symlinks.

## What's inside

```
dotfiles/
├── bootstrap.sh                  # Installs all prerequisites (detects OS automatically)
├── install.sh                    # Stows configs, installs skills, verifies setup
├── uninstall.sh                  # Clean removal (safe reset or full reset)
├── local.template                # Template for machine-local secrets (copied per machine)
├── claude/                       # → symlinked to ~/
│   ├── .claude/
│   │   ├── settings.json         # Permissions, LSP, hooks (auto-format + block push to main)
│   │   ├── CLAUDE.md             # Global instructions (loaded every session)
│   │   ├── commands/             # Custom /slash commands (/review, /plan)
│   │   └── agents/               # Sub-agents (@gemini)
│   └── .mcp.json                 # Global MCP servers (ADK docs)
├── shell/                        # → symlinked to ~/
│   ├── .bashrc                   # Linux shell config
│   ├── .zshrc                    # macOS shell config
│   └── .bash_claude              # Vertex AI env vars + aliases (shared by both shells)
└── git/                          # → symlinked to ~/
    └── .gitconfig
```

## Features

**Claude Code:** Permission allowlist, LSP enabled, auto-format hook (prettier/black/gofmt/terraform), block push to main hook, custom slash commands.

**Vertex AI:** Service account key auth (no token expiry), model pinning (Opus 4.6, Sonnet 4.6, Haiku 4.5), gcp-switch for multi-project support.

**Gemini CLI:** @gemini sub-agent for codebase analysis using Gemini's 1M token context window.

**Skills:** Google ADK (6 skills), Frontend Slides (HTML presentations), Office Skills (.pptx/.docx/.xlsx/.pdf).

**MCP servers:** ADK docs (live official documentation access).

---

## Setup

### 1. First time ever (repo creation — done once, one machine only)

```bash
cd ~/dotfiles
git init
git add .
git commit -m "dotfiles: Claude Code + Vertex AI + ADK + Gemini + office skills"
gh auth login
gh repo create dotfiles --private --source=. --push
```

### 2. Fresh macOS machine

```bash
# Install prerequisites
curl -fsSL https://raw.githubusercontent.com/couchrishi/dotfiles/main/bootstrap.sh | bash

# Clone
git clone https://github.com/couchrishi/dotfiles.git ~/dotfiles

# Copy keys BEFORE install (so install.sh detects them and copies local.template)
mkdir -p ~/.config/gcloud/keys
# Copy your .json service account key files here

# Install (detects keys, copies local.template → ~/.zshrc.local, installs skills)
cd ~/dotfiles && ./install.sh

# Edit local overrides — only two secrets to fill in:
#   GEMINI_API_KEY="your-gemini-api-key-here"  →  your real key
#   GITHUB_PAT="your-github-pat-here"          →  your real PAT
nano ~/.zshrc.local

# Source and verify
source ~/.zshrc
claude-info
gcp-switch saib
claude-info
gcp-switch vital
claude-info
gcp-switch saib

# Launch
cc
```

### 3. Fresh Linux machine (GCP workstation / corporate VM)

```bash
# Install prerequisites
curl -fsSL https://raw.githubusercontent.com/couchrishi/dotfiles/main/bootstrap.sh | bash

# Clone
git clone https://github.com/couchrishi/dotfiles.git ~/dotfiles

# Copy keys BEFORE install (so install.sh detects them and copies local.template)
mkdir -p ~/.config/gcloud/keys
# Copy your .json service account key files here

# Install (detects keys, copies local.template → ~/.bashrc.local, installs skills)
cd ~/dotfiles && ./install.sh

# Edit local overrides — only two secrets to fill in:
#   GEMINI_API_KEY="your-gemini-api-key-here"  →  your real key
#   GITHUB_PAT="your-github-pat-here"          →  your real PAT
nano ~/.bashrc.local

# Source and verify
source ~/.bashrc
claude-info
gcp-switch saib
claude-info
gcp-switch vital
claude-info
gcp-switch saib

# Launch
cc
```
claude-info
gcp-switch saib
claude-info
gcp-switch vital
claude-info
gcp-switch saib

# Launch
cc
```

### 4. Update existing macOS machine

```bash
cd ~/dotfiles
git pull
./install.sh
source ~/.zshrc
```

### 5. Update existing Linux machine

```bash
cd ~/dotfiles
git pull
./install.sh
source ~/.bashrc
```

### 6. Uninstall

```bash
cd ~/dotfiles
./uninstall.sh              # removes symlinks, restores original configs
./uninstall.sh --full       # also removes keys, local overrides, installed skills
```

### 7. Reinstall after uninstall

```bash
cd ~/dotfiles
./install.sh
source ~/.zshrc             # or ~/.bashrc on Linux
```

### 8. LSP plugins (once per machine, inside Claude Code)

```
/plugin install pyright-lsp@claude-plugins-official         # Python
/plugin install typescript-lsp@claude-plugins-official       # TypeScript/JavaScript
/plugin install gopls-lsp@claude-plugins-official            # Go
/plugin install rust-analyzer-lsp@claude-plugins-official    # Rust
```

Restart Claude Code after installing.

---

## Verification checklist

After any setup or reinstall, run through this:

```bash
# Config correct?
claude-info                 # should show correct project, model, service account

# Project switching works?
gcp-switch vital
claude-info                 # should show vital-octagon across the board
gcp-switch saib
claude-info                 # should show saib-ai-playground across the board

# Claude Code launches?
cc                          # should show Vertex AI, correct model

# Inside Claude Code:
/doctor                     # health check
@gemini hello               # tests Gemini sub-agent
/frontend-slides            # tests slides skill
```

---

## Day-to-day usage

### GCP project switching

```bash
gcp-switch saib             # → saib-ai-playground
gcp-switch vital            # → vital-octagon-19612
gcp-switch                  # show current config
```

Restart Claude Code after switching — it reads env vars at startup.

### Inside Claude Code

```
/review                     # code review (security, performance, readability)
/plan                       # plan before coding, wait for approval
/frontend-slides            # create interactive HTML presentation
@gemini analyze this codebase architecture
```

### Presentations

```
# Interactive HTML (demos, tech talks):
/frontend-slides

# Professional .pptx (client deliverables, executive decks):
Create a PowerPoint presentation about X. 5-7 slides. Target audience: executives.

# From existing markdown files:
Create a presentation based on docs/project-overview.md
```

### Key aliases

| Alias | Command |
|-------|---------|
| cc | claude --dangerously-skip-permissions |
| ccc | claude --continue |
| ccr | claude --resume |
| ccp | claude -p (one-shot/print mode) |
| claude-info | Show Vertex AI config + active GCP account |
| gcp-switch | Switch between GCP projects |

---

## Managing customizations going forward

### What's tracked vs. what's not

Because of symlinks, some things are automatically tracked in this repo and some are not:

| What | Where it lives | Tracked in repo? | How to keep in sync |
|------|---------------|-------------------|---------------------|
| Settings, permissions, hooks | ~/dotfiles/claude/.claude/settings.json → symlinked | Yes — changes appear in git status | Commit and push |
| CLAUDE.md | ~/dotfiles/claude/.claude/CLAUDE.md → symlinked | Yes | Commit and push |
| Slash commands | ~/dotfiles/claude/.claude/commands/ → symlinked | Yes | Commit and push |
| Agents | ~/dotfiles/claude/.claude/agents/ → symlinked | Yes | Commit and push |
| MCP servers | ~/dotfiles/claude/.mcp.json → symlinked | Yes | Commit and push |
| Skills from npx skills add | ~/.claude/skills/ (NOT symlinked) | No — lives on that machine only | Add install command to install.sh |
| Plugins from /plugin install | Claude Code internal cache | No — lives on that machine only | Re-install per machine |
| Local overrides | ~/.zshrc.local or ~/.bashrc.local | No — gitignored | Copy local.template on new machines |
| Service account keys | ~/.config/gcloud/keys/ | No — gitignored | Copy manually per machine |

### The discipline: how to keep everything in sync

**For settings, commands, agents, MCP servers** (symlinked — tracked automatically):

Edit through the dotfiles path or let Claude Code edit the symlinked files. Either way, changes show up in `git status`:

```bash
# From any Claude Code session:
# "Add Bash(kubectl *) to the allow list in ~/.claude/settings.json"
# "Create a new /deploy slash command"

# Then commit:
cd ~/dotfiles && git add . && git commit -m "description" && git push
```

**For new skills you discover** (not symlinked — need manual step):

1. Test it: `npx skills add some-org/some-repo -a claude-code -g -y`
2. If you like it, add the install command to `install.sh` so every machine gets it
3. Commit and push `install.sh`

**For new MCP servers:**

Always edit `~/dotfiles/claude/.mcp.json` directly. Don't use `claude mcp add` — that may write to a different file that isn't symlinked.

If the MCP server needs an API key, put the key in `~/.zshrc.local` / `~/.bashrc.local` and reference it as an env var in `.mcp.json`.

**For new GCP projects:**

Edit `~/.zshrc.local` to add a new case to `gcp-switch`. Update `~/dotfiles/local.template` with the same change (using placeholder for any secrets). Copy the key file to `~/.config/gcloud/keys/` on each machine.

**End of session habit:**

```bash
cd ~/dotfiles && git status
# If changes exist:
git add . && git commit -m "description" && git push
```

If you installed something new but `git status` shows nothing changed, it went outside the dotfiles (marketplace skill or plugin). Add it to `install.sh` to make it portable.

### Adding specific things

**New slash command:**
```bash
nano ~/dotfiles/claude/.claude/commands/your-command.md
# Or ask Claude Code: "Create a /deploy command in my dotfiles"
```

**New agent:**
```bash
nano ~/dotfiles/claude/.claude/agents/your-agent.md
```

Example:
```markdown
---
name: your-agent-name
description: What it does and when to use it
tools:
  - Bash
  - Read
---

Instructions for the agent...
```

Invoke with `@your-agent-name` inside Claude Code.

**New MCP server:**
```bash
nano ~/dotfiles/claude/.mcp.json
```

Add to the mcpServers object. Restart Claude Code after adding.

**New skill (custom):**
```bash
mkdir -p ~/dotfiles/claude/.claude/skills/my-skill
nano ~/dotfiles/claude/.claude/skills/my-skill/SKILL.md
```

**New skill (marketplace — add to install.sh):**
```bash
nano ~/dotfiles/install.sh
# Add under the skills section:
# npx --yes skills add org/repo -a claude-code -g -y 2>/dev/null && \
#     echo "   ✅ Skill name" || \
#     echo "   ⚠️  Skill name failed"
```

**Change Claude Code permissions:**
```bash
nano ~/dotfiles/claude/.claude/settings.json
# Or ask Claude Code: "Add Bash(kubectl *) to the allow list"
```

**Update global instructions:**
```bash
nano ~/dotfiles/claude/.claude/CLAUDE.md
# Keep it short — loads every session. Put specialized knowledge in skills.
```

---

## What's automated vs. manual

### Automated (handled by scripts)

| Script | What it does |
|--------|-------------|
| bootstrap.sh | Installs 11 tools, detects macOS vs Linux, skips what's already present |
| install.sh | Creates symlinks, installs skills, copies local template, verifies setup |
| uninstall.sh | Removes symlinks, restores backups, optionally removes keys and skills |

All scripts are idempotent — safe to run multiple times.

### Manual (one-time per machine)

| Step | Why it can't be automated |
|------|--------------------------|
| Copy key files to ~/.config/gcloud/keys/ | Secrets can't be in git |
| Add GEMINI_API_KEY and GITHUB_PAT to local overrides | Secrets can't be in git |
| /plugin install for LSP plugins | Interactive, runs inside Claude Code |

---

## How stow works

Each top-level directory is a "package." Running `stow claude` from `~/dotfiles`
creates symlinks so `~/dotfiles/claude/.claude/settings.json` appears at
`~/.claude/settings.json`. Editing either path edits the same file.

## Config hierarchy (highest priority wins)

1. Managed/policy settings (enterprise IT)
2. Command-line flags and env vars
3. User settings (~/.claude/settings.json) ← this repo
4. Project settings (.claude/settings.json in each project repo)
5. Project local settings (.claude/settings.local.json, gitignored)

## Files that stay local (never committed)

| File | Contains |
|------|----------|
| ~/.zshrc.local / ~/.bashrc.local | GEMINI_API_KEY, GITHUB_PAT, gcp-switch function |
| ~/.config/gcloud/keys/*.json | Service account key files |
| ~/.claude/settings.local.json | Machine-specific Claude Code overrides |

local.template in the repo provides the starting point — copy and add your secrets.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| cc opens C compiler | Open a new terminal tab — alias wasn't loaded |
| claude-info wrong GCP user after switch | Run gcp-switch again |
| 401 auth error | Check GOOGLE_APPLICATION_CREDENTIALS points to valid key |
| 404 model not found | Enable Claude model in Vertex AI Model Garden |
| 429 quota exhausted | Request quota increase in GCP Console |
| @gemini fails | Run `gemini` to authenticate, check GEMINI_API_KEY |
| Skills not found | Re-run ./install.sh |
| Stow conflicts | Backup/remove blocking file, re-run ./install.sh |
| git status shows nothing but you installed something | It went outside dotfiles — add to install.sh |