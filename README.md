# Dotfiles — GCP Cloud Workstation + Claude Code (Vertex AI)

Portable development environment config using GNU Stow.

## Quick Start

```bash
# On a new workstation:
git clone git@github.com:YOUR_USER/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
source ~/.bashrc

# Authenticate with GCP (one-time):
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID

# Verify:
claude-info        # Show Vertex AI config
cc                 # Start Claude Code
/doctor            # Health check inside Claude Code
```

## After First Launch — Install LSP Plugins

LSP gives Claude semantic code understanding (~50ms lookups vs 30-60s grep).
Run these inside Claude Code for your languages:

```
/plugin install typescript-lsp@claude-plugins-official
/plugin install pyright-lsp@claude-plugins-official
/plugin install gopls-lsp@claude-plugins-official
/plugin install rust-analyzer-lsp@claude-plugins-official
```

Restart Claude Code after installing. You need the language server binaries
on your system too (the plugin will tell you if they're missing).

## Structure

```
dotfiles/
├── install.sh                # Bootstrap script
├── claude/                   # → stowed to ~/
│   ├── .claude/
│   │   ├── settings.json     # Permissions, LSP, hooks
│   │   ├── CLAUDE.md         # Global instructions (loaded every session)
│   │   └── commands/         # Custom /slash commands
│   │       ├── review.md
│   │       └── plan.md
│   └── .mcp.json             # Global MCP server config
├── shell/                    # → stowed to ~/
│   ├── .bashrc               # Main shell config
│   └── .bash_claude          # Vertex AI env vars & aliases
├── git/                      # → stowed to ~/
│   └── .gitconfig
└── .gitignore
```

## What's Included

### Hooks (deterministic, 100% enforced)

| Hook | Type | What it does |
|------|------|-------------|
| Block push to main | PreToolUse | Prevents `git push` to main/master, tells Claude to use feature branches |
| Auto-format | PostToolUse | Runs the right formatter after every file edit (prettier, black, gofmt, terraform fmt) |

### Permissions

Generous allowlist for common dev tools (git, npm, python, go, docker, gcloud,
terraform) with explicit denies on sensitive files (.env, credentials, keys)
and destructive commands (rm -rf, sudo).

### CLAUDE.md

Short, opinionated global instructions. Covers: be direct, plan before coding,
use gh CLI for GitHub, use gcloud for GCP, never hardcode secrets, run tests.
**Customize this for your actual coding standards.**

## How Stow Works

Each top-level directory is a "package." Running `stow claude` from `~/dotfiles`
creates symlinks so `~/dotfiles/claude/.claude/settings.json` appears at
`~/.claude/settings.json`. Same for shell and git packages.

## Customization

- **Machine-specific overrides:** Create `~/.bashrc.local` (not tracked in git)
- **Project-specific:** Add `.claude/settings.json` and `CLAUDE.md` in each project repo
- **Add MCP servers:** Edit `claude/.mcp.json`
- **Add skills:** Create `claude/.claude/skills/your-skill/SKILL.md`
- **Add agents:** Create `claude/.claude/agents/your-agent.md`

## Adding Skills Later

Skills load on-demand (~100 tokens to scan, <5k when activated). They don't
bloat every session like CLAUDE.md does. Add them when you feel the pain of
repeating yourself.

```bash
# Install from marketplace (inside Claude Code):
/plugin install frontend-design@anthropics/skills

# Or create your own:
mkdir -p ~/dotfiles/claude/.claude/skills/my-api-conventions/
# Write a SKILL.md with YAML frontmatter + instructions
# Then re-stow: cd ~/dotfiles && stow claude
```

## Key Aliases

| Alias | Command |
|-------|---------|
| `cc`  | `claude --dangerously-skip-permissions` |
| `ccc` | `claude --continue` |
| `ccr` | `claude --resume` |
| `ccp` | `claude -p` (print/one-shot mode) |
| `claude-info` | Show current Vertex AI config |

## Config Hierarchy (highest priority wins)

1. Managed/policy settings (enterprise IT)
2. Command-line flags and env vars
3. User settings (`~/.claude/settings.json`) ← **this repo**
4. Project settings (`.claude/settings.json` in repo)
5. Project local settings (`.claude/settings.local.json`, gitignored)

Settings merge across levels. Higher scopes override lower for same keys.
