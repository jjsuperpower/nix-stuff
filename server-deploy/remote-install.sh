# make sure to set SSHPASS - which doesn't seem to be working -__-

nix run github:nix-community/nixos-anywhere -- --flake "path://#odst1" --target-host root@192.168.11.212 --generate-hardware-config nixos-facter ./facter.json --env-password