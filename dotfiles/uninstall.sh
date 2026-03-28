#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# uninstall.sh — Clean removal of dotfiles symlinks and config
#
# Usage:
#   ./uninstall.sh          # remove symlinks only (safe, keeps tools)
#   ./uninstall.sh --full   # remove symlinks + keys + local overrides
# ============================================================================

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
FULL=false
[ "${1:-}" = "--full" ] && FULL=true

echo "🧹 Uninstalling dotfiles..."

# --- 1. Unstow all packages (removes symlinks) ---
echo ""
echo "Removing symlinks..."
cd "$DOTFILES_DIR"
stow -v --target="$HOME" --delete claude 2>/dev/null && echo "   ✅ claude unstowed" || echo "   ⚠️  claude: nothing to unstow"
stow -v --target="$HOME" --delete shell  2>/dev/null && echo "   ✅ shell unstowed"  || echo "   ⚠️  shell: nothing to unstow"
stow -v --target="$HOME" --delete git    2>/dev/null && echo "   ✅ git unstowed"    || echo "   ⚠️  git: nothing to unstow"

# --- 2. Restore backups if they exist ---
BACKUP_DIR=$(ls -dt "$HOME/.dotfiles-backup"/*/ 2>/dev/null | head -1)
if [ -n "$BACKUP_DIR" ]; then
    echo ""
    echo "Found backup at: $BACKUP_DIR"
    echo "Restoring original config files..."
    for file in $(find "$BACKUP_DIR" -type f); do
        relative="${file#$BACKUP_DIR}"
        target="$HOME/$relative"
        mkdir -p "$(dirname "$target")"
        cp "$file" "$target"
        echo "   ✅ Restored ~/$relative"
    done
else
    echo ""
    echo "No backups found. You may need to create fresh config files:"
    echo "   touch ~/.zshrc   # or ~/.bashrc"
    echo "   touch ~/.gitconfig"
fi

# --- 3. Full cleanup (only with --full flag) ---
if $FULL; then
    echo ""
    echo "Full cleanup..."

    # Remove local overrides
    for f in ~/.zshrc.local ~/.bashrc.local; do
        [ -f "$f" ] && rm "$f" && echo "   ✅ Removed $f"
    done

    # Remove keys
    if [ -d ~/.config/gcloud/keys ]; then
        rm -rf ~/.config/gcloud/keys
        echo "   ✅ Removed ~/.config/gcloud/keys"
    fi

    # Remove installed skills
    if [ -d ~/.claude/skills ]; then
        rm -rf ~/.claude/skills
        echo "   ✅ Removed ~/.claude/skills"
    fi

    echo ""
    echo "⚠️  Tools (claude, gcloud, node, etc.) were NOT removed."
    echo "   Uninstall those manually if needed."
fi

# --- 4. Summary ---
echo ""
echo "============================================"
echo "✅ Dotfiles uninstalled"
echo "============================================"
echo ""
if ! $FULL; then
    echo "Symlinks removed. Tools and keys untouched."
    echo "To also remove keys and local overrides: ./uninstall.sh --full"
fi
echo "To reinstall: ./install.sh && source ~/.zshrc"
