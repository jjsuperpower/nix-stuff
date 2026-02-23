{
  description = "Halo VM deployment cluster configuration";

  # For accessing `deploy-rs`'s utility Nix functions
  inputs = {
    deploy-rs.url = "github:serokell/deploy-rs";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
  };

  outputs = { self, nixpkgs, deploy-rs, disko, nixos-facter-modules, ... }: let
    system = "x86_64-linux";
    # Unmodified nixpkgs
    pkgs = import nixpkgs { inherit system; };
    # nixpkgs with deploy-rs overlay but force the nixpkgs package
    deployPkgs = import nixpkgs {
      inherit system;
      overlays = [
        deploy-rs.overlays.default
        (self: super: { deploy-rs = { inherit (pkgs) deploy-rs; lib = super.deploy-rs.lib; }; })
      ];
    };

    nixosConfigurations.odst1 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ 
        disko.nixosModules.disko
        ./configuration.nix
        ./nodes/1.nix
        nixos-facter-modules.nixosModules.facter
          {
            config.facter.reportPath =
              if builtins.pathExists ./facter.json then
                ./facter.json
              else
                throw "Have you forgotten to run nixos-anywhere with `--generate-hardware-config nixos-facter ./facter.json`?";
          }
      ];
    };
  in {

    inherit nixosConfigurations;

    deploy.nodes.odst1.hostname = "odst1.jjsuperpower.com";
    deploy.nodes.odst1.profiles.system = {
        user = "root";
        sshUser = "admin";
        sshOpts = [ "-i" "~/.ssh/server" ];
        path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.odst1;
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}
