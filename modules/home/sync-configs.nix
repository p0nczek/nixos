{ pkgs, lib, ... }:
{
  home.activation.syncAllConfigs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    SECONDS=0

    for dir in "$HOME/.config/noctalia" "$HOME/.config/kitty" "$HOME/.config/btop" "$HOME/.config/niri" "$HOME/.config/zsh" "$HOME/.local/share/zinit" "$HOME/.local/share/navi/cheats/moje"; do
      [ -d "$dir" ] && find "$dir" -type l -exec sh -c 'for f; do t=$(readlink -f "$f"); rm -f "$f"; cp -f "$t" "$f"; chmod +w "$f"; done' _ {} + 2>/dev/null
      [ -d "$dir" ] && find "$dir" -type f ! -perm /u+w -exec chmod u+w {} + 2>/dev/null
    done
    for f in "$HOME/.zshrc" "$HOME/.p10k.zsh"; do
      [ -L "$f" ] && t=$(readlink -f "$f") && rm -f "$f" && cp -f "$t" "$f" && chmod +w "$f"
      [ -f "$f" ] && chmod +w "$f"
    done

    sync_config() {
      local src="$1"
      local dst="$2"
      if [ -d "$src" ]; then
        mkdir -p "$dst"
        ${pkgs.rsync}/bin/rsync -a --checksum --chmod=Du+w,Fu+w "$src/" "$dst/" \
          --out-format="[sync] %n" 2>/dev/null || true
      else
        mkdir -p "$(dirname "$dst")"
        if [ ! -e "$dst" ] || ! ${pkgs.diffutils}/bin/diff -q "$src" "$dst" >/dev/null 2>&1; then
          cp -f "$src" "$dst"
          echo "[sync] $(basename "$dst")"
        fi
        chmod +w "$dst" 2>/dev/null
      fi
    }

    sync_config "${toString ../../zshrc}" "$HOME/.zshrc" &
        sync_config "${toString ../../zsh/.p10k.zsh}" "$HOME/.p10k.zsh" &
        sync_config "${toString ../../zsh-plugins/zinit}" "$HOME/.local/share/zinit" &
        sync_config "${toString ../../zsh-config}" "$HOME/.config/zsh" &
        sync_config "${toString ../../niri}" "$HOME/.config/niri" &
        sync_config "${toString ../../kitty-config}" "$HOME/.config/kitty" &
        sync_config "${toString ../../noctalia}" "$HOME/.config/noctalia" &
        sync_config "${toString ../../btop-noctalia.theme}" "$HOME/.config/btop/themes/noctalia.theme" &
        sync_config "${toString ../../cheats}" "$HOME/.local/share/navi/cheats/moje" &
        wait
        echo "[sync] done in ''${SECONDS}s"
  '';
}
