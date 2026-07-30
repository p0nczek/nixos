{ pkgs, ... }:
{
  programs.steam = {
  	enable = true;
  	extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    plugins = [ pkgs.obs-studio-plugins.droidcam-obs ];
  };

  security.wrappers.gsr-kms-server = {
    source = "${pkgs.gpu-screen-recorder}/bin/gsr-kms-server";
    capabilities = "cap_sys_admin+ep";
    owner = "root";
    group = "root";
  };

#  vesktop.enable = true;
programs.nixos-cli = {
    enable = true;
    };

  
}
