{ pkgs, inputs, ... }:

{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  # Dopasuj wersję do swojej instalacji (np. "24.11" lub "25.05")
  home.stateVersion = "25.11"; 

  # Konfiguracja powłoki Noctalia
  programs.noctalia-shell = {
    enable = true;
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.override { calendarSupport = true; };
    
    settings = {
      bar = {
        position = "top";
        density = "default";
      };
    };
  };

  # Bezpośrednia konfiguracja Niri przez plik KDL (odporna na błędy modułów)
  xdg.configFile."niri/config.kdl".text = ''
    // Autostart powłoki Noctalia wraz z Niri
    spawn-at-startup "noctalia-shell"

    // Skróty klawiszowe powiązane z powłoką Noctalia (IPC)
    binds {
        "Mod+Space" { spawn "noctalia-shell" "ipc" "call" "launcher" "toggle"; }
        "Mod+Escape" { spawn "noctalia-shell" "ipc" "call" "sessionMenu" "toggle"; }
        "Mod+L" { spawn "noctalia-shell" "ipc" "call" "lockScreen" "lock"; }
        
        // Klawisze multimedialne dżwięku
        "XF86AudioLowerVolume" { spawn "noctalia-shell" "ipc" "call" "volume" "decrease"; }
        "XF86AudioRaiseVolume" { spawn "noctalia-shell" "ipc" "call" "volume" "increase"; }
        "XF86AudioMute"        { spawn "noctalia-shell" "ipc" "call" "volume" "muteOutput"; }
    }
  '';
}
