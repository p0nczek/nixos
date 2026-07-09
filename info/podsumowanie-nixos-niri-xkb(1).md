# PODSUMOWANIE ROZMOWY: NixOS + Niri + Custom XKB Layout (PL+DE znaki na F13-F24)

## KONTEKST
Użytkownik (shin) na NixOS z compositorem Niri (Wayland) chce używać klawiszy
F13-F24 do wpisywania polskich (ąćęłńóśźż) i niemieckich (äöüß) znaków
bez modyfikatorów (bez AltGr, bez Compose).

## PROBLEM 1: QMK CLI nie działał (początkowy kontekst)
**Objaw:** `qmk compile` nie istniał jako subcommand, tylko `config, clone, console, env, setup`.

**Przyczyna:** Repozytorium `~/qmk_firmware` było niekompletne (brakowało `lib/`, `quantum/`,
`tmk_core/`, `paths.mk`). Prawdopodobnie przerwany clone lub sparse-checkout.

**Rozwiązanie:**
```bash
git sparse-checkout disable
git checkout .
```
To przywróciło brakujące pliki z indeksu gita.

---

## PROBLEM 2: Niri nie widzi layoutu "plde" (XKB na Wayland)
**Objaw:** Po dodaniu `layout "plde,ru"` w Niri config, klawiatura umierała przy reboocie.

**Przyczyna:** NixOS `services.xserver.xkb.extraLayouts` buduje custom xkeyboard-config
w `/nix/store/...`, ale Wayland (libxkbcommon) szuka layoutów w innych ścieżkach:
1. `~/.config/xkb`
2. `~/.xkb`
3. `/etc/xkb`
4. `/usr/share/X11/xkb` (systemowy)

Niri nie widziało `plde` w żadnej z tych ścieżek → fallback do `us` → klawiatura
ładowała się, ale F13-F24 to były zwykłe klawisze multimedialne (XF86*).

### Próba 1: `~/.config/xkb/rules/evdev`
Stworzenie `~/.config/xkb/rules/evdev` z `include %S/evdev` spowodowało
**NIESKOŃCZONĄ PĘTLĘ** — `include %S/evdev` w pliku `evdev` próbował załączyć
sam siebie. Niri crashował przy parsowaniu XKB → klawiatura umierała.

**Lekcja:** Plik `rules/evdev` w `~/.config/xkb/` **ZASTĘPUJE** całkowicie
systemowy evdev rules, nie rozszerza go.

### Próba 2: `environment.sessionVariables.XKB_CONFIG_EXTRA_PATH`
Dodanie `XKB_CONFIG_EXTRA_PATH = "/etc/xkb"` w `configuration.nix`.

**Dlaczego nie zadziałało:** `environment.sessionVariables` ustawia zmienne
przez PAM, ale Niri startuje przez `greetd` **przed** pełnym ustawieniem
środowiska PAM. Zmienna nie docierała do procesu Niri w momencie
inicjalizacji XKB.

**Lekcja:** `XKB_CONFIG_EXTRA_PATH` musi być ustawione **przed** uruchomieniem
Niri, nie w sesji użytkownika.

### Próba 3: `environment.etc."xkb/symbols/plde"`
Wystawienie pliku w `/etc/xkb/symbols/plde` przez NixOS.

**Dlaczego nie zadziałało:** Mimo że `/etc/xkb` jest domyślną ścieżką
libxkbcommon, Niri (uruchomione przez greetd) szukało w `/etc/X11/xkb`
(pierwsza ścieżka z `SYSTEMD_XKB_DIRECTORY`), a `/etc/xkb` było
"could not be added" (z logów Niri issue #1918).

---

## ROZWIĄZANIE FINALNE: Niri `file` option + `replace` w XKB

### Krok 1: Wygeneruj gotowy keymap
```bash
XKB_CONFIG_EXTRA_PATH=/etc/xkb xkbcli compile-keymap \
  --layout plde --options grp:caps_toggle > ~/.config/niri/keymap.xkb
```

### Krok 2: W Niri config.kdl użyj `file`
```kdl
input {
    keyboard {
        xkb {
            file "~/.config/niri/keymap.xkb"
        }
        numlock
    }
}
```

To **omija całą logikę szukania layoutów** — Niri wczytuje gotowy plik.

### Krok 3: Fix `XF86*` w wygenerowanym keymapie
Wygenerowany plik miał **DRUGI PROBLEM**:
```xkb
key <FK13> { [ XF86Tools, Aogonek ] };      // Bez Shift = multimedia!
key <FK14> { [ XF86Launch5, Cacute ] };    // Z Shift = polski (OK)
```

**Przyczyna:** Evdev rules automatycznie dodają `inet(evdev)` który definiuje
F13-F24 jako klawisze multimedialne (XF86*). Przy mergowaniu z `plde`,
`inet(evdev)` miał priorytet dla poziomu 1 (bez Shift).

**Rozwiązanie:** Użycie `replace` w pliku źródłowym `symbols/plde`:
```xkb
replace key <FK13> { [ aogonek, Aogonek ] };  // Nadpisuje XF86Tools
replace key <FK14> { [ cacute, Cacute ] };
// ... itd dla wszystkich F13-F24
```

Albo ręczna edycja wygenerowanego `keymap.xkb`:
```xkb
key <FK13> { [ aogonek, Aogonek ] };  // Zamiast [ XF86Tools, Aogonek ]
```

### Krok 4: Reload bez rebootu
```bash
niri msg action reload-config
```

---

## PROBLEM 3: FK23 i FK24 miały dziwne typy
**Objaw:** W wygenerowanym keymapie FK23 i FK24 miały niestandardowe typy:
```xkb
key <FK23> {
    type= "PC_SHIFT_SUPER_LEVEL2",
    symbols[1]= [ F23, XF86Assistant ]
};
key <FK24> {
    type= "PC_CONTROL_SUPER_LEVEL2",
    symbols[1]= [ F24, XF86TouchpadToggle ]
};
```

**Przyczyna:** Błąd w generowaniu przez xkbcli — niepoprawne mergowanie
z `inet(evdev)` dla ostatnich dwóch klawiszy.

**Rozwiązanie:** Ręczna poprawa na standardowy format:
```xkb
key <FK23> { [ odiaeresis, Odiaeresis ] };
key <FK24> { [ udiaeresis, Udiaeresis ] };
```

---

## PROBLEM 4: Błąd składni w configuration.nix
**Objaw:** Po próbie dodania `environment.etc."xkb/symbols/plde".text = ...`
bez odpowiedniego opakowania stringa:
```
error: syntax error, unexpected '"', expecting '.' or '='
at /etc/nixos/configuration.nix:8:13:
     8| xkb_symbols "plde" {
      |             ^
```

**Przyczyna:** Treść XKB została wklejona bezpośrednio do `configuration.nix`
jako raw text, ale Nix to język programowania — wymaga odpowiedniego
quotingu (`''...''` lub `"..."`).

**Rozwiązanie:** Użycie Nix "indented string" (`''...''`):
```nix
environment.etc."xkb/symbols/plde".text = ''
  xkb_symbols "plde" {
    ...
  };
'';
```

---

## PODSUMOWANIE WNIOSKÓW

| Problem | Przyczyna | Rozwiązanie |
|---------|-----------|-------------|
| QMK CLI bez subcommandów | Niekompletne repo | `git sparse-checkout disable` |
| Klawiatura umiera po reboocie | `~/.config/xkb/rules/evdev` z self-include | Usunąć `rules/` całkowicie |
| `xkbcli list` nie widzi `plde` | Brak rejestracji w rules | Nie potrzebne — `compile-keymap` działa bez |
| `environment.sessionVariables` nie działa | Niri startuje przed PAM | Użyj `file` w Niri lub wrappera w greetd |
| F13 daje XF86Tools zamiast ą | `inet(evdev)` nadpisuje poziom 1 | `replace key` w symbols lub edycja keymap |
| FK23/FK24 mają dziwne typy | Błąd generowania xkbcli | Ręczna poprawa w pliku .xkb |
| Syntax error w configuration.nix | Brak quoting w Nix | Użyj `''...''` (indented string) |

## FINALNA KONFIGURACJA (działająca)

### `~/.config/niri/keymap.xkb` (lub `/etc/nixos/niri/keymap.xkb`):
```xkb
xkb_keymap {
  xkb_keycodes  { include "evdev+aliases(qwerty)" };
  xkb_types     { include "complete" };
  xkb_compat    { include "complete" };
  xkb_symbols   { include "pc+plde+inet(evdev)" };
};
// + ręczna poprawa F13-F24 (usunięcie XF86* z poziomu 1)
// + ręczna poprawa FK23/FK24 (usunięcie dziwnych typów)
```

### `input.kdl` w Niri:
```kdl
input {
    keyboard {
        xkb {
            file "/etc/nixos/niri/keymap.xkb"
        }
        numlock
    }
}
```

### Znaki:
- **Polskie:** F13=ą, F14=ć, F15=ę, F16=ł, F17=ń, F18=ó, F19=ś, F20=ź, F21=ż
- **Niemieckie:** F22=ä, F23=ö, F24=ü
- **Scroll Lock:** ß
