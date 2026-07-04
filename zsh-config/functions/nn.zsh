function nn() {
    sed -i "s/system.nixos.label = \".*\";/system.nixos.label = \"$1\";/" /etc/nixos/configuration.nix
    git -C /etc/nixos add .
    git -C /etc/nixos commit -m "$1"
    git -C /etc/nixos push
}
