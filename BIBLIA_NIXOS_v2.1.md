# 📘 BIBLIA NIXOS — shin@nixos
## Wersja 2.1 — Prawda z Kodu
> *"Prawda jest w kodzie. Jeśli nie ma tego w `/etc/nixos`, to nie istnieje."*
> *"Ale to co w `/etc/nixos` jest, niekoniecznie musisz używać."*

---

## 1. FILOZOFIA — Co System Mówi o Sobie

### 1.1 System to Platforma, Home to Osobowość

`configuration.nix` nie jest "wszystkim". To **pustynia** — tylko to co musi działać zanim się zalogujesz:
- Boot, kernel, systemd-boot
- NVIDIA (closed driver, power limit 203W)
- PipeWire + JACK (realtime audio)
- NetworkManager, WiFi, Bluetooth
- Rescue tools (kitty, micro, nh, git)
- Hardware interfaces (i2c dla DDC/CI, v4l2loopback dla OBS)

Wszystko inne — Twój desktop, Twoje appki, Twoje kolory — to `home.nix`.

### 1.2 Copy Over Symlink — Mechanizm Oddechu

Home Manager domyślnie robi symlinki do `/nix/store/` — read-only, zamrożone, nietykalne.
Ale Noctalia chce zmieniać kolory w locie. Kitty chce zapisywać sesje. Btop chce pisać logi.

Rozwiązanie: `syncAllConfigs`.
- HM generuje bazę w `/nix/store/`.
- Aktywacja **kopiuje** pliki do `~/.config/` (dereferencja symlinków).
- Noctalia może pisać w locie.
- Po `nos` — wszystko wraca do stanu z `/etc/nixos/`.

To nie jest czysty NixOS. To NixOS który **oddycha**.

### 1.3 Archiwum Żywych Martwych

Masz w `home.nix` rzeczy których nie używasz:
- `llama-cpp`, `lmstudio` — lokalne LLM, nieużywane (masz Kimi w chmurze)
- `xdotool`, `ydotool` — były do wprowadzania głosowego, obecnie nieaktywne
- `faster-whisper` + `sounddevice` + `numpy` — TTS działa do dupy, ale skrypt do Anki gdzieś istnieje
- `espeak-ng` — w system packages, TTS backup

Nie usunąłeś ich. Są w kodzie. To **archiwum** — nie śmietnik. W każdej chwili możesz do nich wrócić.

### 1.4 Flakes jako Lockbox, nie Klatka

`flake.lock` pina wersje, ale używasz `nixos-unstable`. Jesteś na krawędzi, ale z bezpiecznikiem.
Jeśli coś się zepsuje — reboot, wybierz starą generację, wracasz do znanego stanu.

### 1.5 Git jako Historia, nie Tylko Backup

`nn "opis"` nie jest opcjonalny. To część workflow. Każda generacja systemu ma **nazwę** (`system.nixos.label`).
Możesz przejść przez historię i zobaczyć kiedy co się zmieniło.

### 1.6 Niri jako Centrum Świata

Cały desktop to trójca:
- **Niri** — kompozytor, tiling, keybindy
- **Noctalia** — shell, bar, kolory, tapety
- **Kitty** — terminal

Wszystko inne to dodatki.

### 1.7 NVIDIA jako Wymóg, nie Wybór

RTX 3060 12GB to serce systemu. Closed driver (`open = false`), modesetting, power limit.
Bez tego nie ma: AI, Godot, przezroczystości, CUDA.
NVIDIA rządzi, a Ty się dostosowujesz (OpenGL zamiast Vulkan w Godot).

### 1.8 QMK to Narzędzie, nie Hobby

Masz w systemie cały toolchain AVR/QMK, udev rules, firmware w flake.
To nie jest "może kiedyś". To aktywnie używane narzędzie.

---

## 2. ARCHITEKTURA SYSTEMU

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
│  │ • nixpkgs   │  │ • Boot      │  │ • Zsh       │  │ • Partycje          │  │
│  │ • home-mgr  │  │ • NVIDIA    │  │ • Dotfiles  │  │ • Kernel modules    │  │
│  │ • noctalia  │  │ • PipeWire  │  │ • Pakiety   │  │ • Udev rules        │  │
│  │ • zen       │  │ • Network   │  │ • syncAll   │  └─────────────────────┘  │
│  │ • kimi-cli  │  │ • Users     │  │   Configs   │                           │
│  │ • qmk_fw   │  │ • v4l2loop  │  │ • Env vars  │                           │
│  └─────────────┘  │ • Flatpak   │  │ • Cursor    │                           │
│                   │ • QMK       │  │ • Niri tgt  │                           │
│                   └─────────────┘  └─────────────┘                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   niri/     │  │  scripts/   │  │ zsh-config/ │  │     noctalia/       │  │
│  │             │  │             │  │             │  │                     │  │
│  │ • cfg/      │  │ • voice-note│  │ • aliases   │  │ • settings.json     │  │
│  │ • keybinds  │  │ • dictate   │  │ • functions/│  │ • themes            │  │
│  │ • rules.kdl │  │ • brightness│  │ • nn.zsh    │  │ • assets            │  │
│  │ • keymap.xkb│  │ • sync-all  │  │ • init.zsh  │  │                     │  │
│  └─────────────┘  │ • tlo       │  └─────────────┘  └─────────────────────┘  │
│                   │ • zen-music │                                             │
│                   └─────────────┘                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────────────────────┐  │
│  │kitty-config/│  │   qmk/      │  │ ARCHIWUM (w home.nix, nieużywane):   │  │
│  │             │  │             │  │ • llama-cpp, lmstudio (lokalne LLM)   │  │
│  │ • kitty.conf│  │ • firmware  │  │ • xdotool, ydotool (stare TTS)        │  │
│  └─────────────┘  └─────────────┘  │ • faster-whisper (TTS do dupy)        │  │
│                                    │ • espeak-ng (TTS backup)              │  │
│  [Projekty:]                       └─────────────────────────────────────────┘  │
│  • /home/shin/gd/justGame (Godot 4, OpenGL, transparent)                      │
│  • /home/shin/gd/FLESHCITY (Godot 4, PS1 horror, MVP)                         │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │           nh os switch            │
                    │   (alias: nos)                    │
                    └─────────────────┬─────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    ▼                                   ▼
        ┌─────────────────────┐           ┌─────────────────────────┐
        │   SYSTEM (root)     │           │   UŻYTKOWNIK (shin)    │
        │                     │           │                         │
        │ • /run/current-system │           │ • ~/.nix-profile        │
        │ • kernel, drivers   │           │ • ~/.config/ (COPIES!)  │
        │ • systemd services  │           │ • ~/ (dotfiles)         │
        │ • /etc/ (generated) │           │ • PATH z pakietami HM   │
        └─────────────────────┘           └─────────────────────────┘
                    │                                   │
                    └─────────────────┬─────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │         /nix/store (immutable)      │
                    │  /nix/store/abc123-firefox-.../     │
                    │  /nix/store/xyz789-zen-browser/      │
                    │  /nix/store/...-kimi-cli-.../       │
                    └─────────────────────────────────────┘
```

---

## 3. DRZEWO PLIKÓW — Gdzie Co Leży

```
/etc/nixos/
│
├── flake.nix              ← WEJŚCIE. Definiuje inputs i outputs.
│                            • nixpkgs (unstable)
│                            • home-manager
│                            • noctalia (shell + widgets)
│                            • zen-browser (flake)
│                            • kimi-cli (MoonshotAI)
│                            • qmk_firmware (flake = false, raw repo)
│
├── configuration.nix      ← SYSTEM. Tylko to co musi być root.
│                            • Bootloader (systemd-boot)
│                            • NVIDIA (modesetting, power management, CLOSED driver)
│                            • PipeWire + JACK (audio, realtime limits)
│                            • NetworkManager
│                            • Users (shin, root locked)
│                            • Nix settings (flakes, substituters, cachix)
│                            • v4l2loopback (OBS virtual camera)
│                            • i2c (DDC/CI brightness control)
│                            • Flatpak (systemd service for flathub)
│                            • Steam (system-wide, udev, 32-bit libs)
│                            • QMK / AVR toolchain (gcc, binutils, avrlibc, dfu, avrdude, gnumake)
│                            • XKB custom layout (plde) in /etc/xkb/symbols/
│                            • MINIMAL systemPackages (nh, git, kitty, micro, ddcutil, espeak-ng)
│                            • NO /mnt/dane mount (usunięte — powodowało timeouty boot)
│
├── home.nix               ← UŻYTKOWNIK. Twój desktop, twoje appki.
│                            • home.activation.syncAllConfigs (dereference + copy)
│                            • programs.navi
│                            • programs.noctalia-shell (BEZ calendarSupport — usunięte)
│                            • home.pointerCursor (Bibata)
│                            • systemd.user.targets.niri-session
│                            • home.sessionPath ($HOME/.local/bin)
│                            • Pakiety użytkownika (audio, video, comms, AI, utils)
│                            • VST bridge path (.vst/yabridge)
│
├── hardware-configuration.nix  ← HARDWARE. Wygenerowany.
│                            • NIGDY nie edytuj ręcznie (chyba że UUID się zmieni).
│
├── niri/
│   ├── cfg/
│   │   ├── keybinds.kdl       ← WSZYSTKIE skróty.
│   │   ├── rules.kdl          ← Reguły okien.
│   │   ├── input.kdl          ← Touchpad, natural-scroll, keyboard.
│   │   ├── layout.kdl         ← Tiling, gaps, borders.
│   │   ├── animation.kdl      ← Animacje workspace'ów.
│   │   ├── display.kdl        ← Monitory (LOGICAL pixels, NO negative coords).
│   │   ├── autostart.kdl      ← Autostart.
│   │   └── misc.kdl           ← Reszta.
│   ├── config.kdl             ← Główny import.
│   └── keymap.xkb             ← Custom layout plde (F13-F24 + ScrollLock).
│                                  Ładowany przez `file` w input.kdl.
│                                  NIE przez ~/.config/xkb/rules/ (usunięte!)
│
├── scripts/                   ← SKRYPTY. Żywe. Martwe — usunięte.
│   ├── voice-note             ← Nagrywanie + faster-whisper (model small).
│   ├── dictate.py             ← Autorski skrypt pythonowy (TTS/Anki).
│   ├── brightness.sh          ← DDC/CI brightness (--bus N, milisekundy).
│   ├── sync-all-colors        ← JEDYNY skrypt sync. Konsolidacja.
│   ├── tlo                    ← Tapeta / wallpaper setter.
│   ├── tlo-layer              ← Layer-shell wallpaper.
│   ├── wtype-if-not-obsidian  ← Wstawianie polskich znaków (Alt+S = ś).
│   └── zen-music              ← Wrapper na zen --new-window music.youtube.com.
│
├── zsh-config/
│   ├── aliases.zsh            ← ALIASY. nos, ncu, nclean, llm-code, aider-code.
│   ├── functions/
│   │   ├── func_init.zsh      ← Auto-loader: source *.zsh.
│   │   └── nn.zsh             ← Label + git commit.
│   └── init.zsh               ← zinit, p10k, plugins. NO zsh-newuser-install.
│
├── noctalia/
│   └── settings.json          ← Widgety, bar, launcher, calendar.
│                                  HM NIE zarządza bezpośrednio (syncAllConfigs).
│
├── kitty-config/
│   └── kitty.conf             ← Również NIE zarządzane bezpośrednio przez HM.
│
├── btop-noctalia.theme        ← Theme btop wygenerowany przez Noctalia.
│
├── zshrc                      ← Źródło dla ~/.zshrc (via syncAllConfigs).
├── zsh/.p10k.zsh              ← Powerlevel10k config.
├── zsh-plugins/zinit          ← Zinit plugins.
├── cheats/                    ← Navi cheatsheets.
│
├── BIBLIA.md / NIXOS_GUIDE.md ← TEN DOKUMENT.
│
└── .git/                      ← HISTORIA. Każda zmiana to commit.
    └── flake.lock             ← ZAMROŻONE WERSJE. Nie dotykać ręcznie.
```

---

## 4. GRANICA SYSTEM / HOME — Tabela Decyzyjna

| Chcesz dodać... | Gdzie? | Dlaczego? |
|-----------------|--------|-----------|
| `firefox`, `obsidian`, `discord` | `home.nix` `home.packages` | Appki użytkownika. |
| `nh`, `git`, `micro` (rescue) | `configuration.nix` `environment.systemPackages` | Muszą być w TTY / rescue mode. |
| `pipewire`, `nvidia`, `bluetooth` | `configuration.nix` | Usługi systemowe (systemd). |
| `zsh` jako shell | `configuration.nix` `programs.zsh.enable = true` | NixOS wymaga dla login shell. |
| `zsh` config, aliases, p10k | `home.nix` / `zsh-config/` | Personalizacja użytkownika. |
| `niri` keybindy | `niri/cfg/*.kdl` | Config compositora, nie pakiet. |
| Skrypt shell | `scripts/` + keybind lub PATH | Skrypt w repo, absolutna ścieżka. |
| Tapeta / theme | `home.nix` `home.file` LUB Noctalia | Asset użytkownika. |
| `/mnt/dane` mount | **NIGDZIE** (usunięte) | Powodowało timeouty boot. Montuj ręcznie jeśli trzeba. |
| `noctalia` / `kitty` config | `home.nix` `home.activation.syncAllConfigs` | HM zarządza bazą, aktywacja robi kopie. |
| `llama-cpp`, `lmstudio` | `home.nix` (ARCHIWUM) | Nie używasz, ale masz w kodzie. |
| `xdotool`, `ydotool` | `home.nix` (ARCHIWUM) | Były do TTS, obecnie nieaktywne. |
| `faster-whisper` | `home.nix` (ARCHIWUM) | Działa do dupy, ale skrypt do Anki gdzieś istnieje. |

---

## 5. syncAllConfigs — Filozofia Copy Over Symlink

Home Manager domyślnie: symlink z `/nix/store/` → `~/.config/foo` → **read-only**.

Twój system: HM generuje w `/nix/store/`, ale `syncAllConfigs` robi:
1. **Dereference** — zamienia symlinki na kopie plików
2. **chmod +w** — daje prawo zapisu
3. **Sync** — kopiuje z `/etc/nixos/` jeśli się różni

**Rezultat:**
- Noctalia może zmieniać kolory w locie.
- Kitty może zapisywać sesje.
- Btop może pisać logi.
- Po `nos` — wszystko wraca do stanu z `/etc/nixos/`.

To nie jest czysty NixOS. To NixOS który pozwala Ci **oddychać**.

---

## 6. WORKFLOW — Golden Path

```bash
# 1. EDYTUJ plik w /etc/nixos/
sudo micro /etc/nixos/home.nix

# 2. ZATWIERDŹ zmianę w git + ustaw label systemu
nn "dodaniePakietu"

# 3. ZBUDUJ i aktywuj
nos

# 4. TESTUJ w nowym terminalu (stary ma stary PATH)
```

**ZASADY:**
- `nn` przed `nos` — zawsze. Git to safety net.
- Testuj w nowym terminalu — stary ma stary PATH.
- Jedna zmiana logiczna = jeden commit.

---

## 7. HARDWARE — Serce Systemu

### 7.1 NVIDIA RTX 3060 12GB

```nix
services.xserver.videoDrivers = [ "nvidia" ];
hardware.nvidia = {
  modesetting.enable = true;
  powerManagement.enable = true;
  open = false;              # CLOSED driver — lepsza wydajność
  nvidiaSettings = true;
  package = config.boot.kernelPackages.nvidiaPackages.stable;
};
```

Power limit: **203W** via `nvidia-power-limit` systemd service.

### 7.2 QMK — Aktywne Narzędzie

```nix
# System packages
qmk
pkgsCross.avr.buildPackages.gcc
pkgsCross.avr.buildPackages.binutils
pkgsCross.avr.avrlibc
dfu-programmer
avrdude
gnumake

# Flake input
qmk_firmware = {
  url = "github:qmk/qmk_firmware/0.18.17";
  flake = false;
};

# Udev rules
services.udev.packages = [ pkgs.qmk-udev-rules ];
```

To nie jest "może kiedyś". To aktywnie używany toolchain.

### 7.3 Audio — Produkcja, nie Tylko Odtwarzanie

```nix
services.pipewire = {
  enable = true;
  alsa.enable = true;
  alsa.support32Bit = true;
  pulse.enable = true;
  jack.enable = true;        # JACK dla Reaper/Renoise
};

# Realtime limits
security.pam.loginLimits = [
  { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
  { domain = "@audio"; item = "rtprio";  type = "-"; value = "99"; }
  { domain = "@audio"; item = "nice";   type = "-"; value = "-19"; }
];
```

---

## 8. NIRI & NOCTALIA

### 8.1 Niri — KDL, Logical Pixels, Zakazy

- **ZAKAZANE:** Ujemne współrzędne, `left-of`, `~` w ścieżkach keybindów.
- **WYMUSZONE:** Monitory w LOGICAL pixels. Lewy monitor na `x=0`. Przesunięcie o szerokość logiczną.
- **Klawiatura:** Custom `plde` layout (F13-F24 + ScrollLock). Ładowany przez `file` w `input.kdl` z `/etc/xkb/symbols/plde`.
- **PUŁAPKA:** `~/.config/xkb/rules/evdev` powodował self-include i zawieszanie klawiatury. **USUNIĘTE.** Nigdy więcej.

### 8.2 Noctalia — Dynamiczna Wolność

- `calendarSupport` — **USUNIĘTE** z `home.nix` (przestało być wspierane). Jeśli widzisz `calendarSupport = true` w configu — to efekt `git checkout`, nie życzenie.
- `settings.json` — zarządzane przez `syncAllConfigs`, nie bezpośrednio przez HM.
- Kolory, tapety, motywy — zmieniane w locie przez Noctalia.

---

## 9. AI STACK — Chmura + Archiwum Lokalne

### 9.1 Aktywnie Używane

| Tool | Źródło | Użycie |
|------|--------|--------|
| `kimi-cli` | Flake (MoonshotAI) | Główne narzędzie AI (chmura) |
| `aider` | `uv tool install` | Programowanie z AI (chmura) |

### 9.2 Archiwum Lokalne (Nieużywane, ale w Systemie)

| Tool | Gdzie | Status |
|------|-------|--------|
| `llama-cpp` | `home.nix` packages | Nieużywane. Porty 1234/1235 nieaktywne. |
| `lmstudio` | `home.nix` packages | Nieużywane. GUI do lokalnych modeli. |
| `faster-whisper` | `home.nix` python packages | Działa do dupy. Skrypt do Anki gdzieś istnieje. |
| `espeak-ng` | `configuration.nix` | TTS backup. W system packages. |
| `xdotool`, `ydotool` | `home.nix` packages | Były do wprowadzania głosowego. Nieaktywne. |

**Filozofia:** Nie usunąłeś ich. Są w kodzie. To **archiwum** — w każdej chwili możesz wrócić.

---

## 10. MULTIMEDIA

### 10.1 Audio — Reaper + Yabridge

| Komponent | Config |
|---|---|
| Reaper | VST3 via Yabridge |
| Yabridge | `wineWow64Packages.staging` |
| Warnings | Ignoruj `ntoskrnl` — nie wpływają na audio |
| Wine | `wineWow64Packages.stable` + `winetricks` + `yabridgectl` |

### 10.2 Video — OBS Studio

- **Virtual Camera:** Wbudowana w OBS 27+ (`programs.obs-studio.enableVirtualCamera = true`).
- **Usunięte:** `obs-v4l2sink` — przestarzała wtyczka.
- **Moduł jądra:** `v4l2loopback` z `exclusive_caps=1`.

### 10.3 TTS / Whisper — Status

- `faster-whisper` + model `small` — wybrany jako złoty środek (base za słaby, large za wolny na CPU).
- Aktualnie **działa do dupy** — w archiwum, do naprawienia w przyszłości.
- Skrypt `dictate.py` — autorski, gdzieś w `/etc/nixos/scripts/` lub projekcie.

---

## 11. PROJEKTY GIER

### 11.1 FLESHCITY — Survival Horror (MVP)

| Parametr | Wartość |
|---|---|
| Engine | Godot 4 + GDScript |
| Styl | PS1 retro (niskie rozdzielczości, vertex jitter) |
| Core Loop | 5-10 min cykle: zdobywaj części ciała, dostarczaj do Doktora |
| MVP Plan | 3 miesiące: Miesiąc 1 nauka, Miesiące 2-3 Vertical Slice |

**ZAKAZANE w MVP:** Mechanika "Głosu", zaawansowane AI, 4 typy pochodzenia, wielokrotne zakończenia, otwarty świat.

### 11.2 justGame — Przezroczyste Okna

| Parametr | Wartość |
|---|---|
| Engine | Godot 4 + GDScript |
| Renderer | **Compatibility (OpenGL)** — NIE Forward+/Vulkan |
| Dlaczego? | NVIDIA + Vulkan + przezroczystość = błędy na Linux |
| Okno | Flagi `TRANSPARENT` + `MOUSE_PASSTHROUGH` |
| Fallback | "Fake Desktop" — screenshot tła jako Sprite2D |
| Repo | `/home/shin/gd/justGame` (jedna ścieżka, brak `~/shintest`) |

---

## 12. TROUBLESHOOTING — Rozszerzona Księga

| Błąd | Przyczyna | Fix |
|------|-----------|-----|
| Boot failure po GParted | Zmieniony UUID root | `hardware-configuration.nix` z Live CD + `nixos-enter` |
| ext4 mount error | `compress=zstd` (tylko Btrfs!) | Usuń z `configuration.nix` |
| Zsh `locking failed` | HM-managed history | `HISTFILE=~/.zsh_history` poza HM |
| xwayland-satellite SIGTERM | Degraded systemd z błędnych mountów | Napraw mount points (usuń `/mnt/dane`) |
| Klawiatura zawieszona | `~/.config/xkb/rules/evdev` self-include | **USUŃ** katalog `~/.config/xkb/rules/`. Używaj `/etc/xkb/symbols/plde` |
| Slow brightness (6s) | ddcutil skanuje wszystkie szyny | Użyj `--bus N` bezpośrednio |
| Godot transparency broken | Vulkan + NVIDIA | Przejdź na Compatibility (OpenGL) |
| `system.nixos.label` error | Spacja lub `+` w labelu | Tylko `[a-zA-Z0-9:_\.-]*` |
| Noctalia nie zmienia kolorów | Pliki read-only (symlinki) | `syncAllConfigs` musi robić kopie |
| `calendarSupport` error | Usunięte z Noctalii, ale wróciło przez `git checkout` | Usuń `calendarSupport = true` z `home.nix` |

---

## 13. ALIASY & KOMENDY

### 13.1 Systemowe

| Alias | Co robi | Kiedy używać |
|-------|---------|--------------|
| `nos` | `nh os switch` | ZAWSZE gdy zmieniasz cokolwiek |
| `ncu` | `nh os switch --update` | Aktualizacja pakietów |
| `nclean` | `nh clean all` | Czyszczenie `/nix/store` |
| `nstat` | `git -C /etc/nixos status` | Co się zmieniło w repo |
| `nlog` | `git -C /etc/nixos log --oneline -n 10` | Historia commitów |
| `ndiff` | `git -C /etc/nixos diff` | Niezacommitowane zmiany |
| `nn` | Label + git commit | Złota ścieżka — przed `nos` |

### 13.2 AI (Archiwum / Nieużywane)

| Alias | Co robi | Status |
|-------|---------|--------|
| `llm-code` | Start OmniCoder (port 1234) | **ARCHIWUM** — nie używasz |
| `aider-code` | Start Aider z OmniCoder | **ARCHIWUM** — używasz Aider z chmurą |

---

## 14. HISTORIA ZMIAN — Timeline

```
2024-??-??  ──► Instalacja NixOS, configuration.nix "wszystkomający"
       │
       ▼
2024-??-??  ──► Dodanie Home Manager
       │
       ▼
2025-??-??  ──► Migracja do Flakes, Noctalia, Zen Browser
       │
       ▼
2025-??-??  ──► Dodanie lokalnych LLM (llama.cpp, OmniCoder, Llama 3.1)
       │
       ▼
2026-06-07  ──► WIELKIE SPRZĄTANIE
       │         • Podział system/home, nn, nos, skrypty do /etc/nixos/scripts/
       │         • Usunięcie nixConfig z flake.nix, dodanie kimi-cli
       │         • Fix btop theme, fix zen keybind, root locked
       │
       ▼
2026-06-26  ──► WIELKA CZystOść
       │         • Usunięcie martwych skryptów (label: usunieteMartweSkrypty)
       │         • Usunięcie calendarSupport z Noctalii
       │         • Konsolidacja sync-all-colors
       │         • Usunięcie /mnt/dane (timeouty boot)
       │         • Usunięcie ~/.config/xkb/rules/ (zapętlenie klawiatury)
       │         • Naprawa HISTFILE, wyłączenie zsh-newuser-install
       │         • Usunięcie obs-v4l2sink (OBS 27+ ma wbudowaną kamerę)
       │         • Usunięcie compress=zstd (ext4 != btrfs)
       │         • Konsolidacja repo justGame (brak ~/shintest)
       │         • Czystość git (exporty Godota rm --cached)
       │         • Zastąpienie nerd-dictation przez faster-whisper + dictate.py
       │         • Wybór whisper small (base za słaby, large za wolny)
       │
       ▼
  FUTURE  ──► Naprawa TTS, globalny hotkey voice-note, fake desktop Godot,
              FLESHCITY Vertical Slice, passthru.updateScript ZenNotes
```

---

## 15. ARCHIWUM — Co Masz w Systemie, ale Nie Używasz

To nie jest śmietnik. To **archiwum** — rzeczy które były aktywne, mogą wrócić, ale obecnie śpią w kodzie.

| Rzecz | Lokalizacja | Dlaczego w archiwum | Kiedy wrócić |
|-------|-------------|---------------------|-------------|
| `llama-cpp` | `home.nix` | Używasz Kimi (chmura) | Gdy chmura zawiedzie lub ceny wzrosną |
| `lmstudio` | `home.nix` | GUI do lokalnych modeli | Gdy chcesz eksperymentować bez terminala |
| `xdotool` | `home.nix` | Był do TTS/wprowadzania głosowego | Gdy TTS zacznie działać |
| `ydotool` | `home.nix` | Waylandowy xdotool | Gdy TTS zacznie działać |
| `faster-whisper` | `home.nix` | Działa do dupy, ale skrypt do Anki istnieje | Gdy naprawisz TTS |
| `espeak-ng` | `configuration.nix` | TTS backup | Gdy faster-whisper zawiedzie |
| `llm-code` alias | `aliases.zsh` | Start lokalnego OmniCoder | Gdy wrócisz do lokalnych LLM |
| `aider-code` alias | `aliases.zsh` | Start Aider z lokalnym modelem | Gdy wrócisz do lokalnych LLM |
| Porty 1234/1235 | — | llama-server | Nieaktywne |

---

## 16. ZASOBY

| Zasób | URL |
|-------|-----|
| NixOS Manual | https://nixos.org/manual/nixos/stable/ |
| NixOS Options | https://search.nixos.org/options |
| NixOS Packages | https://search.nixos.org/packages |
| Home Manager | https://nix-community.github.io/home-manager/ |
| Noctalia | https://github.com/noctalia-dev/noctalia-shell |
| Kimi CLI | https://github.com/MoonshotAI/kimi-cli |
| NixOS Wiki | https://wiki.nixos.org/wiki/Main_page |
| Moje Repo | `/etc/nixos` — Prawda jest w kodzie |

---

## 17. OSTATNIE SŁOWO

> **NixOS to nie dystrybucja. To paradygmat.**
>
> Ale Twój paradygmat ma oddech. Nie jest to ascetyczny monolit — to platforma z archiwum.
> Masz rzeczy których nie używasz, ale są w kodzie. I to jest OK.
>
> `/etc/nixos` to nie tylko config. To **infrastruktura jako kod** + **pamięć jako kod**.
> To backup Twojego braina — nie tylko tego co działa, ale tego co kiedyś działało
> i może znowu zadziałać.
>
> **Edytuj. Commituj. Rebuilduj. Ciesz się systemem który pamięta.**
>
> *A gdy budujesz FLESHCITY — pamiętaj: jeden korytarz, jedna operacja, jeden wróg.*

---

*Wygenerowano dla systemu `shin@nixos` • NixOS 25.11 • Flakes + Home Manager • Niri + Noctalia*
*Ostatnia aktualizacja: 2026-06-26 • Wersja 2.1 — Prawda z Kodu*
