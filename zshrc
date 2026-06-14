#!/usr/bin/env zsh
# ┬ ┬┌─┐┬  ┌─┐┌─┐┌┬┐┌─┐  ┌┬┐┌─┐  ┌─┐┌─┐┬ ┬
# │││├┤ │  │  │ ││││├┤    │ │ │  ┌─┘└─┐├─┤
# └┴┘└─┘┴─┘└─┘└─┘┴ ┴└─┘   ┴ └─┘  └─┘└─┘┴ ┴
#---------------------------------------------------------------------
# Copyright (c) 2025 maarutan \ Marat Arzymatov. All Rights Reserved.
# https://github.com/maarutan

# -- Welcome to Zsh! --

# zmodload zsh/zprof

zsh-newuser-install() { :; }
export ZSH_CONFIG="$HOME/.config/zsh"  # Config directory
export ZSH_PLUGINS_MANAGER="zinit"     # Plugin manager
eval "$(atuin init zsh)"
source "$ZSH_CONFIG/init.zsh"          # Load main config
# Navi widget (Ctrl+G)
source <(navi widget zsh)





# iNiR launcher PATH
case ":$PATH:" in
  *:"/home/shin/.local/bin":*) ;;
  *) export PATH="/home/shin/.local/bin:$PATH" ;;
esac
# end iNiR launcher PATH


# iNiR environment
export INIR_VENV="/home/shin/.local/state/quickshell/.venv"
export ILLOGICAL_IMPULSE_VIRTUAL_ENV="$INIR_VENV"
# Apply terminal color sequences (Material You from wallpaper)
if [ -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt ]; then
  cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
fi
# end iNiR

alias yay='paru'
alias nano='micro'
