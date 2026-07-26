nn() {
    if [[ -z "$1" ]]; then
        echo "Usage: nn <opis>"
        return 1
    fi

    # sanityzacja pod system.nixos.label — dozwolone tylko [a-zA-Z0-9:_-]
    local label
    label=$(echo "$1" | tr -c 'a-zA-Z0-9_.:-' '_')

    sudo sed -i "s/system\.nixos\.label = \".*\";/system.nixos.label = \"${label}\";/" /etc/nixos/configuration.nix

    git -C /etc/nixos add .
    git -C /etc/nixos commit -m "$1"
    git -C /etc/nixos push
}
