{
  description = "Homelab Kubernetes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: {
    nixosConfigurations.cp-1 = nixpkgs.lib.nixosSystem {
      modules = [
        ./hosts/cp-1/configuration.nix
      ];
    };
  };
}
