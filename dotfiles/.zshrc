# ── Profiling (uncomment to debug startup time) ─────────────────────
# zmodload zsh/zprof

# ── Environment ─────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="nvim"
export VISUAL="nvim"
export LANG="en_US.UTF-8"

# ── History ─────────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS    # remove older duplicate entries
setopt HIST_FIND_NO_DUPS       # don't show duplicates in search
setopt HIST_REDUCE_BLANKS      # remove superfluous blanks
setopt SHARE_HISTORY           # share history between sessions
setopt INC_APPEND_HISTORY      # write immediately, not on exit
setopt EXTENDED_HISTORY        # save timestamp and duration

# ── Shell options ───────────────────────────────────────────────────
setopt AUTO_CD                 # cd by typing directory name
setopt AUTO_PUSHD              # push directories onto stack
setopt PUSHD_IGNORE_DUPS       # don't push duplicates
setopt PUSHD_SILENT            # don't print stack after pushd/popd
setopt CORRECT                 # command auto-correction
alias gh='nocorrect gh'
setopt INTERACTIVE_COMMENTS    # allow comments in interactive shell
setopt NO_BEEP                 # silence

# ── Completion system ──────────────────────────────────────────────
autoload -Uz compinit
# Only regenerate completions once per day
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Case-insensitive, partial-word, and substring completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
# Color completions using LS_COLORS
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# Disable menu for fzf-tab
zstyle ':completion:*' menu no
# Group completions by category
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
# fzf-tab previews
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' switch-group '<' '>'

# ── Key bindings ───────────────────────────────────────────────────
bindkey -e                           # emacs mode
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[[A' history-search-backward   # up arrow
bindkey '^[[B' history-search-forward    # down arrow
bindkey '^[[3~' delete-char              # delete key

# ── Zinit ──────────────────────────────────────────────────────────
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33}Installing Zinit...%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git"
fi
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# ── Annexes (required without turbo) ──────────────────────────────
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

# ── Plugins (Turbo mode — deferred for fast startup) ──────────────

# fzf-tab: must load before autosuggestions and syntax highlighting
zinit ice wait lucid
zinit light Aloxaf/fzf-tab

# Autosuggestions
zinit ice wait lucid atload'_zsh_autosuggest_start'
zinit light zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# Additional completions
zinit ice wait lucid blockf
zinit light zsh-users/zsh-completions

# Syntax highlighting (fast-syntax-highlighting > zsh-syntax-highlighting)
zinit ice wait lucid
zinit light zdharma-continuum/fast-syntax-highlighting

# Substring history search
zinit ice wait lucid
zinit light zsh-users/zsh-history-substring-search

# Git extras from OMZ (aliases: gst, gco, gp, gl, etc.)
zinit ice wait lucid
zinit snippet OMZP::git

# 1password plugin from OMZ
zinit ice wait lucid
zinit snippet OMZP::1password

# forgit: interactive git powered by fzf (gi, glo, gd, ga, etc.)
zinit ice wait lucid
zinit light wfxr/forgit

# ── Tool initialization ───────────────────────────────────────────

# Starship prompt (must be eager, not deferred)
eval "$(starship init zsh)"

# fzf keybindings and completion (Ctrl-R, Ctrl-T, Alt-C)
source <(fzf --zsh)

# zoxide (smarter cd)
eval "$(zoxide init zsh)"

# mise (universal runtime manager — replaces nvm, pyenv, rbenv)
eval "$(mise activate zsh)"

# direnv (auto-load .envrc per directory)
eval "$(direnv hook zsh)"

# atuin (SQLite shell history with sync)
eval "$(atuin init zsh)"

# difftastic
export DFT_COLOR=always

# ── Aliases ────────────────────────────────────────────────────────

# Modern replacements
alias ls="eza --icons --group-directories-first"
alias ll="eza -la --icons --group-directories-first --git"
alias lt="eza --tree --level=2 --icons"
alias la="eza -a --icons --group-directories-first"
alias cat="bat --paging=never"
alias catp="bat"   # cat with pager
alias grep="rg"
alias find="fd"
alias du="dust"
alias top="btop"
alias diff="delta"
alias help="tldr"
alias sed="sd"
alias lg="lazygit"

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias -- -="cd -"

# Git shortcuts (beyond OMZ git plugin)
alias gs="git status -sb"
alias glog="git log --oneline --graph --decorate -20"

# Safety nets
alias rm="rm -i"
alias mv="mv -i"
alias cp="cp -i"

# Quick edit
alias zshrc="$EDITOR ~/.zshrc"
alias reload="exec zsh"

# ── Bun ────────────────────────────────────────────────────────────
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# ── Compile .zshrc for faster loading ─────────────────────────────
if [[ ! -f ~/.zshrc.zwc || ~/.zshrc -nt ~/.zshrc.zwc ]]; then
  zcompile ~/.zshrc 2>/dev/null
fi

# ── Profiling output (uncomment with the top line) ────────────────
# zprof
