{ config, pkgs, ... }:

{
  # 1. Włącz libvirtd + QEMU/KVM
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;                    # TPM 2.0 (wymagany przez Windows 11)
      ovmf = {
        enable = true;
        packages = [ pkgs.OVMFFull.fd ];      # UEFI ze Secure Boot
      };
    };
  };

  # 2. Włącz KVM w jądrze (wybierz jedno, zależnie od CPU)
  boot.kernelModules = [ "kvm-amd" ];         # AMD
  # boot.kernelModules = [ "kvm-intel" ];     # Intel

  # 3. Włącz IOMMU w jądrze (wymagane też w BIOS/UEFI: AMD-Vi / VT-d)
  boot.kernelParams = [ "amd_iommu=on" ];     # AMD
  # boot.kernelParams = [ "intel_iommu=on" ]; # Intel

  # 4. Pakiety do zarządzania VM
  environment.systemPackages = with pkgs; [
    virt-manager
    qemu
    OVMF
    swtpm
    virtio-win          # sterowniki Windows dla QEMU (network, disk, GPU)
    win-spice           # lepsza integracja myszki/klawiatury
  ];

  # 5. Dodaj użytkownika do grup
  users.users.shin.extraGroups = [ "libvirtd" "kvm" ];

  # 6. 32-bitowe biblioteki (przydatne jeśli kiedyś wrócisz do Wine)
  hardware.graphics.enable32Bit = true;
}
