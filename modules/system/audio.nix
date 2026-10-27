{ ... }:
{
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  security.pam.loginLimits = [
    { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "@audio"; item = "rtprio";  type = "-"; value = "99"; }
    { domain = "@audio"; item = "nice";   type = "-"; value = "-19"; }
  ];
  
  services.pipewire.extraConfig.pipewire."91-virtual-mic" = {
  "context.modules" = [
    {
      name = "libpipewire-module-loopback";
      args = {
        "node.description" = "Virtual Microphone";
        "capture.props" = {
          "node.name" = "virtual_mic_sink";
          "media.class" = "Audio/Sink";
        };
        "playback.props" = {
          "node.name" = "virtual_mic_source";
          "media.class" = "Audio/Source";
          "audio.position" = [ "FL" "FR" ];
        };
      };
    }
  ];
};
}
