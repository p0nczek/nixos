{ ... }:
{
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
}
