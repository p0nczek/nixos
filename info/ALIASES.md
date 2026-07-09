# 🛠️ NixOS & Zsh Aliases Guide

Ten plik zawiera zestawienie aliasów i funkcji ułatwiających zarządzanie systemem NixOS w Twojej konfiguracji.

## ❄️ Zarządzanie Systemem (NixOS Flakes)

| Alias | Komenda | Opis |
|-------|---------|------|
| `ns` | `sudo nixos-rebuild switch --flake /etc/nixos#nixos` | Przebudowuje system i aktywuje zmiany. |

## 📦 Zarządzanie Konfiguracją (Git + /etc/nixos)

Dla ułatwienia pracy z repozytorium systemowym, używamy aliasów operujących bezpośrednio na `/etc/nixos`.

| Alias | Opis |
|-------|------|
| `nstat` | Pokazuje status zmian w plikach konfiguracyjnych (`git status`). |
| `nlog`  | Pokazuje ostatnie 10 commitów (`git log --oneline`). |
| `ndiff` | Pokazuje szczegółowe zmiany w kodzie przed commitem (`git diff`). |

### 🚀 Funkcja ncom (Smart Commit)
Główna funkcja do szybkiego zapisywania zmian.

**Użycie:**
```zsh
ncom <nazwa_pliku_lub_folderu> "[opcjonalna wiadomość]"
```

**Przykłady:**
- `ncom kitty` -> automatycznie doda folder kitty i zrobi commit "update: kitty".
- `ncom niri "poprawka animacji"` -> doda zmiany w niri z Twoją wiadomością.
- `ncom configuration.nix "nowy program"` -> doda zmiany w głównym pliku.

## ⌨️ Ustawienia Shell (Zsh)

- **Autokorekta:** Wyłączona (`unsetopt CORRECT`). Koniec z irytującym `zsh: correct to... [nyae]?`.
- **Ścieżki:** Funkcje używają pełnych ścieżek (`/run/current-system/sw/bin/`), co zapewnia działanie nawet w specyficznych środowiskach.

---
*Plik wygenerowany przez Twojego asystenta Gemini CLI. 🐈‍⬛*
