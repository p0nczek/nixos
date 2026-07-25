{ config, pkgs, ... }:

{
  # IOMMU + VFIO
  boot.kernelParams = [ "amd_iommu=on" "iommu=pt" ];
  boot.initrd.availableKernelModules = [ "vfio" "vfio_iommu_type1" "vfio_pci" ];
  
  # Przekaż RTX 3060 do VFIO od boota
  boot.extraModprobeConfig = ''
    options vfio-pci ids=10de:2504,10de:228e
  '';

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  virtualisation.spiceUSBRedirection.enable = true;

  environment.systemPackages = with pkgs; [
    virt-manager
    looking-glass-client
  ];
}
