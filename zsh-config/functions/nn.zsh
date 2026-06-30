function nn() {
    # Ustaw label systemu
    sudo sed -i "s/system.nixos.label = \".*\";/system.nixos.label = \"$1\";/" /etc/nixos/configuration.nix
    
    # Git add + commit + push
    git -C /etc/nixos add .
    git -C /etc/nixos commit -m "$1"
    git -C /etc/nixos push origin master
}
