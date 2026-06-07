# ┌─┐┬  ┬┌─┐┌─┐┌─┐┌─┐
# ├─┤│  │├─┤└─┐├┤ └─┐
# ┴ ┴┴─┘┴┴ ┴└─┘└─┘└─┘
#---------------------------------------------------------------------

# Szybki commit dla zmian w NixOS
ncom() {
    local target=$1
    local msg=${2:-"update: $1"}
    local repo="/etc/nixos"
    
    local SUDO="/run/current-system/sw/bin/sudo"
    local GIT="/run/current-system/sw/bin/git"

    if [[ -z "$target" ]]; then
        echo "❌ Podaj co zmieniłeś (np. kitty, niri, configuration.nix)"
        return 1
    fi

    local path=$(find "$repo" -maxdepth 2 -name "$target" -o -name "$target-config" | head -n 1)

    if [[ -n "$path" ]]; then
        $SUDO $GIT -C "$repo" add "$path"
        $SUDO $GIT -C "$repo" commit -m "$msg"
        echo "✅ Zcommitowano: $target"
    else
        echo "❌ Nie znaleziono  w /etc/nixos"
    fi
}

# NixOS Helpers
# alias ns="sudo nixos-rebuild switch --flake /etc/nixos#nixos"
alias nstat="git -C /etc/nixos status"
alias nlog="git -C /etc/nixos log --oneline -n 10"
alias ndiff="git -C /etc/nixos diff"

# Wyłączenie irytujących sugestii (autokorekty)
unsetopt CORRECT
unsetopt CORRECT_ALL

# Nix Helper (nh) aliases
alias nos="nh os switch"
alias nhs="nh home switch"
alias ncu="nh os switch --update"
alias nclean="nh clean all"
