{...}: {
  networking.hostName = "pi5";
  networking.useDHCP = true;

  services.resolved.enable = false;

  networking.firewall = {
    enable = true;
    trustedInterfaces = ["tailscale0"];

    allowedTCPPorts = [
      22
      53
      80
      443
      22000
    ];

    allowedUDPPorts = [
      53
      22000
      21027
    ];
  };
}
