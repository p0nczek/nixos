# Vicinae na NixOS + Zen Browser — Kompletny Przewodnik

> *"Prawda jest w kodzie. Jeśli nie ma tego w `/etc/nixos`, to nie istnieje."*  
> Dokumentacja żywa. Ostatnia aktualizacja: 2026-07-09

---

## 1. Czym jest Vicinae i po co to robić

Vicinae to **launcher desktopowy** (alternatywa dla Rofi/dmenu) z natywną integracją przeglądarki. Pozwala:
- wyszukiwać i przełączać karty z **Zena** (lub Firefoksa) bez dotykania myszy,
- przeglądać **historię** i **zakładki**,
- korzystać z **clipboard history**,
- uruchamiać aplikacje i skrypty (tryb `dmenu`).

---

## 2. Instalacja deklaratywna (Flakes + Home Manager)

### 2.1 Dodaj input do `flake.nix`

```nix
inputs = {
  # ... twoje obecne inputy ...

  vicinae = {
    url = "github:vicinaehq/vicinae";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

> **Uwaga:** Pakiet `vicinae` w `nixpkgs` (0.21.0) **nie zawiera** `vicinae-browser-link`.  
> Tylko oficjalny flake buduje binarkę do komunikacji z przeglądarką.

### 2.2 Dodaj cache Vicinae (opcjonalnie, przyspiesza build)

`configuration.nix`:
```nix
nix.settings = {
  substituters = [ "https://vicinae.cachix.org" ];
  trusted-public-keys = [ "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc=" ];
};
```

### 2.3 Importuj moduł HM w `home.nix`

```nix
{ pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.noctalia.homeModules.default
    inputs.vicinae.homeManagerModules.default  # ⬅️ KLUCZOWA LINIA
  ];

  # Włącza pakiet + systemd service + native messaging
  programs.vicinae = {
    enable = true;
    systemd.enable = true;
  };

  # ... reszta home.nix ...
}
```

**NIE rób tego ręcznie** (moduł HM załatwi to sam):
- `systemd.user.services.vicinae` ❌
- `home.file".mozilla/native-messaging-hosts/..."` ❌  
- `home.packages = [ pkgs.vicinae ]` ❌ (moduł instaluje pakiet sam)

---

## 3. Skróty klawiszowe w Niri

`niri/cfg/keybinds.kdl`:
```kdl
// Główny launcher
Mod+P hotkey-overlay-title="Vicinae" {
    spawn "vicinae" "toggle"
}

// Tryb dmenu (pipe menu, jak klasyczne dmenu)
Mod+Shift+P hotkey-overlay-title="Vicinae dmenu" {
    spawn "vicinae" "dmenu"
}
```

---

## 4. Problemy napotkane i rozwiązania

### 4.1 `attribute 'vicinae' missing` — zły sposób dostępu do pakietu

**Objaw:**
```
error: attribute 'vicinae' missing
at /etc/nixos/home.nix:4:16:
  vicinaePkg = inputs.vicinae.packages.${pkgs.system}.vicinae;
```

**Przyczyna:** Oficjalny flake Vicinae nie eksportuje `packages.x86_64-linux.vicinae`.  
Eksportuje **Home Manager module** (`homeManagerModules.default`).

**Rozwiązanie:** Nie używaj `inputs.vicinae.packages...`. Użyj `programs.vicinae` po zaimportowaniu modułu.

---

### 4.2 Brak `vicinae-browser-link` — rozszerzenie nie widzi Vicinae

**Objaw:**
```
which vicinae-browser-link
vicinae-browser-link not found
```

**Przyczyna:** Pakiet `pkgs.vicinae` z nixpkgs nie buduje targetu browser-link.  
Oficjalny flake buduje go w `/libexec/vicinae/vicinae-browser-link`.

**Rozwiązanie:** Użyć oficjalnego flake (patrz pkt 2.1) i modułu HM.  
Jeśli ktoś potrzebuje ręcznie naprawić ścieżkę w native messaging manifestu:
```json
{
  "name": "com.vicinae.vicinae",
  "path": "/nix/store/XXX-vicinae-0.23.0/libexec/vicinae/vicinae-browser-link",
  "type": "stdio",
  "allowed_extensions": [ "firefox@vicinae.com" ]
}
```

> **Zen czyta native messaging z `~/.mozilla/native-messaging-hosts/`**,  
> **NIE** z `~/.zen/`. To znany bug/feature Zena.

---

### 4.3 Brak faviconów (znaczków) przy kartach z przeglądarki

**Objaw:** Karty się pojawiają, ale bez ikonek YouTube, GitHub, Steam itp.

**Przyczyna:** Brak Qt6 image plugins do renderowania PNG/SVG.

**Rozwiązanie:** `home.nix`:
```nix
home.packages = with pkgs; [
  qt6Packages.qtimageformats
  qt6Packages.qtsvg
];
```

---

### 4.4 Historia i zakładki nie działają — "No Firefox profiles found"

**Objaw:**
- Komenda `history` w Vicinae pokazuje się, ale lista jest pusta.
- Komunikat: *"No Firefox history found / No Firefox profiles detected"*.

**Przyczyna:** Błędnie ustawiony **Profile Directory** w ustawieniach Vicinae.  
Vicinae szuka pliku **`profiles.ini`** w katalogu nadrzędnym, nie bezpośrednio w katalogu profilu.

**Rozwiązanie:**

1. Sprawdź gdzie Zen trzyma profil:
   ```bash
   cat ~/.config/zen/profiles.ini
   ```
   Powinno zwrócić:
   ```ini
   [Profile0]
   Name=Default Profile
   IsRelative=1
   Path=swafwveg.Default Profile
   Default=1
   ```

2. W ustawieniach Vicinae (Firefox integration → Profile Directory) wpisz:
   ```
   .config/zen/
   ```
   **NIE** `.config/zen/swafwveg.Default Profile`.

3. Restart serwera:
   ```bash
   systemctl --user restart vicinae
   ```

---

## 5. Sprawdź czy wszystko działa

```bash
# 1. Serwer działa?
systemctl --user status vicinae

# 2. Komunikacja z przeglądarką?
vicinae ping

# 3. Native messaging manifest istnieje?
ls ~/.mozilla/native-messaging-hosts/com.vicinae.vicinae.json

# 4. Browser link jest w PATH?
ls /nix/store/*-vicinae-*/libexec/vicinae/vicinae-browser-link

# 5. Qt plugins są?
ls ~/.nix-profile/lib/qt-6/plugins/imageformats/
```

---

## 6. Uprawnienia rozszerzenia w Zen (ważne!)

Po instalacji rozszerzenia Vicinae w Zen (`about:addons`):
- **Access browser tabs** — włączone (bez tego nie ma kart)
- **Access your browsing history** — włączone (bez tego nie ma historii)
- **Access your bookmarks** — włączone (bez tego nie ma zakładek)

Jeśli któregoś brakuje, usuń rozszerzenie i zainstaluj ponownie.

---

## 7. Finalny stan systemu

| Komponent | Status |
|-----------|--------|
| Vicinae launcher (`Mod+P`) | ✅ Działa |
| Tryb dmenu (`Mod+Shift+P`) | ✅ Działa |
| Karty z Zena w launcherze | ✅ Działa |
| Favicony przy kartach | ✅ Działa |
| Historia przeglądarki (`history`) | ✅ Działa |
| Zakładki (`bookmarks`) | ✅ Działa |
| Clipboard history | ✅ Działa natywnie |

---

## 8. Złote zasady na przyszłość

1. **Nie używaj `pkgs.vicinae` z nixpkgs** jeśli chcesz browser integration.  
   Używaj oficjalnego flake + modułu HM.
2. **Zen czyta native messaging z `~/.mozilla/`**, nie z `~/.zen/`.
3. **Profile Directory** w Vicinae = katalog z `profiles.ini`, nie sam profil.
4. **Po zmianie ustawień Vicinae** zrestartuj serwer: `systemctl --user restart vicinae`.
5. **Po zmianach w Niri** nie trzeba rebuildować NixOS — `niri msg action reload-config` wystarczy.  
   Po zmianach w `home.nix` — `nos` jest wymagany.

---

*Wygenerowano dla systemu `shin@nixos` • NixOS 25.11 • Flakes + Home Manager • Niri + Zen Browser + Vicinae*
