# ============================================================================
# ~/.zshrc — managed via dotfiles (macOS)
# ============================================================================

# --- History ---
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# --- Prompt (simple, shows git branch) ---
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%F{yellow}${vcs_info_msg_0_}%f$ '

# --- Homebrew (Apple Silicon vs Intel) ---
if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# --- Source Claude Code / Vertex AI config (shared with bash) ---
if [ -f "$HOME/.bash_claude" ]; then
    source "$HOME/.bash_claude"
fi

# --- Source local overrides (machine-specific, not in git) ---
if [ -f "$HOME/.zshrc.local" ]; then
    source "$HOME/.zshrc.local"
fi
