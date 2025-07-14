# first arg = <root@ip_addr>

nix --experimental-features 'nix-command flakes' run github:nix-community/nixos-anywhere -- --flake "path://#enterprise" --target-host $1 --generate-hardware-config nixos-facter ./facter.json
