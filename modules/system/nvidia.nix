{ config, pkgs, ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  hardware.nvidia.nvidiaPersistenced = true;   # ← to jest nowe, dodaj gdzieś w configu

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
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
