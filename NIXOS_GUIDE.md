# NixOS & Zsh System Architecture Guide

Ten przewodnik opisuje strukturę Twojego systemu, filozofię NixOS oraz zasady zarządzania konfiguracją.

## Filozofia Systemu: Reprodukowalność i Deklaratywność

Twój system opiera się na **Nix Flakes** i **Home Manager**. Oznacza to, że:
1. **Prawda jest w kodzie:** Wszystko, co zainstalowane, musi być zadeklarowane w `/etc/nixos`.
2. **Niezmienność:** Nie instalujemy programów przez `sudo apt/dnf`. Dodajemy je do `environment.systemPackages` w `configuration.nix` i robimy `ns`.
3. **Reprodukowalność:** Dzięki `flake.lock` możesz odtworzyć identyczny system na innym komputerze.

---

## Struktura Plików (ASCII Tree)

```text
/etc/nixos/
├── flake.nix               <-- Punkt wejścia (zarządza wejściami jak Zen, Noctalia)
├── configuration.nix       <-- Konfiguracja systemowa (hardware, pakiety, usługi)
├── home.nix                <-- Konfiguracja użytkownika shin (pliki dotfiles, xdg)
├── ALIASES.md              <-- Spis aliasów systemowych
├── NIXOS_GUIDE.md          <-- Ten przewodnik
│
├── niri/                   <-- Konfiguracja kompozytora Niri
│   └── cfg/
│       └── keybinds.kdl    <-- Skróty klawiszowe (tu jest Twoje Alt+Y)
│
├── scripts/                <-- TU TRZYMAJ SKRYPTY (voice-note, brightness, itd.)
│
├── zsh-config/             <-- Zaawansowana konfiguracja Zsh
│   ├── aliases.zsh         <-- Tu dodawaj proste aliasy
│   ├── functions/          <-- TU TRZYMAJ FUNKCJE (np. nn.zsh)
│   │   ├── func_init.zsh   <-- Automatycznie ładuje wszystko z tego folderu
│   │   └── nn.zsh          <-- Twoja nowa funkcja do labeli i gita
│   └── init.zsh            <-- Główny plik ładujący moduły Zsh
│
└── noctalia/               <-- Konfiguracja Noctalia Shell
```

---

## Workflow: Jak wprowadzać zmiany?

1.  **Edytuj plik** w `/etc/nixos`.
2.  **Uruchom `nn opis_zmiany`**:
    - Zmieni label systemu (widoczny przy boocie).
    - Zrobi `git add` i `git commit` Twoich zmian.
3.  **Uruchom `ns`**:
    - Przebuduje system (`nixos-rebuild switch`).
    - Aktywuje nowe ustawienia.


--- 
**Status:** Migracja zakończona. Pakiety użytkownika i Zsh są teraz w `home.nix`.