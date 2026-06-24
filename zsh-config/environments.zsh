#!/usr/bin/env zsh
# ┌─┐┌┐┌┬  ┬┬┬─┐┌─┐┌┐┌┌┬┐┌─┐┌┐┌┌┬┐┌─┐
# ├┤ │││└┐┌┘│├┬┘│ │││││││├┤ │││ │ └─┐
# └─┘┘└┘ └┘ ┴┴└─└─┘┘└┘┴ ┴└─┘┘└┘ ┴ └─┘
#--------------------------------------------
# (c) maarutan   https://github.com/maarutan

# ---- Options ----
#- set
setopt INTERACTIVE_COMMENTS
setopt AUTO_CD
setopt HIST_FCNTL_LOCK
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt INC_APPEND_HISTORY
setopt HIST_REDUCE_BLANKS
setopt hist_save_no_dups
setopt CORRECT
setopt CORRECT_ALL
#- unset
unsetopt AUTO_REMOVE_SLASH
unsetopt HIST_EXPIRE_DUPS_FIRST
unsetopt EXTENDED_HISTORY

# ---- Path ----
export GOPATH="$HOME/.config/go"

LIST_PATH=(
    "$HOME/.local/bin"
    "$HOME/.local/share/nvim/mason/bin"
    "$HOME/.npm-global/bin"
    "$HOME/.cargo/bin"
)
export PATH="$(IFS=:; echo "${LIST_PATH[*]}"):$PATH"

# ---- Autoload
autoload -U compinit; compinit
zmodload zsh/complist
autoload -Uz edit-command-line; zle -N edit-command-line

# ---- Software specific ----
export EDITOR="nvim"
export VISUAL="nvim"
export QT_QPA_PLATFORMTHEME=qt5ct

# History settings
HISTFILE="$HOME/.config/zsh/.history"
HISTSIZE=100000
SAVEHIST=100000

# ---- Initialize tools ----
eval "$(zoxide init zsh)"           # Initialize zoxide

# ----- Completion Configuration -----
zstyle ":completion:*:*:*:*:*" menu select   # enable menu at completion
zstyle ":completion:*" use-cache yes         # save completion in cache for fast review
zstyle ":completion:*" special-dirs true     # review dir
zstyle ":completion:*" squeeze-slashes true  # squeeze slashes
zstyle ":completion:*" file-sort change      # last file check if you change -----------------------------
zstyle ":completion:*" matcher-list "m:{[:lower:][:upper:]}={[:upper:][:lower:]}" "r:|=*" "l:|=* r:|=*" # |
zstyle ':completion:*:descriptions' format '%b%B%d'     # font type for completion
zstyle ':completion:*:messages' format '%b%B%U%S%m%u%s' # font type for completion
zstyle ':completion:*:warnings' format '%b%B%U%S%w%u%s' # font type for completion

export FZF_DEFAULT_OPTS="
--height=100% \
    --border \
    --preview-window=right:60%:wrap \
    --preview='
if [[ -d {} ]]; then
    eza --tree --level=3 --icons "{}"
elif [[ {} =~ \.(jpg|jpeg|png|gif|bmp|webp|tiff)$ ]]; then
    chafa -s ${FZF_PREVIEW_COLUMNS:-"$((COLUMNS/2))"}x${FZF_PREVIEW_LINES:-"$((LINES/2))"} "{}"
else
    bat --style=numbers --color=always "{}" || cat "{}"
fi
'
"


