{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

environment.etc."xkb/symbols/plde".text = ''
    xkb_symbols "plde" {
      include "us(basic)"
      name[Group1] = "PL+DE via F13-F24 + ScrollLock";

      replace key <FK13> { [ aogonek,    Aogonek    ] };
      replace key <FK14> { [ cacute,     Cacute     ] };
      replace key <FK15> { [ eogonek,    Eogonek    ] };
      replace key <FK16> { [ lstroke,    Lstroke    ] };
      replace key <FK17> { [ nacute,     Nacute     ] };
      replace key <FK18> { [ oacute,     Oacute     ] };
      replace key <FK19> { [ sacute,     Sacute     ] };
      replace key <FK20> { [ zacute,     Zacute     ] };
      replace key <FK21> { [ zabovedot,  Zabovedot  ] };

      replace key <FK22> { [ adiaeresis, Adiaeresis ] };
      replace key <FK23> { [ odiaeresis, Odiaeresis ] };
      replace key <FK24> { [ udiaeresis, Udiaeresis ] };

      replace key <SCLK> { [ ssharp,     U1E9E      ] };
    };
  '';


environment.sessionVariables = {
  XKB_CONFIG_EXTRA_PATH = "/etc/xkb";
};
  # ============================================================================
  #  SYSTEM LABEL
  # ============================================================================
  # Managed by the `nn` helper (updates label + git commit). Do not edit manually.
  system.nixos.label = "test_push_";

  # ============================================================================
  #  HOME MANAGER (module integration)
  # ============================================================================
  # These are required because Home Manager is imported as a NixOS module
  # inside flake.nix. They ensure HM shares the system pkgs instance.
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";

  # ============================================================================
  #  BOOT
  # ============================================================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "fuse" ];

  # ============================================================================
  #  FILESYSTEMS
  # ============================================================================
  fileSystems."/mnt/dane" = {
    device = "/dev/disk/by-uuid/b8b5b9bb-0e35-4bb5-b9e0-4a306f2fb1ec";
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  fonts = {
    enableDefaultPackages = true;
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "DejaVu Serif" ];
        sansSerif = [ "DejaVu Sans" ];
        monospace = [ "DejaVu Sans Mono" ];
      };
    };
  };

  # ============================================================================
  #  NETWORKING
  # ============================================================================
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.enableIPv6 = false;

  # ============================================================================
  #  LOCALE & TIME
  # ============================================================================
  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT    = "de_DE.UTF-8";
    LC_MONETARY       = "de_DE.UTF-8";
    LC_NAME           = "de_DE.UTF-8";
    LC_NUMERIC        = "de_DE.UTF-8";
    LC_PAPER          = "de_DE.UTF-8";
    LC_TELEPHONE      = "de_DE.UTF-8";
    LC_TIME           = "de_DE.UTF-8";
  };



 # services.xserver.xkb = {
 #   layout = "us";
#    variant = "";
 # };
boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
boot.kernelModules = [ "v4l2loopback" ];
boot.extraModprobeConfig = ''
  options v4l2loopback devices=1 video_nr=10 card_label="OBS Virtual Camera" exclusive_caps=1
'';


  # ============================================================================
  #  NIX SETTINGS
  # ============================================================================
  nixpkgs.config.allowUnfree = true;

  

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@wheel" ];
    substituters = [
      "https://cache.nixos.org"
      "https://noctalia.cachix.org"
      "https://vicinae.cachix.org" 
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc=" 
    ];
  };

  # ============================================================================
  #  HARDWARE
  # ============================================================================
  # NVIDIA (closed driver — better performance for RTX 3060)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # OpenGL / graphics (32-bit for Steam / Wine)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # External monitor control via DDC/CI
  hardware.i2c.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;

  # FUSE (AppImage, Flatpak, user mounts)
  programs.fuse.userAllowOther = true;


  # ============================================================================
  #  POWER & THERMAL
  # ============================================================================
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  systemd.services.nvidia-power-limit = {
    description = "Set NVIDIA GPU power limit";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.boot.kernelPackages.nvidia_x11.bin}/bin/nvidia-smi -pl 203";
    };
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
  };

  # ============================================================================
  #  AUDIO
  # ============================================================================
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Realtime audio limits
  security.pam.loginLimits = [
    { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "@audio"; item = "rtprio";  type = "-"; value = "99"; }
    { domain = "@audio"; item = "nice";   type = "-"; value = "-19"; }
  ];

  # ============================================================================
  #  DISPLAY / DESKTOP
  # ============================================================================
  # Compositor
  programs.niri.enable = true;
  programs.xwayland.enable = true;

  # Auto-login via greetd -> Niri
 services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "sh -c 'export XKB_CONFIG_EXTRA_PATH=/etc/xkb; exec niri'";
        user = "shin";
      };
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd \"sh -c 'export XKB_CONFIG_EXTRA_PATH=/etc/xkb; exec niri'\"";
        user = "greeter";
      };
    };
  };

  # Unlock GNOME keyring on login
  security.pam.services.greetd.enableGnomeKeyring = true;

  # XDG Portals (screen sharing, file open, etc.)
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      niri = {
        default = lib.mkForce [ "wlr" "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast"     = [ "wlr" ];
        "org.freedesktop.impl.portal.Screenshot"     = [ "wlr" ];
        "org.freedesktop.impl.portal.Access"         = [ "gtk" ];
        "org.freedesktop.impl.portal.Notification"   = [ "gtk" ];
      };
    };
  };

  # Noctalia calendar integration
  services.gnome.evolution-data-server.enable = true;

  # ============================================================================
  #  PRINTING
  # ============================================================================
  services.printing.enable = true;

  # ============================================================================
  #  DYNAMIC LINKING (nix-ld)
  # ============================================================================
  programs.nix-ld.enable = true;

  # ============================================================================
  #  FLATPAK
  # ============================================================================
  services.flatpak.enable = true;

  systemd.services.flatpak-repo = {
  description = "Add Flathub remote";
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
  };
  wants  = [ "network-online.target" ];
  after  = [ "network-online.target" ];
  wantedBy = [ "multi-user.target" ];
  path = [ pkgs.flatpak ];
  script = ''
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  '';
};
  # ============================================================================
  #  SYSTEM-WIDE APPLICATIONS
  # ============================================================================
  # Only enable modules that must run at system level (udev rules, 32-bit libs,
  # kernel modules). The actual application packages belong in home.nix.
  programs.steam.enable = true;
  # programs.firefox.enable = true;  # optional — enable if you want Firefox system-wide

  # ============================================================================
  #  USERS
  # ============================================================================
  # Root is locked — use sudo only.
  users.users.root.hashedPassword = "!";

  users.users.shin = {
    isNormalUser = true;
    description = "shin";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "audio" "i2c" "video" ];
    packages = with pkgs; [];
  };

  # Zsh must be enabled at system level because it is used as a login shell.
  programs.zsh.enable = true;



programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true; 
    plugins = [ pkgs.obs-studio-plugins.droidcam-obs ];
 };
  

  # ============================================================================
  #  SYSTEM PACKAGES (bare minimum — rescue & hardware only)
  # ============================================================================
  # Everything else (eza, bat, obsidian, reaper, yabridge, wine, etc.)
  # belongs in home.nix under home.packages.
  environment.systemPackages = with pkgs; [
    # --- NixOS tooling ---
    nh
    git
    jujutsu

    # --- Recovery / rescue TUI ---
    kitty
    micro

    # --- Hardware control ---
    ddcutil
    ddcui
    brightnessctl

    # --- Wayland / PipeWire basics ---
    xwayland-satellite
    wl-clipboard
    wtype
    networkmanagerapplet

    # --- Flatpak / AppImage runtime ---
    flatpak
    appimage-run
    fuse
    fuse3
	nodejs_22

    # --- System libraries (nix-ld, some apps need these in PATH) ---
    nix-ld
    wayland
    libxkbcommon
    libGL

	jq

	android-tools
	adb-sync
	v4l-utils

	

    qmk
    pkgsCross.avr.buildPackages.gcc
    pkgsCross.avr.buildPackages.binutils
    pkgsCross.avr.avrlibc
    dfu-programmer
    avrdude
    gnumake

    gpu-screen-recorder-gtk
    #qmk-cornemykeyboard

    espeak-ng
    pipewire
    pipewire.jack
  ];
  services.udev.packages = [ pkgs.qmk-udev-rules ];

  security.wrappers.gsr-kms-server = {
    source = "${pkgs.gpu-screen-recorder}/bin/gsr-kms-server";
    capabilities = "cap_sys_admin+ep";
    owner = "root";
    group = "root";
  };

  # ============================================================================
  #  MISC
  # ============================================================================
  # This value determines the NixOS release with which your system is compatible.
  # It should NOT be changed after installation (it controls data-migration
  # logic). Keep the value from the release you originally installed.
  system.stateVersion = "25.11";
}
