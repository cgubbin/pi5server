{
  description = "Pi 5 homelab: AdGuard, Prometheus, Grafana, Syncthing, Caddy";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    sops-nix.url = "github:Mic92/sops-nix";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
  };

  # Optional: Binary cache for the flake
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
    nixpkgs,
    nixos-raspberrypi,
    sops-nix,
    ...
  }: let
    system = "aarch64-linux";
  in {
    nixosConfigurations.pi5 = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs;};

      modules = [
        sops-nix.nixosModules.sops

        # Pi 5 board support from nvmd/nixos-raspberrypi
        nixos-raspberrypi.nixosModules.raspberry-pi-5.base
        nixos-raspberrypi.nixosModules.sd-image

        ./hosts/pi5/default.nix
        ./hosts/pi5/networking.nix
        ./hosts/pi5/users.nix
        ./hosts/pi5/services.nix
        ./modules/caddy-local-tls.nix
      ];
    };
  };
}
