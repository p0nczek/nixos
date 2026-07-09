# ┌─┐┬  ┬┌─┐┌─┐┌─┐┌─┐
# ├─┤│  │├─┤└─┐├┤ └─┐
# ┴ ┴┴─┘┴┴ ┴└─┘└─┘└─┘
#---------------------------------------------------------------------

# Wyłączenie irytujących sugestii (autokorekty)
unsetopt CORRECT
unsetopt CORRECT_ALL

# Nix Helper (nh) aliases
alias nos="nh os switch /etc/nixos#nixos"
alias losslesscut='NIXOS_OZONE_WL=0 losslesscut --disable-gpu --no-sandbox'
alias nclean="python /etc/nixos/scripts/nclean.py"
