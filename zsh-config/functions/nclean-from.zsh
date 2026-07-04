function nclean-from() {
    local target_label="$1"
    local profile="/nix/var/nix/profiles/system"
    
    if [[ -z "$target_label" ]]; then
        echo "Użycie: nclean-from <label>"
        echo "Przykład: nclean-from monitors"
        return 1
    fi
    
    # Pobierz listę generacji z profilu systemowego
    local gens=$(nix-env -p "$profile" --list-generations 2>/dev/null)
    
    # Znajdź najniższy numer generacji z danym labelem
    local min_gen=$(echo "$gens" | grep -E "\s${target_label}\s*$" | awk '{print $1}' | sort -n | head -1)
    
    if [[ -z "$min_gen" ]]; then
        echo "Nie znaleziono generacji z labelem: $target_label"
        return 1
    fi
    
    # Policz ile generacji jest od tego numeru wzwyż (włącznie)
    local keep=$(echo "$gens" | awk -v mg="$min_gen" '$1 >= mg {count++} END {print count}')
    local total=$(echo "$gens" | wc -l)
    
    echo "Label '$target_label' zaczyna się od generacji $min_gen"
    echo "Zostawiam $keep z $total generacji (od $min_gen do teraz)"
    echo "Usuwam wszystko starsze niż $min_gen"
    echo ""
    
    # Dry run najpierw
    nh clean all --keep $keep --dry
    
    echo ""
    read -q "REPLY?Potwierdź usunięcie [y/N] "
    echo ""
    if [[ "$REPLY" == "y" ]]; then
        nh clean all --keep $keep
    fi
}
