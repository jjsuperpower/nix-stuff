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

    node_config = node_config: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ 
        disko.nixosModules.disko
        ./configuration.nix
        node_config
        nixos-facter-modules.nixosModules.facter {
          config.facter.reportPath =
            if builtins.pathExists ./facter.json then
              ./facter.json
            else
              throw "Have you forgotten to run nixos-anywhere with `--generate-hardware-config nixos-facter ./facter.json`?";
        }
      ];
    };

    nixosConfigurations.odst1 = node_config ./nodes/1.nix;
    # nixosConfigurations.odst2 = node_config ./nodes/2.nix;

    node_deploy = hostname: {
      hostname = "${hostname}.jjsuperpower.com";
      profiles.system = {
        user = "root";
        sshUser = "admin";
        sshOpts = [ "-i" "~/.ssh/server" ];
        path = deployPkgs.deploy-rs.lib.activate.nixos nixosConfigurations.${hostname};
      };
    };

  in {

    deploy.nodes.odst1 = node_deploy "odst1";
    # deploy.nodes.odst2 = node_deploy "odst2";

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}
