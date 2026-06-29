{
  config,
  pkgs,
  lib,
  ...
}: {
  system.stateVersion = "26.05";

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
      trusted-users = ["root" "kit"];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  documentation.nixos.enable = false;

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    jq
    dig
    htop
    tmux
    age
    sops
  ];

  boot.loader.raspberry-pi = {
    enable = true;
    bootloader = "kernel";
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;
      AllowUsers = ["kit"];
    };
    openFirewall = true;
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
    execWheelOnly = true;
  };

  users.mutableUsers = false;

  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "net.ipv4.ip_forward" = 0;
    "net.ipv6.conf.all.forwarding" = 0;
  };

  programs.argon.one = {
    enable = true;

    settings = {
      # Is 'celsius' by default, can also be set to 'fahrenheit'
      displayUnits = "celsius";

      # This is the same config as the original Argon40 config.
      # This is also the default config for this flake.
      fanspeed = [
        {
          # This the temperature threshold at which this fan speed will activate.
          # The temperature is in the above specified unit.
          temperature = 55;
          # This is speed percentage at which the fan will spin.
          speed = 30;
        }
        {
          temperature = 60;
          speed = 55;
        }
        {
          temperature = 65;
          speed = 100;
        }
      ];
    };
  };
}
