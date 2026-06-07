# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs,lib, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  system.nixos.label = "nhTest";

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  # Auto-login i start Niri przez greetd
         services.greetd = {
           enable = true;
           settings = {
            initial_session = {
               command = "niri";
               user = "shin";
             };
             default_session = {
              command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri";
             user = "greeter";
            };
         };
        };

     # Opcjonalne: Odblokowanie keyringu przy auto-loginie
      security.pam.services.greetd.enableGnomeKeyring = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "fuse" ];
  programs.fuse.userAllowOther = true;

  networking.hostName = "nixos"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;
  home-manager.backupFileExtension = "backup";
  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Włączenie obsługi Flakes i komend nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Wymagania systemowe dla modułów Noctalia (bateria, sieć, bluetooth, profile zasilania)
  #networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Włączenie kompozytora Niri na poziomie systemu
  programs.niri.enable = true;

  # Konfiguracja XDG Portals dla Screen Sharing (Wayland/Niri)
  xdg.portal = {
   	enable = true;
   	extraPortals = [
     		 pkgs.xdg-desktop-portal-wlr
     		 pkgs.xdg-desktop-portal-gtk
 	];

	config = {
    	niri = {
    		default = lib.mkForce [ "wlr" "gtk" ];
      		"org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
      		"org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
      		"org.freedesktop.impl.portal.Access" = [ "gtk" ];
      		"org.freedesktop.impl.portal.Notification" = [ "gtk" ];
   	 	};
  	};
  };

  programs.nix-ld.enable = true;
  programs.xwayland.enable = true;

  # Wsparcie dla kalendarza i wydarzeń w Noctalia
  services.gnome.evolution-data-server.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    # Realtime audio
    security.pam.loginLimits = [
      { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
      { domain = "@audio"; item = "rtprio"; type = "-"; value = "99"; }
      { domain = "@audio"; item = "nice"; type = "-"; value = "-19"; }
    ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  users.users.root.initialPassword = "nixos";

  users.users.shin = {
    isNormalUser = true;
    description = "shin";
    extraGroups = [ "networkmanager" "wheel" "audio" "i2c" ];
    packages = with pkgs; [];
  };

  # Install firefox.
  programs.firefox.enable = true;
  programs.steam.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  hardware.i2c.enable = true;

  services.flatpak.enable = true;

systemd.services.flatpak-repo = {
  wantedBy = [ "multi-user.target" ];
  path = [ pkgs.flatpak ];
  script = ''
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  '';
};

  environment.systemPackages = with pkgs; [
   nh   inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
   home-manager
   xwayland-satellite
    atuin          # historia shella (widzę w .zshrc)
     # Fonty - konkretne, nie cała paczka nerdfonts
    nerd-fonts.jetbrains-mono
     # lub jeśli powyższe nie działa:
     # jetbrains-mono
    flatpak
    appimage-run
    fuse
    fuse3
    ffmpeg
     # Nowoczesne CLI
    eza
    bat
    fd
    ripgrep
    fzf
    zoxide
    zsh
    libnotify
    nix-ld
    wayland
    libxkbcommon
    libGL
    ddcutil        # sterowanie DDC/CI
    ddcui          # GUI do ddcutil (opcjonalnie)
    brightnessctl
      # Reszta
    kitty
    micro
    fastfetch
    (btop.override { cudaSupport = true;   })     
    nvtopPackages.nvidia
    steam
    git            # lokalny git
    # Komunikacja
    # File manager
    nautilus
    # Clipboard
    cliphist
    wl-clipboard
    # Launcher
    fuzzel
 	qjackctl          # GUI do patchbay JACK/PipeWire
 	yabridge          # bridge VST Windows → Linux
 	yabridgectl       # CLI do zarządzania yabridge
 	wine 
    wineWowPackages.stable
    wineWow64Packages.stable
    winetricks
 	       # kontrola głośności PipeWire
 	libjack2
 	pipewire
 	pipewire.jack
	           # EQ, kompresor, reverb, delay, gate, limiter
    # Streaming sunshine
    # Python dla trackera
    # Inne
    wtype
    brightnessctl
    networkmanagerapplet];

fileSystems."/mnt/dane" = {
  device = "/dev/disk/by-uuid/b8b5b9bb-0e35-4bb5-b9e0-4a306f2fb1ec";
  fsType = "ext4";
  options = [ "defaults" "noatime" ];
};

systemd.services.nvidia-power-limit = {
  description = "Set NVIDIA GPU power limit";
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${config.boot.kernelPackages.nvidia_x11.bin}/bin/nvidia-smi -pl 203";
  };
  wantedBy = [ "multi-user.target" ];
  after = [ "systemd-modules-load.service" ];
};

# Zamknięty sterownik NVIDIA (wymagany dla Discord, gier, GPU acceleration)
services.xserver.videoDrivers = [ "nvidia" ];
hardware.nvidia = {
  modesetting.enable = true;
  powerManagement.enable = false;
  open = false;  # zamknięty sterownik, lepszy performance
  nvidiaSettings = true;
  package = config.boot.kernelPackages.nvidiaPackages.stable;
};

# Włącz OpenGL (dla Mesa/NVIDIA)
hardware.graphics = {
  enable = true;
  enable32Bit = true;  # dla Steam, gier 32-bit
};

  environment.variables.FLAKE = "/etc/nixos";
  system.stateVersion = "25.11"; # Did you read the comment?

}
