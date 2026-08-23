{ config, pkgs, ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;  # false, chyba że masz problemy po suspend/resume
    open = true;                     # ZMIANA: RTX 3060 (Ampere) w pełni wspiera open module
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  hardware.nvidia.nvidiaPersistenced = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ nvidia-vaapi-driver ];  # DODANE
  };

  environment.variables = {
    LIBVA_DRIVER_NAME = "nvidia";       # DODANE
    MOZ_DISABLE_RDD_SANDBOX = "1";      # DODANE
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