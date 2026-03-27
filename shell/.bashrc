# ============================================================================
# ~/.bashrc — managed via dotfiles
# ============================================================================

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# --- System defaults (keep your existing ones, these are sensible defaults) ---
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend
shopt -s checkwinsize

# --- Prompt (simple, shows git branch if in a repo) ---
parse_git_branch() {
    git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[33m\]$(parse_git_branch)\[\033[00m\]\$ '

# --- Source Claude Code / Vertex AI config ---
if [ -f "$HOME/.bash_claude" ]; then
    source "$HOME/.bash_claude"
fi

# --- Source local overrides (machine-specific, not in git) ---
if [ -f "$HOME/.bashrc.local" ]; then
    source "$HOME/.bashrc.local"
fi
