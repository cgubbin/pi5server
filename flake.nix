{
  description = "Pi 5 homelab: AdGuard, Prometheus, Grafana, Syncthing, Caddy";

  inputs = {
    sops-nix.url = "github:Mic92/sops-nix";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
  };

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  outputs = inputs @ {
    self,
    sops-nix,
    nixos-raspberrypi,
    ...
  }: {
    nixosConfigurations.pi5 = nixos-raspberrypi.lib.nixosSystem {
      system = "aarch64-linux";

      specialArgs = {
        inherit (inputs) nixos-raspberrypi;
      };

      modules = [
        sops-nix.nixosModules.sops

        ({...}: {
          imports = with nixos-raspberrypi.nixosModules; [
            raspberry-pi-5.base
            sd-image
          ];
        })

        ./hosts/pi5/default.nix
        ./hosts/pi5/networking.nix
        ./hosts/pi5/users.nix
        ./hosts/pi5/services.nix
        ./modules/caddy-local-tls.nix
      ];
    };
  };
}
