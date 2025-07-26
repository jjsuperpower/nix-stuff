{
  description = "Enterprise nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
  };

  outputs = inputs @ {
    nixpkgs,
    nixpkgs-stable,
    disko,
    nixos-facter-modules,
    impermanence,
    ...
  }: {
    nixosConfigurations.enterprise = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        impermanence.nixosModules.impermanence
        ./configuration.nix
        nixos-facter-modules.nixosModules.facter
        {config.facter.reportPath = ./facter.json;}
      ];
      specialArgs = {inherit inputs;};
    };
  };
}
