{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  system.stateVersion = "25.05";

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
      trusted-users = ["root" "alice"];
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
      AllowUsers = ["alice"];
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
}
