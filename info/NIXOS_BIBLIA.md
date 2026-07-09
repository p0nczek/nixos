# 📘 BIBLIA NIXOS — Kompletny Przewodnik Systemu `shin@nixos`

> *"Prawda jest w kodzie. Jeśli nie ma tego w `/etc/nixos`, to nie istnieje."*

---

## 1. FILOZOFIA — Dlaczego NixOS?

### 1.1 Deklaratywność
W tradycyjnym Linuksie instalujesz program przez `sudo apt install firefox`. Po miesiącu nie pamiętasz co zainstalowałeś, w jakiej wersji, i dlaczego. W NixOS **cały stan systemu** jest opisany w plikach `.nix`. Jeśli znasz stan plików, znasz stan systemu.

### 1.2 Reprodukowalność
Dzięki `flake.lock` możesz sklonować repo `/etc/nixos` na nowy komputer, odpalić `nos`, i mieć **identyczny** system — w tym samym dniu, za rok, na innym sprzęcie.

### 1.3 Atomowość
Każda zmiana tworzy nową generację systemu. Nie działa? Reboot i wybierz poprzednią z bootloadera. Nie ma "częściowych aktualizacji" które zostawiają system w stanie pośrednim.

### 1.4 Hermetyzacja
Programy nie widzą się nawzajem, chyba że jawnie zadeklarujesz zależność. Nie ma `pip install` który psuje systemowe Pythony. Nie ma `npm install -g` który zalewa `/usr/local`.

---

## 2. ARCHITEKTURA SYSTEMU — Wielki Obraz

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              TWÓJ BRAIN / YOU                               │
│  Edytujesz pliki w /etc/nixos  →  nn "opis"  →  nos  →  SYSTEM DZIAŁA     │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           /etc/nixos/ (GIT REPO)                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  flake.nix  │  │configuration│  │  home.nix   │  │   hardware-conf.nix │  │
│  │             │  │    .nix     │  │             │  │                     │  │
│  │ • Inputs    │  │ • Boot      │  │ • Zsh       │  │ • Partycje          │  │
│  │ • Outputs   │  │ • NVIDIA    │  │ • Dotfiles  │  │ • Kernel modules    │  │
│  │ • Systems   │  │ • PipeWire  │  │ • Pakiety   │  │ • Udev rules        │  │
│  └─────────────┘  │ • Network   │  │ • XDG       │  └─────────────────────┘  │
│                   │ • Users     │  │ • Env vars  │                           │
│                   └─────────────┘  └─────────────┘                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   niri/     │  │  scripts/   │  │ zsh-config/ │  │     noctalia/       │  │
│  │             │  │             │  │             │  │                     │  │
│  │ • cfg/      │  │ • voice-note│  │ • aliases   │  │ • settings.json     │  │
│  │ • keybinds  │  │ • brightness│  │ • functions/│  │ • themes            │  │
│  │ • rules.kdl │  │ • tlo       │  │ • nn.zsh    │  │ • assets            │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │           nixos-rebuild switch      │
                    │   (alias: nos / nh os switch)       │
                    └─────────────────┬─────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    ▼                                   ▼
        ┌─────────────────────┐           ┌─────────────────────────┐
        │   SYSTEM (root)     │           │   UŻYTKOWNIK (shin)    │
        │                     │           │                         │
        │ • /run/current-system │           │ • ~/.nix-profile        │
        │ • kernel, drivers   │           │ • ~/.config/ (symlinks) │
        │ • systemd services  │           │ • ~/ (dotfiles)         │
        │ • /etc/ (generated) │           │ • PATH z pakietami HM   │
        └─────────────────────┘           └─────────────────────────┘
                    │                                   │
                    └─────────────────┬─────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │         /nix/store (immutable)      │
                    │  /nix/store/abc123-firefox-125.0/   │
                    │  /nix/store/xyz789-zen-browser/     │
                    │  /nix/store/...-kimi-cli-1.47.0/    │
                    └─────────────────────────────────────┘
```

---

## 3. DRZEWO PLIKÓW — Gdzie Co Leży

```
/etc/nixos/
│
├── flake.nix                    ← WEJŚCIE. Definiuje inputs (źródła) i outputs (systemy).
│                                  • nixpkgs (unstable)
│                                  • home-manager
│                                  • noctalia (shell + widgets)
│                                  • zen-browser (flake)
│                                  • kimi-cli (MoonshotAI)
│
├── configuration.nix            ← SYSTEM. Tylko to co musi być root.
│                                  • Bootloader (systemd-boot)
│                                  • NVIDIA (modesetting, power management)
│                                  • PipeWire + JACK (audio)
│                                  • NetworkManager
│                                  • Users (shin, root locked)
│                                  • Nix settings (flakes, substituters)
│                                  • MINIMAL systemPackages (nh, git, kitty, micro)
│
├── home.nix                     ← UŻYTKOWNIK. Twój desktop, twoje appki.
│                                  • Zsh config (via HM module lub dotfiles)
│                                  • Dotfiles (niri, kitty, noctalia)
│                                  • Pakiety użytkownika (obsidian, reaper, discord, zen)
│                                  • Env vars (FLAKE=/etc/nixos)
│                                  • Cursor theme (Bibata)
│
├── hardware-configuration.nix  ← HARDWARE. Wygenerowany przez nixos-generate-config.
│                                  • NIGDY nie edytuj ręcznie (chyba że wiesz co robisz).
│                                  • Partycje, LUKS, filesystemy, kernel modules.
│
├── niri/
│   ├── cfg/
│   │   ├── keybinds.kdl         ← SKRÓTY. Alt+Y (YouTube Music), Mod+Tab (kitty).
│   │   ├── rules.kdl            ← Reguły okien (które app gdzie się otwiera).
│   │   ├── input.kdl            ← Touchpad, natural-scroll, focus-follows-mouse.
│   │   ├── layout.kdl           ← Tiling, gaps, borders.
│   │   ├── animation.kdl        ← Animacje workspace'ów.
│   │   ├── display.kdl          ← Monitory, scale, position.
│   │   ├── autostart.kdl        ← Co startuje z Niri.
│   │   └── misc.kdl             ← Reszta.
│   ├── config.kdl               ← Główny import (ładuje cfg/*.kdl).
│   └── noctalia.kdl             ← Integracja z Noctalia Shell.
│
├── scripts/                     ← SKRYPTY SHELL. Nigdy więcej w ~/ ani ~/.local/bin.
│   ├── voice-note               ← Nagrywanie voice note (whisper / aider).
│   ├── brightness.sh            ← Kontrola jasności ekranu.
│   ├── tlo                      ← Tapeta / wallpaper setter.
│   ├── tlo-layer                ← Layer-shell wallpaper (niri-specific).
│   ├── wtype-if-not-obsidian    ← Wstawianie polskich znaków (Alt+S = ś).
│   └── zen-music                ← Wrapper na zen --new-window music.youtube.com.
│
├── zsh-config/
│   ├── aliases.zsh              ← ALIASY. nos, nhs (teraz nos), ncu, nclean.
│   ├── functions/
│   │   ├── func_init.zsh        ← Auto-loader: source *.zsh z folderu.
│   │   └── nn.zsh               ← Złota Funkcja: label + git commit + push.
│   └── init.zsh                 ← Główny init (zinit, p10k, plugins).
│
├── noctalia/                    ← KONFIG NOCTALII (jeśli masz custom).
│   └── settings.json            ← Widgety, bar, launcher, calendar.
│
├── kitty-config/                ← Konfiguracja terminala Kitty.
│   └── kitty.conf
│
├── btop-noctalia.theme          ← Theme btop wygenerowany przez Noctalia.
│
├── NIXOS_GUIDE.md               ← TEN DOKUMENT (albo jego wcześniejsza wersja).
│
└── .git/                        ← HISTORIA. Każda zmiana to commit.
    └── flake.lock               ← ZAMROŻONE WERSJE. Nie dotykać ręcznie.
```

---

## 4. WORKFLOW — Jak Wprowadzać Zmiany (The Golden Path)

### 4.1 Diagram Przepływu

```
┌────────────┐     ┌──────────────┐     ┌─────────────┐     ┌─────────────┐
│  EDYTUJ    │────▶│  nn "opis"   │────▶│    nos      │────▶│   TESTUJ    │
│  plik .nix │     │ (label+git)  │     │ (rebuild)   │     │  działa?    │
└────────────┘     └──────────────┘     └─────────────┘     └──────┬──────┘
                                                                 │
                                                    TAK ◄────────┘
                                                                 │
                                                    NIE ◄────────┘
                                                                 │
                                            ┌────────────────────┴────────┐
                                            │  git revert / reboot +      │
                                            │  wybranie starej generacji  │
                                            │  w bootloaderze             │
                                            └─────────────────────────────┘
```

### 4.2 Krok po Kroku — Dodawanie Pakietu

**Scenariusz:** Chcesz zainstalować `kdenlive` (edytor wideo).

```bash
# 1. EDYTUJ home.nix (bo to appka użytkownika, nie systemowa)
sudo micro /etc/nixos/home.nix

# 2. ZNAJDŹ sekcję home.packages i dodaj:
#     kdenlive

# 3. ZAPISZ (Ctrl+O, Ctrl+X w micro)

# 4. ZATWIERDŹ ZMIANĘ W GIT + LABEL
nn "dodanieKdenlive"

# 5. ZBUDUJ SYSTEM
nos

# 6. SPRAWDŹ
which kdenlive
kdenlive --version
```

### 4.3 Co się dzieje pod spodem?

| Krok | Komenda | Co się dzieje |
|------|---------|---------------|
| Edycja | `micro` | Zmieniasz tekst w `/etc/nixos/home.nix` |
| Label | `nn` | `sed` zmienia `system.nixos.label`, `git add .`, `git commit -m "dodanieKdenlive"` |
| Build | `nos` | `nh` wywołuje `nix build`. Nix porównuje nowy stan ze starym. |
| Aktywacja | `nos` (część 2) | Nowa generacja systemu staje się `/run/current-system`. Home Manager symlinkuje `~/.nix-profile`. |
| Boot | (automatycznie) | Systemd-boot dodaje nową pozycję do menu. Stara generacja jest dostępna jako fallback. |

---

## 5. SYSTEM vs HOME — Granica Odpowiedzialności

### 5.1 Tabela Decyzyjna

| Chcesz dodać... | Gdzie? | Dlaczego? |
|-----------------|--------|-----------|
| `firefox`, `obsidian`, `discord` | `home.nix` `home.packages` | To są appki użytkownika. Inny user na tym PC może ich nie chcieć. |
| `nh`, `git`, `micro` (rescue) | `configuration.nix` `environment.systemPackages` | Muszą być dostępne w TTY / rescue mode, zanim Home Manager się odpali. |
| `pipewire`, `nvidia`, `bluetooth` | `configuration.nix` | To są usługi systemowe (systemd). |
| `zsh` jako shell | `configuration.nix` `programs.zsh.enable = true` | NixOS wymaga tego dla login shell. |
| `zsh` config, aliases, p10k | `home.nix` `programs.zsh` LUB `home.file` | To jest personalizacja użytkownika. |
| `niri` keybindy | `niri/cfg/keybinds.kdl` | Config compositora, nie pakiet. |
| Skrypt shell | `scripts/` + `home.nix` / `configuration.nix` | Skrypt w repo, ścieżka w keybindzie lub PATH. |
| Tapeta / theme | `home.nix` `home.file` | Asset użytkownika. |

### 5.2 Granica Mentalna

```
┌────────────────────────────────────────┐
│           configuration.nix            │
│  "Co musi działać, zanim się zaloguję?"│
│                                        │
│  • Boot  • NVIDIA  • PipeWire          │
│  • WiFi  • Login (greetd)  • TTY       │
│  • nh, git, micro (rescue tools)       │
└────────────────────────────────────────┘
                    │
                    │ Po zalogowaniu...
                    ▼
┌────────────────────────────────────────┐
│              home.nix                  │
│  "Co widzę na swoim pulpicie?"         │
│                                        │
│  • Zen, Obsidian, Reaper, Discord      │
│  • Zsh theme, cursor, btop theme       │
│  • Niri config, kitty config           │
│  • Env vars (FLAKE), PATH tweaks       │
└────────────────────────────────────────┘
```

---

## 6. ZARZĄDZANIE SKRYPTAMI

### 6.1 Zasada

> **Skrypt musi być w `/etc/nixos/scripts/` i zarządzany przez NixOS.**

Nigdy więcej `~/voice-note`, `~/.local/bin/brightness.sh`, `~/polacz_tablet.sh`. Dlaczego?

| Problem | Rozwiązanie NixOS |
|---------|-------------------|
| Skrypt znika przy reinstallu | Jest w repo gita |
| Ścieżka `~/skrypt.sh` jest różna na różnych komputerach | `/etc/nixos/scripts/skrypt.sh` jest zawsze ta sama |
| Nie wiesz która wersja skryptu działa | Git pokazuje historię zmian |
| Keybind w Niri wskazuje na `~` które się zmienia | Keybind wskazuje na `/etc/nixos/scripts/` |

### 6.2 Dodawanie Nowego Skryptu

```bash
# 1. Stwórz skrypt w repo
sudo micro /etc/nixos/scripts/moj-nowy-skrypt

# 2. Uczyń go wykonywalnym (ważne!)
sudo chmod +x /etc/nixos/scripts/moj-nowy-skrypt

# 3. Dodaj do keybinds.kdl (jeśli to skrót klawiszowy)
sudo micro /etc/nixos/niri/cfg/keybinds.kdl
#     Mod+X { spawn "/etc/nixos/scripts/moj-nowy-skrypt"; }

# 4. ZATWIERDŹ
nn "dodanieSkryptuMoj"
nos
```

### 6.3 Ścieżki w Keybindach — Złota Zasada

```kdl
# ❌ ZŁE — zależy od PATH użytkownika, który w Niri może być inny
Mod+Y { spawn "zen" "--new-window" "https://music.youtube.com/"; }

# ✅ DOBRE — absolutna ścieżka do profilu Home Managera
Alt+Y { spawn "/etc/profiles/per-user/shin/bin/zen" "--new-window" "https://music.youtube.com/"; }

# ✅ ALBO — wrapper w /etc/nixos/scripts/ (najlepsze dla złożonych komend)
Alt+Y { spawn "/etc/nixos/scripts/zen-music"; }
```

---

## 7. SHELL & ZSH — Architektura

### 7.1 Jak się ładuje?

```
Login shell (greetd -> niri -> kitty -> zsh)
         │
         ▼
    /etc/zshrc (system-wide, NixOS)
         │
         ▼
    ~/.zshrc (symlink z home.file)
         │
         ▼
    source /etc/nixos/zsh-config/init.zsh
         │
         ├── zinit loads plugins (p10k, autosuggestions, abbr)
         ├── source aliases.zsh
         ├── source functions/func_init.zsh (auto-load all *.zsh)
         │       └── functions/nn.zsh
         └── p10k prompt
```

### 7.2 Dodawanie Aliasu

```bash
# EDYTUJ aliases.zsh
sudo micro /etc/nixos/zsh-config/aliases.zsh

# DODAJ (przykład):
alias yt="zen --new-window https://youtube.com"

# ZATWIERDŹ
nn "aliasYt"
nos
# (lub nhs jeśli masz standalone HM, ale używaj nos)
```

### 7.3 Dodawanie Funkcji

```bash
# STWÓRZ plik w functions/
sudo micro /etc/nixos/zsh-config/functions/backup-config.zsh
```

```zsh
function backup-config() {
    local dest="$HOME/backup/nixos-$(date +%Y%m%d-%H%M%S).tar.gz"
    mkdir -p "$HOME/backup"
    tar czf "$dest" -C /etc nixos
    echo "Backup saved to: $dest"
}
```

```bash
sudo chmod +x /etc/nixos/zsh-config/functions/backup-config.zsh
nn "funkcjaBackup"
nos
```

**Nie musisz niczego dodawać do `func_init.zsh`!** On auto-ładuje wszystkie `*.zsh` z folderu `functions/`.

---

## 8. NIRI & KEYBINDY — Modyfikacja

### 8.1 Struktura Configu Niri

Niri używa formatu **KDL** (nie Nix!). Config jest w `/etc/nixos/niri/` i symlinkowany do `~/.config/niri/` przez Home Manager.

```
niri/
├── config.kdl          ← Główny plik, importuje resztę
├── noctalia.kdl        ← Integracja z paskiem Noctalia
└── cfg/
    ├── keybinds.kdl    ← WSZYSTKIE skróty (TU EDYTUJESZ)
    ├── input.kdl       ← Touchpad, myszka
    ├── layout.kdl      ← Tiling, gaps
    ├── animation.kdl   ← Animacje
    ├── display.kdl     ← Monitory
    ├── autostart.kdl   ← Autostart
    └── misc.kdl        ← Reszta
```

### 8.2 Dodawanie Skrótu Klawiszowego

```bash
sudo micro /etc/nixos/niri/cfg/keybinds.kdl
```

```kdl
// Przykład: Mod+Shift+S zrzut ekranu do clipboard
Mod+Shift+S hotkey-overlay-title="Screenshot to clipboard" {
    spawn "grimblast" "--notify" "copy" "area"
}

// Przykład: Mod+M otwiera YouTube Music w Zen
Mod+M hotkey-overlay-title="YouTube Music" {
    spawn "/etc/profiles/per-user/shin/bin/zen" "--new-window" "https://music.youtube.com/"
}
```

```bash
nn "niriKeybindy"
nos
```

**Niri nie wymaga rebuildu NixOS do przeładowania keybindów!** Możesz zrobić:
```bash
niri msg action reload-config
```
Ale po `nos` config i tak się przeładuje przy nowej generacji.

---

## 9. AI / ML STACK — Lokalny Ekosystem

Masz złożony setup AI. Oto jak pasuje do NixOS:

```
┌─────────────────────────────────────────────────────────────┐
│                    TWÓJ AI STACK                            │
├─────────────────────────────────────────────────────────────┤
│  CHMURA                      │  LOKALNIE (RTX 3060 12GB)    │
│  • Gemini CLI (kimi)         │  • llama-server (port 1234)  │
│    ^ zainstalowany przez   │    ^ OmniCoder 9B Q6_K         │
│      flake MoonshotAI      │  • llama-server (port 1235)    │
│    ^ nh os switch          │    ^ Llama 3.1 8B Q8_0         │
│                            │  • Aider (via uv/pip)          │
│                            │    ^ --chat-language Polish    │
│                            │    ^ --context-window 32768    │
│                            │    ^ --no-auto-commits         │
│                            │  • CUDA via NixOS + ręczne     │
│                            │    LD_LIBRARY_PATH (legacy)    │
└─────────────────────────────────────────────────────────────┘
```

### 9.1 Zasady dla AI Tools

| Tool | Jak zarządzać? | Gdzie? |
|------|----------------|--------|
| `kimi-cli` | `flake.nix` input + `home.nix` | NixOS (deklaratywnie) |
| `llama.cpp` / `llama-server` | `home.nix` `home.packages` | NixOS (llama-cpp pakiet) |
| `aider` | `uv tool install` lub `pipx` | Imperatywnie (nie ma w nixpkgs) |
| Modele GGUF | `~/models/` lub `/mnt/dane/models/` | State (duże pliki binary, nie w repo) |

### 9.2 Aider — Lokalny Development

Aider nie jest w nixpkgs. Instalujesz go przez `uv`:

```bash
# uv jest w home.packages (lub configuration.nix)
uv tool install aider-chat

# Aider widzi Twoje lokalne API:
export OPENAI_API_BASE=http://localhost:1234/v1
aider --model openai/local --chat-language Polish --no-auto-commits
```

**To jest OK.** Nie wszystko musi być w NixOS. Aider to narzędzie developerskie które często się aktualizuje — `uv tool install` jest akceptowalnym kompromisem. Ale jeśli chcesz go zpinować:

```nix
# W home.nix — ale wymaga overlayu lub pip2nix
(python3.withPackages (ps: [ ps.aider-chat ]))
```

To jest skomplikowane. Na razie `uv tool install` jest w porządku.

---

## 10. TROUBLESHOOTING — Kiedy Coś Idzie Źle

### 10.1 Szybka Diagnostyka

```bash
# Sprawdź czy build się udał
nixos-rebuild switch --flake /etc/nixos#nixos --show-trace

# Sprawdź która generacja jest aktywna
sudo nix-env -p /nix/var/nix/profiles/system --list-generations

# Rollback do poprzedniej (jeśli system się zepsuł)
sudo nixos-rebuild switch --flake /etc/nixos#nixos --rollback

# Albo reboot i wybierz starą generację w bootloaderze

# Sprawdź błędy w configu (syntax)
nix-instantiate --parse /etc/nixos/configuration.nix
nix-instantiate --parse /etc/nixos/home.nix
nix-instantiate --parse /etc/nixos/flake.nix

# Sprawdź czy pakiet jest w nixpkgs
nix search nixpkgs firefox

# Sprawdź czy Home Manager widzi zmiany
home-manager news --flake /etc/nixos#shin
```

### 10.2 Częste Błędy

| Błąd | Przyczyna | Fix |
|------|-----------|-----|
| `error: undefined variable 'zen'` | `zen` nie jest w `home.packages` ani `systemPackages` | Dodaj do `home.packages` jako `inputs.zen-browser.packages...` |
| `error: attribute 'home' missing` | `home.nix` zwraca `{}` zamiast `home` config | Sprawdź czy `home.nix` ma `home.packages`, `programs`, itp. |
| `warning: Git tree is dirty` | Masz niezacommitowane zmiany | `nn "opis"` lub `git add . && git commit` |
| `zsh: command not found: nn` | Funkcja nie jest załadowana | `source ~/.zshrc` lub nowy terminal |
| `permission denied` na `/etc/nixos` | Pliki root-owned | `sudo chown -R shin:users /etc/nixos` (raz, na stałe) |
| `nvidia-smi` nie widzi GPU | `hardware.nvidia.modesetting` lub `open` jest źle | Sprawdź `configuration.nix` sekcję NVIDIA |
| `pipewire` nie działa | `services.pulseaudio.enable = true` koliduje | Upewnij się że `pulseaudio.enable = false` |

### 10.3 Recovery Mode

Jeśli `nos` zepsuł system tak, że nie bootuje:

1. Reboot.
2. W bootloaderze (systemd-boot) wybierz **poprzednią generację** (starszą datę).
3. System wstanie w stanie sprzed zmiany.
4. Zaloguj się, napraw `configuration.nix`, `nn "fix"`, `nos`.

---

## 11. BEST PRACTICES — Jak Nie Zepsuć Systemu

### 11.1 Dziesięć Przykazań NixOS

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  1. NIE INSTALUJ PAKIETÓW PRZEZ apt / pip / npm / cargo install -g           ║
║     (chyba że wiesz EXAKTLY co robisz i używasz nix-ld)                      ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  2. NIE EDYTUJ PLIKÓW W /etc/nixos PRZEZ sed -i                              ║
║     (sed nie rozumie składni Nix, zepsuje nawiasy)                           ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  3. NIE ZMIENIAJ system.stateVersion                                         ║
║     (to migracyjna wersja, nie aktualna wersja NixOS)                        ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  4. NIE COMMITUJ root.initialPassword = "tajnehaslo"                         ║
║     (używaj hashedPassword lub locked root)                                  ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  5. NIE TRZYMAJ SKRYPTÓW W ~/ ANI ~/.local/bin                               ║
║     (wszystko do /etc/nixos/scripts/)                                        ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  6. NIE UŻYWAJ ABSOLUTNYCH ŚCIEŻEK /nix/store/... W KEYBINDACH               ║
║     (zmieniają się po każdym rebuildzie)                                     ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  7. ZAWSZE RÓB nn PRZED nos                                                  ║
║     (git commit to Twój safety net)                                          ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  8. ZAWSZE TESTUJ W NOWYM TERMINALU PO REBUILDZIE                            ║
║     (stary terminal może mieć stary PATH)                                    ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  9. RÓB GIT COMMIT CO JEDNĄ ZMIANĘ LOGICZNĄ                                  ║
║     (nie commituj 10 zmian naraz — rollback będzie trudny)                   ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ 10. CZYTAJ BŁĘDY NIX — one mówią DOKŁADNIE co jest źle                       ║
║     (linia, kolumna, plik, nazwa zmiennej)                                   ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

### 11.2 Co Commitować, Co Nie Commitować

```
✅ COMMITUJ (w /etc/nixos):
   • *.nix (configuration.nix, home.nix, flake.nix)
   • *.kdl (keybinds, rules, input, layout)
   • *.zsh (aliases, functions)
   • *.sh (skrypty w scripts/)
   • *.theme, *.json (configi noctalia, btop)
   • README, ten przewodnik

❌ NIE COMMITUJ (dodaj do .gitignore):
   • flake.lock (commituj, ale nie edytuj ręcznie — Nix go zarządza)
   • *.backup
   • .history (zsh history)
   • node_modules/, __pycache__/
   • Duże pliki binarne (modele AI, ISO, filmy)
   • Pliki zawierające hasła, klucze API, tokeny
```

### 11.3 .gitignore dla /etc/nixos

```gitignore
# NixOS /etc/nixos .gitignore

# Generowane przez Nix (nie edytuj ręcznie)
# flake.lock  ← TEN COMMITUJEMY, bo pinuje wersje

# Backupy
*.backup
*~
*.swp
*.swo

# Zsh history i temp
.zsh_history
.history
*.zwc

# Python / Node
__pycache__/
node_modules/
*.pyc

# Duże assety (modele AI, etc.)
*.gguf
*.bin
*.safetensors
models/

# Secrets (JEŚLI MASZ — lepiej użyć sops-nix lub age)
secrets/
*.key
*.pem
```

---

## 12. ROZSZERZANIE SYSTEMU — Przykłady

### 12.1 Dodanie Nowego Użytkownika

```nix
# configuration.nix
users.users.gosc = {
  isNormalUser = true;
  description = "Gość";
  shell = pkgs.bash;  # Gość nie potrzebuje Twojego Zsh
  extraGroups = [ "networkmanager" "audio" ];
  packages = with pkgs; [ firefox ];  # Tylko Firefox
};
```

### 12.2 Dodanie Nowej Maszyny (Laptop)

```nix
# flake.nix
outputs = inputs@{ ... }: {
  nixosConfigurations.nixos = nixpkgs.lib.nixosSystem { ... };  # PC
  nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./laptop-hardware.nix
      ./configuration.nix  # WSPÓLNA konfiguracja!
      { networking.hostName = "laptop"; }
    ];
  };
};
```

### 12.3 Dodanie Własnego Overlay (np. nowa wersja pakietu)

```nix
# flake.nix
outputs = inputs@{ nixpkgs, ... }:
  let
    overlay = final: prev: {
      my-custom-mpv = prev.mpv.override {
        scripts = [ prev.mpvScripts.uosc ];
      };
    };
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay ]; })
        ./configuration.nix
      ];
    };
  };
```

### 12.4 Dodanie Secret (SOPS / Age)

NIE trzymaj haseł w plaintext w `.nix`. Użyj `sops-nix`:

```nix
# flake.nix inputs
sops-nix = {
  url = "github:Mic92/sops-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};

# configuration.nix
imports = [ inputs.sops-nix.nixosModules.sops ];

sops.defaultSopsFile = ./secrets/secrets.yaml;
sops.secrets.moje_haslo = {};

# W serwisie:
systemd.services.moj-serwis = {
  serviceConfig.LoadCredential = "haslo:${config.sops.secrets.moje_haslo.path}";
};
```

---

## 13. ALIASY & KOMENDY — Ściągawka

### 13.1 Twoje Aliasy (z `aliases.zsh`)

| Alias | Co robi | Kiedy używać |
|-------|---------|--------------|
| `nos` | `nh os switch` | ZAWSZE gdy zmieniasz cokolwiek w systemie |
| `ncu` | `nh os switch --update` | Aktualizacja wszystkich pakietów |
| `nclean` | `nh clean all` | Czyszczenie starego garbage z `/nix/store` |
| `nstat` | `git -C /etc/nixos status` | Sprawdź co się zmieniło w repo |
| `nlog` | `git -C /etc/nixos log --oneline -n 10` | Historia commitów |
| `ndiff` | `git -C /etc/nixos diff` | Co jest niezacommitowane |

### 13.2 Funkcje (z `functions/`)

| Funkcja | Użycie | Co robi |
|---------|--------|---------|
| `nn "opis"` | `nn dodanieFirefox` | 1. Zmienia label, 2. `git add .`, 3. `git commit` |

### 13.3 Komendy Nix

```bash
# Wyszukaj pakiet
nix search nixpkgs firefox

# Zainstaluj tymczasowo (nie trwale!)
nix shell nixpkgs#htop

# Zbuduj config bez aktywacji (dry-run)
nixos-rebuild build --flake /etc/nixos#nixos

# Sprawdź diff między generacjami
nix store diff-closures /nix/var/nix/profiles/system-42-link /nix/var/nix/profiles/system-43-link

# Garbage collection (usuń nieużywane)
nix-collect-garbage -d

# Optymalizacja store (deduplikacja)
nix store optimise
```

---

## 14. HISTORIA ZMIAN — Dlaczego To Zrobiliśmy

### 14.1 Timeline Twojej Migracji

```
2024-??-??  ──► Instalacja NixOS, configuration.nix "wszystkomający" (300+ linii)
       │
       ▼
2024-??-??  ──► Dodanie Home Manager, ale pakiety wciąż w configuration.nix
       │
       ▼
2025-??-??  ──► Migracja do Flakes, dodanie Noctalia, Zen Browser
       │
       ▼
2025-??-??  ──► Dodanie lokalnych LLM (llama.cpp, OmniCoder, Llama 3.1)
       │
       ▼
2026-06-07  ──► WIELKIE SPRZĄTANIE (ten dzień!)
       │         • Podział system/home
       │         • Przeniesienie skryptów do /etc/nixos/scripts/
       │         • Funkcja nn (label + git)
       │         • Alias nos (nh)
       │         • Usunięcie nixConfig z flake.nix
       │         • Dodanie kimi-cli przez oficjalny flake
       │         • Fix btop theme (Noctalia)
       │         • Fix zen keybind (absolutna ścieżka)
       │         • Root locked (hashedPassword = "!")
       │
       ▼
  FUTURE  ──► Sops-nix dla sekretów, laptop config, CI/CD dla /etc/nixos
```

---

## 15. ZASOBY — Gdzie Szukać Pomocy

| Zasób | URL | Do czego |
|-------|-----|----------|
| NixOS Manual | https://nixos.org/manual/nixos/stable/ | Oficjalna dokumentacja |
| NixOS Options | https://search.nixos.org/options | Wyszukiwarka opcji systemowych |
| NixOS Packages | https://search.nixos.org/packages | Wyszukiwarka pakietów |
| Home Manager | https://nix-community.github.io/home-manager/ | Opcje Home Managera |
| Noctalia | https://github.com/noctalia-dev/noctalia-shell | Dokumentacja shella |
| Kimi CLI | https://github.com/MoonshotAI/kimi-cli | Dokumentacja AI CLI |
| NixOS Wiki | https://wiki.nixos.org/wiki/Main_page | Community wiki |
| Nixpkgs Source | https://github.com/NixOS/nixpkgs | Czytaj kod, szukaj przykładów |
| Moje Repo | `/etc/nixos` | Prawda jest w kodzie |

---

## 16. OSTATNIE SŁOWO

> **NixOS to nie dystrybucja. To paradygmat.**
>
> Każda inna dystrybucja pyta: "Jak zainstalować program?"
> NixOS pyta: "Jak opisać stan systemu, żeby był reprodukowalny?"
>
> Twoje `/etc/nixos` to nie tylko config. To **infrastruktura jako kod**.
> To backup Twojego braina. To możliwość sklonowania siebie na nowy hardware.
> To spokój ducha, że jak coś zepsujesz — wciśniesz reboot i wybierzesz poprzednią wersję.

**Nie wracaj do `sudo apt install`. Nie wracaj do `~/random-scripts.sh`. Nie wracaj do ręcznego klikania w GUI.**

Edytuj. Commituj. Rebuilduj. Ciesz się niezniszczalnym systemem.

---

*Wygenerowano dla systemu `shin@nixos` • NixOS 25.11 • Flakes + Home Manager • Niri + Noctalia*
*Ostatnia aktualizacja: 2026-06-07*
