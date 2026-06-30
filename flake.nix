{
  description = "Pi 5 homelab: AdGuard, Prometheus, Grafana, Syncthing, Caddy";

  inputs = {
    sops-nix.url = "github:Mic92/sops-nix";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    argon40-nix.url = "github:guusvanmeerveld/argon40-nix";
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
    argon40-nix,
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
          imports = [
            nixos-raspberrypi.nixosModules.raspberry-pi-5.base
            ## nixos-raspberrypi.nixosModules.sd-image
            argon40-nix.nixosModules.default
          ];
        })

        ./hosts/pi5/default.nix
        ./hosts/pi5/networking.nix
        ./hosts/pi5/users.nix
        ./hosts/pi5/services.nix
        ./hosts/pi5/hardware-configuration.nix
        ./modules/caddy-local-tls.nix
      ];
    };
  };
}
