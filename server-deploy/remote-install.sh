# make sure to set SSHPASS - which doesn't seem to be working -__-

# run this when hardware is changed, to generate a new hardware config
# nix run github:nix-community/nixos-anywhere -- --flake "path://#$1" --target-host root@$2 --generate-hardware-config nixos-facter ./facter.json --env-password

nix run github:nix-community/nixos-anywhere -- --flake "path://#$1" --target-host root@$2 --env-password