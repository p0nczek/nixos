function nn() {
    if [ -z "$1" ]; then
        echo "Usage: nn <new_label>"
        return 1
    fi

    # 1. Update the label in configuration.nix
    sudo sed -i "s/system.nixos.label = \".*\";/system.nixos.label = \"$1\";/" /etc/nixos/configuration.nix
    echo "NixOS label updated to: $1"

    # 2. Git operations
    pushd /etc/nixos > /dev/null
    sudo git add .
    sudo git commit -m "$1"
    popd > /dev/null

    echo "Changes committed with message: $1"
}
