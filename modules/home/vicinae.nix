{ ... }:
{
  programs.vicinae = {
    enable = true;
    systemd.enable = true;
  };

  home.file.".mozilla/native-messaging-hosts/com.vicinae.vicinae.json" = {
    text = builtins.toJSON {
      name = "com.vicinae.vicinae";
      description = "Vicinae browser integration";
      path = "/nix/store/lr8l5h6fg1zq2wcpz9ww28dsfgxyhybx-vicinae-0.23.0/libexec/vicinae/vicinae-browser-link";
      type = "stdio";
      allowed_extensions = [ "firefox@vicinae.com" ];
    };
  };
}
