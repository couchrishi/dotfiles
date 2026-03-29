#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Dotfiles installer — Cross-platform (macOS + Linux)
# Claude Code + Vertex AI + Google ADK
#
# Prerequisites: run bootstrap.sh first on a fresh machine.
# Usage: cd ~/dotfiles && ./install.sh
# ============================================================================

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
OS="$(uname -s)"
echo "📂 Dotfiles: $DOTFILES_DIR ($OS)"

# Ensure ~/.local/bin is in PATH (claude, uv, etc. install here)
export PATH="$HOME/.local/bin:$PATH"

has() { command -v "$1" &>/dev/null; }

# --- 1. Check critical prerequisites ---
MISSING=()
has git    || MISSING+=("git")
has stow   || MISSING+=("stow")
has claude || MISSING+=("claude")
has jq     || MISSING+=("jq")

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "❌ Missing prerequisites: ${MISSING[*]}"
    echo "   Run bootstrap.sh first: bash bootstrap.sh"
    exit 1
fi

# --- 2. Handle existing files (backup, don't clobber) ---
echo ""
echo "🔍 Checking for existing config files..."
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
NEEDS_BACKUP=false

for file in .claude/settings.json .claude/CLAUDE.md .mcp.json .bashrc .bash_claude .gitconfig; do
    target="$HOME/$file"
    # Only backup if it's a real file (not already a symlink from stow)
    if [ -f "$target" ] && [ ! -L "$target" ]; then
        NEEDS_BACKUP=true
        mkdir -p "$BACKUP_DIR/$(dirname "$file")"
        cp "$target" "$BACKUP_DIR/$file"
        rm "$target"
        echo "   Backed up: ~/$file → $BACKUP_DIR/$file"
    fi
done

if $NEEDS_BACKUP; then
    echo "   Backups saved to: $BACKUP_DIR"
fi

# --- 3. Ensure directories exist ---
mkdir -p "$HOME/.claude"

# --- 4. Stow packages (creates symlinks) ---
echo ""
echo "🔗 Stowing packages..."
cd "$DOTFILES_DIR"

stow -v --target="$HOME" --restow claude 2>&1 | grep -v "BUG" || true
stow -v --target="$HOME" --restow shell  2>&1 | grep -v "BUG" || true
stow -v --target="$HOME" --restow git    2>&1 | grep -v "BUG" || true

echo "   ✅ Symlinks created"

# --- 5. Install skills ---
echo ""
echo "📦 Installing skills..."
if has npx; then
    # Official Google ADK skills
    npx --yes skills add google/adk-docs -a claude-code -g -y 2>/dev/null && \
        echo "   ✅ Google ADK skills" || \
        echo "   ⚠️  ADK skills failed (retry: npx skills add google/adk-docs -a claude-code -g -y)"

    # Frontend Slides (interactive HTML presentations)
    npx --yes skills add zarazhangrui/frontend-slides -a claude-code -g -y 2>/dev/null && \
        echo "   ✅ Frontend Slides (HTML presentations)" || \
        echo "   ⚠️  Frontend Slides failed (retry: npx skills add zarazhangrui/frontend-slides -a claude-code -g -y)"

    # Office document skills (pptx, docx, xlsx, pdf)
    npx --yes skills add tfriedel/claude-office-skills -a claude-code -g -y 2>/dev/null && \
        echo "   ✅ Office skills (pptx/docx/xlsx/pdf)" || \
        echo "   ⚠️  Office skills failed (retry: npx skills add tfriedel/claude-office-skills -a claude-code -g -y)"
else
    echo "   ⚠️  npx not found — install Node.js, then run install.sh again"
fi

# --- 6. Install LSP plugins ---
echo ""
echo "📦 Installing LSP plugins..."
if has claude; then
    claude plugin marketplace add anthropics/claude-plugins-official 2>/dev/null || true
    claude plugin install pyright-lsp@claude-plugins-official 2>/dev/null && \
        echo "   ✅ Python LSP (pyright)" || echo "   ⚠️  pyright LSP failed"
    claude plugin install typescript-lsp@claude-plugins-official 2>/dev/null && \
        echo "   ✅ TypeScript LSP" || echo "   ⚠️  typescript LSP failed"
else
    echo "   ⚠️  Claude Code not found — install LSP plugins manually"
fi


# --- 7. Verify Vertex AI setup ---
echo ""
echo "🔍 Checking GCP / Vertex AI..."

if has gcloud; then
    PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
    [ -n "$PROJECT" ] && echo "   ✅ GCP project: $PROJECT" || echo "   ⚠️  No GCP project set. Run: gcloud config set project YOUR_PROJECT_ID"

    ADC_FILE="${GOOGLE_APPLICATION_CREDENTIALS:-$HOME/.config/gcloud/application_default_credentials.json}"
    [ -f "$ADC_FILE" ] && echo "   ✅ Application Default Credentials found" || echo "   ⚠️  No ADC. Run: gcloud auth application-default login"
else
    echo "   ⚠️  gcloud not found. Run bootstrap.sh or install manually."
fi

# --- 8. Check MCP server dependencies ---
echo ""
echo "🔍 Checking MCP server dependencies..."
has uvx && echo "   ✅ uvx (for adk-docs MCP server)" || echo "   ⚠️  uvx not found. Run: curl -LsSf https://astral.sh/uv/install.sh | sh"

# --- 9. Check Gemini CLI ---
echo ""
echo "🔍 Checking Gemini CLI (sub-agent)..."
if has gemini; then
    echo "   ✅ gemini CLI installed"
    echo "   ℹ️  Gemini analyzer sub-agent at: ~/.claude/agents/gemini-analyzer.md"
    echo "   Usage: @gemini-analyzer inside Claude Code"
else
    echo "   ⚠️  Gemini CLI not found. Run bootstrap.sh or: npm install -g @google/gemini-cli"
fi

# --- 10. Check formatters (used by auto-format hook) ---
echo ""
echo "🔍 Checking formatters..."
has npx                                          && echo "   ✅ prettier (via npx)"
python3 -m black --version &>/dev/null 2>&1      && echo "   ✅ black" || echo "   ℹ️  black: pip install black"
has gofmt                                        && echo "   ✅ gofmt"
has terraform                                    && echo "   ✅ terraform fmt"

# --- 11. Set up local overrides (service account keys, project switcher) ---
echo ""
SHELL_NAME=$(basename "$SHELL")
if [ "$SHELL_NAME" = "zsh" ]; then
    LOCAL_FILE="$HOME/.zshrc.local"
    SHELL_RC="~/.zshrc"
else
    LOCAL_FILE="$HOME/.bashrc.local"
    SHELL_RC="~/.bashrc"
fi

if [ ! -f "$LOCAL_FILE" ]; then
    echo "🔑 Setting up local overrides..."
    if [ -d "$HOME/.config/gcloud/keys" ] && ls "$HOME/.config/gcloud/keys"/*.json &>/dev/null; then
        echo "   Found key files in ~/.config/gcloud/keys/:"
        ls "$HOME/.config/gcloud/keys"/*.json | while read f; do echo "     $(basename "$f")"; done
        echo ""
        echo "   Copying template → $LOCAL_FILE"
        cp "$DOTFILES_DIR/local.template" "$LOCAL_FILE"
        echo "   ⚠️  Edit $LOCAL_FILE to match your key filenames and project IDs"
    else
        echo "   No key files found in ~/.config/gcloud/keys/"
        echo "   To set up service account auth:"
        echo "     1. mkdir -p ~/.config/gcloud/keys"
        echo "     2. Copy your .json key files there"
        echo "     3. cp $DOTFILES_DIR/local.template $LOCAL_FILE"
        echo "     4. Edit $LOCAL_FILE with your actual values"
    fi
else
    echo "🔑 Local overrides: $LOCAL_FILE already exists (skipping)"
fi

# --- 12. Summary ---
echo ""
echo "============================================"
echo "✅ Dotfiles installed!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  source $SHELL_RC"
echo "  claude-info                  # verify Vertex AI config"
echo "  cc                           # start Claude Code"
echo ""
echo "Inside Claude Code — install LSP plugins (one-time):"
echo "  /plugin install pyright-lsp@claude-plugins-official"
echo "  /plugin install typescript-lsp@claude-plugins-official"
echo "  /plugin install gopls-lsp@claude-plugins-official"
