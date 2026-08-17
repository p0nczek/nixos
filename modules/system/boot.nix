{ config, pkgs, lib, ... }:
{
  # ─── Bootloader ───
  boot.tmp.useTmpfs = true;
  # Wyłącz core dumps
  systemd.coredump.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;
  boot.plymouth.enable = false;
  boot.loader.timeout = 1;

  boot.supportedFilesystems = [ "fuse" ];
  # boot.supportedFilesystems = [ "ntfs" ];

  # ─── Fonts ───
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

  # ─── Kernel modules (OBS virtual camera) ───
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=10 card_label="OBS Virtual Camera" exclusive_caps=1
  '';

  # ─── Kernel params — jeden, nie zdublowany zestaw ───
  boot.kernelParams = [
    "quiet"
    "rd.systemd.show_status=false"
    "systemd.show_status=false"
    "loglevel=3"
    # Wyłączenie portów szeregowych — systemd nie będzie na nie czekał
    "8250.nr_uarts=0"
    # Jeśli NIE masz LUKS opartego o TPM:
    "tpm_tis.force=0"
    "tpm_crb.force=0"
    "nvidia-drm.modeset=1"
  ];

  # Blacklist modułów TPM — tylko gdy realnie nie masz żadnych urządzeń LUKS
  boot.blacklistedKernelModules = lib.mkIf (config.boot.initrd.luks.devices == { }) [
    "tpm"
    "tpm_tis"
    "tpm_crb"
    "tpmrm"
  ];

  # ─── Initrd ───

  

  # ─── Sieć — nie czekaj na IP przy boot ───
  systemd.services.NetworkManager-wait-online.enable = false;

  # ─── Flatpak repo — nie wymagaj network-online.target ───
  systemd.services.flatpak-repo = {
    after = lib.mkForce [ "network.target" "multi-user.target" ];
    wants = lib.mkForce [ "network.target" ];
  };
  
  # Ogranicz journald
services.journald.extraConfig = ''
  SystemMaxUse=500M
  MaxFileSec=7day
'';


# Automatyczne czyszczenie /tmp i /var/tmp
systemd.tmpfiles.rules = [
  "D /var/tmp 0755 root root 7d -"
];
}
