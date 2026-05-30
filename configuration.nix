# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs,lib, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];


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

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

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
  
  programs.xwayland.enable = true;

  # Wsparcie dla kalendarza i wydarzeń w Noctalia
  services.gnome.evolution-data-server.enable = true;

  # ... Reszta Twojej domyślnej konfiguracji (bootloader, strefa czasowa, użytkownicy itp.)
  # Upewnij się, że Twój użytkownik należy do grupy "networkmanager"

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
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
users.defaultUserShell = pkgs.zsh;
programs.zsh.enable = true;
  
  users.users.root.initialPassword = "nixos";

  users.users.shin = {
    isNormalUser = true;
    description = "shin";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  
  environment.systemPackages = with pkgs; [
   inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
   home-manager

  
    atuin          # historia shella (widzę w .zshrc)
      
     # Fonty - konkretne, nie cała paczka nerdfonts
    nerd-fonts.jetbrains-mono
     # lub jeśli powyższe nie działa:
     # jetbrains-mono
      
     # Nowoczesne CLI
    eza
    bat
    fd
    ripgrep
    fzf
    zoxide
    zsh
    libnotify
      
      # Reszta
    kitty
    micro
    fastfetch
    btop     
      
    
    git            # lokalny git
    
    # Komunikacja
    telegram-desktop
    vesktop
    discord    
    # File manager
    nautilus
    
    # Clipboard
    cliphist
    wl-clipboard
    
    # Launcher
    fuzzel
    
    
    # Streaming
    sunshine
    
    # Python dla trackera
    python3
    
    # Inne
    wtype
    brightnessctl
    pamixer
    playerctl
    pavucontrol
    networkmanagerapplet



    lmstudio
  ];

fileSystems."/mnt/dane" = {
  device = "/dev/disk/by-uuid/03c63f99-9000-4dee-b104-5cc796e23ffa";
  fsType = "btrfs";
  options = [ "defaults" "noatime" "compress=zstd" ];
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
 
  system.stateVersion = "25.11"; # Did you read the comment?

}
