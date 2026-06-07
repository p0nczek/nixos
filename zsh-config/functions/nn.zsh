function nn() {
    if [ -z "$1" ]; then
        echo "Usage: nn <new_label>"
        return 1
    fi

    # 1. Prepare label (replace spaces with hyphens using zsh parameter expansion)
    local CLEAN_LABEL="${1// /-}"
    CLEAN_LABEL="${CLEAN_LABEL//[^a-zA-Z0-9:_\.-]/}"

    # 2. Update the label in configuration.nix
    sudo sed -i "s/system.nixos.label = \".*\";/system.nixos.label = \"$CLEAN_LABEL\";/" /etc/nixos/configuration.nix
    echo "NixOS label updated to: $CLEAN_LABEL"

    # 3. Git operations
    pushd /etc/nixos > /dev/null
    sudo git add .
    sudo git commit -m "$1"
    popd > /dev/null

    echo "Changes committed with message: $1"
}
