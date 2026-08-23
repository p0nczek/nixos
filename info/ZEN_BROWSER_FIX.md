# Zen Browser Fix — NVIDIA + Wayland

## Status: v2 (2026-08-23) — zastępuje poprzedni fix z 2026-07-04

Poprzedni fix (patrz niżej, sekcja "Historia") był obejściem objawu, nie
naprawą przyczyny. Wyłączał całą akcelerację GPU w przeglądarce, co
naprawiło crash loop WebGL kosztem wydajności całej przeglądarki
(software rendering, brak WebGL, XWayland zamiast natywnego Waylanda).

Prawdziwa przyczyna: `hardware.nvidia.open = false` (closed-source
kernel module Nvidii) źle współpracuje z WebRender + wlroots (niri)
na Waylandzie. RTX 3060 to Ampere — w pełni wspiera **open-source**
kernel module Nvidii, który nie ma tego problemu.

## Root Cause (poprawiona diagnoza)

- `open = false` (proprietary/closed Nvidia kernel module) + WebRender
  + wlroots (niri) → niestabilna kompozycja GPU → WebGL crashuje
  w pętli (`WebGL context was lost` x100).
- Obejście z v1 (wyłączenie WebGL/akceleracji) usuwało crash, ale
  też całą wydajność GPU.
- Prawdziwy fix: przełączenie na `open = true` (open kernel module,
  dojrzały od architektury Turing/Ampere wzwyż) + dodatkowe flagi
  dla wlroots.

## Fix Applied (v2 — aktualny)

### 1. `modules/system/nvidia.nix`

```nix
{ config, pkgs, ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;  # true tylko jeśli masz problemy po suspend/resume
    open = true;                     # ← KLUCZOWA ZMIANA: RTX 3060 = Ampere, w pełni wspierane
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  hardware.nvidia.nvidiaPersistenced = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ nvidia-vaapi-driver ];
  };

  environment.variables = {
    LIBVA_DRIVER_NAME = "nvidia";
    MOZ_DISABLE_RDD_SANDBOX = "1";
  };

  hardware.i2c.enable = true;
  hardware.bluetooth.enable = true;
  programs.fuse.userAllowOther = true;

  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  systemd.services.nvidia-power-limit = {
    description = "Set NVIDIA GPU power limit";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.boot.kernelPackages.nvidia_x11.bin}/bin/nvidia-smi -pl 203";
    };
    wantedBy = [ "multi-user.target" ];
    after = [ "nvidia-persistenced.service" ];
    requires = [ "nvidia-persistenced.service" ];
  };
}
```

### 2. `modules/system/desktop.nix`

Dodane zmienne środowiskowe sesji (na poziomie systemowym, nie home):

```nix
environment.sessionVariables = {
  WLR_NO_HARDWARE_CURSORS = "1";  # fix na freeze/artefakty kursora, wlroots+Nvidia
  NIXOS_OZONE_WL = "1";           # Electron/Chromium native Wayland
  MOZ_ENABLE_WAYLAND = "1";       # Zen/Firefox native Wayland
};
```

### 3. `home.nix` — COFNIĘTE ustawienia z v1

```nix
home.sessionVariables = {
  MOZ_ENABLE_WAYLAND = "1";   # było "0" w v1 — WRÓCONE do natywnego Waylanda
  NIXOS_OZONE_WL = "1";       # było "0" w v1 — WRÓCONE
  # MOZ_WEBRENDER = "0";      # USUNIĘTE CAŁKOWICIE — to wyłączało GPU renderer
  FLAKE = "/etc/nixos";
};
```

### 4. `about:config` w Zen — zresetowane flagi z v1

Otwórz `about:config`, znajdź każdy z poniższych, kliknij ikonę
resetu (strzałka cofania) obok wartości, żeby wrócić do defaultu
zamiast trzymać ręcznie ustawione `true`:

| Flaga | v1 (błędne) | v2 (poprawne) |
|---|---|---|
| `webgl.disabled` | `true` | reset → `false` |
| `layers.acceleration.disabled` | `true` | reset → `false` |
| `gfx.webrender.software` | `true` | reset → `false` |
| `media.ffmpeg.vaapi.enabled` | `false` | reset → `true` |

### 5. `networking.enableIPv6 = false`

To ustawienie z v1 zostaje bez zmian — dotyczyło DNS timeoutów,
niezwiązane z problemem WebGL/GPU. Jeśli faktycznie pomagało,
nie ma powodu go cofać.

## Weryfikacja fixa

Po `sudo nixos-rebuild switch` + **pełnym reboocie** (zmiana
`open = false → true` przebudowuje moduł kernela, samo `switch`
nie wystarczy):

```bash
vainfo
```

Powinno pokazać `Driver version: VA-API NVDEC driver` bez błędów,
z obsługą profili H264/HEVC/AV1.

W Zen, `about:support` → sekcja Graphics:

- `WebGL 1/2 Renderer` → `NVIDIA Corporation -- NVIDIA GeForce RTX 3060`
  (nie SwiftShader / puste pole)
- `Compositing` → `WebRender` (nie `WebRender (software)`)
- `HW_COMPOSITING` → `available` (nie `disabled by layers.acceleration.disabled`)

## Trade-offs (v2)

- Pełna akceleracja GPU przywrócona — WebGL, Figma, dekodowanie
  wideo działają jak powinny.
- Natywny Wayland zamiast XWayland — może ujawnić inne, drobniejsze
  bugi Wayland-specific w niektórych stronach/rozszerzeniach,
  ale generalnie stabilniejsze i szybsze niż XWayland.
- Jeśli WebGL crash loop wróci mimo `open = true`, to znak że
  problem nie był w closed/open module, tylko np. w konkretnej
  wersji sterownika — wtedy warto sprawdzić changelog
  `nvidiaPackages` i ew. przypiąć starszą stabilną wersję zamiast
  ponownie wyłączać całą akcelerację.

## Historia — v1 (2026-07-04, PRZESTARZAŁE)

Poprzedni fix wyłączał WebGL, akcelerację GPU i wymuszał XWayland
jako obejście crash loopa. Działał (crash znikał), ale kosztem
wydajności całej przeglądarki — de facto software rendering.
Zachowane tu wyłącznie jako kontekst historyczny, **nie stosować**.

## Related

- Niri compositor działa na Wayland natywnie (nie dotknięte).
- Steam/Proton działa zawsze przez X11, nie dotyczy tego fixa.
- Godot 4 (Compatibility renderer, OpenGL) — nie dotknięte.

## Git commit

```bash
nn "zenBrowserNvidiaOpenKernelFix"
nos
```
