#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# bootstrap.sh — Cross-platform prerequisites installer
#
# Run this BEFORE cloning your dotfiles repo. It installs the minimum
# tools needed to clone and run install.sh.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/YOUR_USER/dotfiles/main/bootstrap.sh | bash
#   (or download and run manually)
#
# Supports: macOS (Intel + Apple Silicon), Linux (Ubuntu/Debian), GCP Cloud Workstations
# ============================================================================

echo "🔧 Bootstrap: detecting platform..."

# Ensure ~/.local/bin is in PATH (many tools install here: claude, uv, etc.)
export PATH="$HOME/.local/bin:$PATH"

OS="$(uname -s)"
ARCH="$(uname -m)"

echo "   OS: $OS | Arch: $ARCH"

# --- Detect platform ---
IS_MAC=false
IS_LINUX=false
IS_GCP_WORKSTATION=false

case "$OS" in
    Darwin) IS_MAC=true ;;
    Linux)  IS_LINUX=true ;;
    *)      echo "❌ Unsupported OS: $OS"; exit 1 ;;
esac

# Detect GCP Cloud Workstation (has metadata server)
if $IS_LINUX && curl -sf -m 1 "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google" &>/dev/null; then
    IS_GCP_WORKSTATION=true
    echo "   Detected: GCP Cloud Workstation"
fi

# --- Helper: check if command exists ---
has() { command -v "$1" &>/dev/null; }

# ============================================================================
# 1. Package manager
# ============================================================================
if $IS_MAC; then
    if ! has brew; then
        echo "📦 Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Add to path for this session
        if [ -f /opt/homebrew/bin/brew ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -f /usr/local/bin/brew ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
    echo "   ✅ Homebrew"
fi

if $IS_LINUX; then
    sudo apt-get update -qq 2>/dev/null || true
    echo "   ✅ apt"
fi

# ============================================================================
# 2. Git (required to clone dotfiles repo)
# ============================================================================
if ! has git; then
    echo "📦 Installing Git..."
    if $IS_MAC; then
        brew install git
    else
        sudo apt-get install -y -qq git
    fi
fi
echo "   ✅ git $(git --version | awk '{print $3}')"

# ============================================================================
# 3. Claude Code (native installer — no Node.js dependency)
# ============================================================================
if ! has claude; then
    echo "📦 Installing Claude Code (native installer)..."
    curl -fsSL https://claude.ai/install.sh | bash
fi
if has claude; then
    echo "   ✅ claude $(claude --version 2>/dev/null || echo '(installed)')"
else
    echo "   ⚠️  Claude Code installed but not in PATH. Open a new terminal."
fi

# ============================================================================
# 4. GNU Stow (for dotfiles symlinking)
# ============================================================================
if ! has stow; then
    echo "📦 Installing GNU Stow..."
    if $IS_MAC; then
        brew install stow
    else
        sudo apt-get install -y -qq stow
    fi
fi
echo "   ✅ stow"

# ============================================================================
# 5. GitHub CLI (for PR workflows, issue management)
# ============================================================================
if ! has gh; then
    echo "📦 Installing GitHub CLI..."
    if $IS_MAC; then
        brew install gh
    else
        # Official GitHub CLI install for Linux
        (type -p wget >/dev/null || sudo apt-get install -y wget) \
            && sudo mkdir -p -m 755 /etc/apt/keyrings \
            && out=$(mktemp) \
            && wget -qO "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
            && cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
            && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
            && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
            && sudo apt-get update -qq \
            && sudo apt-get install -y -qq gh \
            && rm -f "$out"
    fi
fi
echo "   ✅ gh $(gh --version 2>/dev/null | head -1 | awk '{print $3}')"

# ============================================================================
# 6. Google Cloud SDK (for Vertex AI auth)
# ============================================================================
if ! has gcloud; then
    echo "📦 Installing Google Cloud SDK..."
    if $IS_MAC; then
        brew install --cask google-cloud-sdk
    elif $IS_GCP_WORKSTATION; then
        echo "   ℹ️  gcloud should be pre-installed on GCP workstations."
        echo "   If missing, see: https://cloud.google.com/sdk/docs/install"
    else
        # Debian/Ubuntu
        sudo apt-get install -y -qq apt-transport-https ca-certificates gnupg curl
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg 2>/dev/null
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
        sudo apt-get update -qq && sudo apt-get install -y -qq google-cloud-cli
    fi
fi
if has gcloud; then
    echo "   ✅ gcloud $(gcloud --version 2>/dev/null | head -1 | awk '{print $NF}')"
else
    echo "   ⚠️  gcloud not found. Install manually: https://cloud.google.com/sdk/docs/install"
fi

# ============================================================================
# 7. Node.js + npm (needed for npx skills, prettier, MCP servers)
# ============================================================================
if ! has node; then
    echo "📦 Installing Node.js..."
    if $IS_MAC; then
        brew install node
    else
        # NodeSource LTS
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - 2>/dev/null
        sudo apt-get install -y -qq nodejs
    fi
fi
if has node; then
    echo "   ✅ node $(node --version)"
    echo "   ✅ npm $(npm --version)"
else
    echo "   ⚠️  Node.js install failed. Install manually."
fi

# ============================================================================
# 8. Python 3 + pip (for ADK, black formatter, etc.)
# ============================================================================
if ! has python3; then
    echo "📦 Installing Python 3..."
    if $IS_MAC; then
        brew install python
    else
        sudo apt-get install -y -qq python3 python3-pip python3-venv
    fi
fi
if has python3; then
    echo "   ✅ python3 $(python3 --version | awk '{print $2}')"
fi

# ============================================================================
# 9. uv (fast Python package manager — needed for ADK MCP server)
# ============================================================================
if ! has uv; then
    echo "📦 Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi
if has uv; then
    echo "   ✅ uv $(uv --version 2>/dev/null | awk '{print $2}')"
fi

# ============================================================================
# 10. jq (used by hooks in settings.json)
# ============================================================================
if ! has jq; then
    echo "📦 Installing jq..."
    if $IS_MAC; then
        brew install jq
    else
        sudo apt-get install -y -qq jq
    fi
fi
echo "   ✅ jq"

# ============================================================================
# 11. Gemini CLI (sub-agent for codebase analysis + ADK testing)
# ============================================================================
if ! has gemini; then
    echo "📦 Installing Gemini CLI..."
    if $IS_MAC; then
        brew install gemini-cli 2>/dev/null || npm install -g @anthropic-ai/gemini-cli 2>/dev/null || {
            echo "   ℹ️  Auto-install failed. Try: npm install -g @google/gemini-cli"
            echo "   Or: https://ai.google.dev/gemini-api/docs/gemini-cli"
        }
    else
        npm install -g @google/gemini-cli 2>/dev/null || {
            echo "   ℹ️  Gemini CLI install failed. Try manually:"
            echo "   npm install -g @google/gemini-cli"
        }
    fi
fi
if has gemini; then
    echo "   ✅ gemini CLI"
else
    echo "   ⚠️  Gemini CLI not found. Install manually, then run: gemini (to authenticate)"
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "✅ Bootstrap complete! Prerequisites installed."
echo ""
echo "Next steps:"
echo "  1. git clone git@github.com:YOUR_USER/dotfiles.git ~/dotfiles"
echo "  2. cd ~/dotfiles && ./install.sh"
echo "  3. source ~/.bashrc"
echo ""
if ! has gcloud || ! gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null | head -1 | grep -q '.'; then
    echo "  4. gcloud auth login"
    echo "  5. gcloud auth application-default login"
    echo "  6. gcloud config set project YOUR_PROJECT_ID"
fi
