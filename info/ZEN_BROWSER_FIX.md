Dobra, zróbmy to porządnie w /etc/nixos żebyś za pół roku nie musiał pamiętać co i jak.
Co dodajemy do home.nix
Znajdź sekcję home.sessionVariables (już tam jest) i dodaj MOZ_WEBRENDER = "0":
nix

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "0";
    NIXOS_OZONE_WL = "0";
    MOZ_WEBRENDER = "0";        # ← DODAJ TO
    FLAKE = "/etc/nixos";
  };

Co dodajemy do configuration.nix
nix

  networking.enableIPv6 = false;
  # networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];  # opcjonalne, jak chcesz

Nowy plik: /etc/nixos/ZEN_BROWSER_FIX.md
Stwórz dokumentację żebyś wiedział co i dlaczego:
bash

sudo micro /etc/nixos/ZEN_BROWSER_FIX.md

Wklej:
Markdown
Copy
Code Preview

# Zen Browser Fix — NVIDIA + Wayland

## Problem (2026-07-04)
Zen Browser (Firefox fork) crashował WebGL w pętli:
- `WebGL context was lost` x100 na stronach z fingerprintingiem (trustdecision.com)
- Strony ładowały się z 3-5 razu lub w ogóle
- Chromium też miał błędy: `Wayland + Vulkan incompatible`
- Steam działał bo używa X11/Proton, nie natywnego Wayland WebGL

## Root Cause
NVIDIA closed driver (RTX 3060) + Wayland + WebRender = death.
Firefox WebRender (GPU renderer) crashuje na NVIDIA pod Waylandem.
WebGL stron próbował odtworzyć context, crashował znowu → loop.

## Fix Applied

### 1. Wyłączenie IPv6 (system)
W `configuration.nix`:
```nix
networking.enableIPv6 = false;

Broken IPv6 powodował DNS timeouty — przeglądarki próbowały IPv6,
czekały 5-10s, fallback na IPv4. Steam nie miał tego problemu.
2. Wymuszenie XWayland dla przeglądarek (home)
W home.nix home.sessionVariables:
nix

MOZ_ENABLE_WAYLAND = "0";   # Zen/Firefox → XWayland
NIXOS_OZONE_WL = "0";       # Chromium/Electron → XWayland
MOZ_WEBRENDER = "0";        # Wyłącza GPU renderer całkowicie

3. Wyłączenie WebGL w Zen (about:config)
Otwórz about:config, ustaw:

    webgl.disabled = true
    layers.acceleration.disabled = true
    gfx.webrender.software = true
    media.ffmpeg.vaapi.enabled = false

To jest per-profile, nie da się tego zrobić przez NixOS.
Po reinstalacji/Zen update trzeba zrobić ręcznie.
Trade-offs

    WebGL wyłączony → niektóre strony (Google Earth, WebGL games) nie działają
    Software rendering → slightly wyższe CPU usage, niższe GPU usage
    XWayland → brak natywnych gestów Wayland w przeglądarkach (OK dla desktop)

Test
Po fixie: Failed to create WebGL context: WebGL is currently disabled
(zamiast crash loopa) — to OK, oczekiwane zachowanie.
Related

    Niri compositor działa na Wayland natywnie (nie dotknięte)
    Steam/Proton działał zawsze (X11)
    Godot 4 używa OpenGL (Compatibility renderer) — nie dotknięte

plain


## Git commit

```bash
nn "zenBrowserNvidiaWaylandFix"
nos

Za pół roku otworzysz ZEN_BROWSER_FIX.md i będziesz wiedział wszystko.
