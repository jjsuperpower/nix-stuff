# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  arcMaxMiB = 512;
  stablePkgs = import inputs.nixpkgs-stable {system = "x86_64-linux";};

  # get latest kernel package that is compatible with zfs
  zfsCompatibleKernelPackages = lib.filterAttrs (
    name: kernelPackages:
    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
    && (builtins.tryEval kernelPackages).success
    && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
  ) pkgs.linuxKernel.packages;
  latestKernelPackage = lib.last (
    lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );

in {
  nix.settings.experimental-features = ["nix-command" "flakes"];
  imports = [
    ./disko.nix
    ./startup_sshkey.nix
    ./passwords.nix
  ];

  boot.kernelPackages = latestKernelPackage;

  # zfs mount stuff
  networking.hostId = "e321370e";
  boot.loader.grub = {
    enable = true;
    zfsSupport = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    mirroredBoots = [
      {
        devices = ["nodev"];
        path = "/boot";
      }
    ];
  };

  boot.kernelParams = ["nohibernate" "zfs.zfs_arc_max=4884901888"];
  boot.initrd.postMountCommands = lib.mkAfter ''
    zfs rollback -r zroot/root@blank;
  '';

  fileSystems = {
    "/" = {
      device = "zroot/root";
      fsType = "zfs";
      neededForBoot = true;
    };
    "/persistent".neededForBoot = true;
    "/var/log".neededForBoot = true;
    "/games" = {
      device = "games";
      fsType = "zfs";
      neededForBoot = false;
      options = [
        "users"
        "nofail"
      ];
    };
  };
  #   swapDevices = [];
  services.zfs.autoScrub.enable = true;
  services.zfs.autoSnapshot.enable = true;
  #   services.zfs-mount.enable = false;

  # add mnt folder at boot
  systemd.tmpfiles.rules = [
    "d /mnt 0755 root root -"
  ];

  # minimize swap usage
  boot.kernel.sysctl = {
    "vm.swappiness" = 20;
  };

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    open = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

  networking.hostName = "enterprise"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  systemd.network.wait-online.enable = false; # Disable wait-online, as it can cause issues with NetworkManager
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openvpn
  ];

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  #services.xserver.enable = true;

  services.displayManager.sddm.wayland.enable = true;

  # Enable the KDE Plasma     Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X    11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print     documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # vpn stuff
  services.openvpn.servers = {
    bitbyteVPN = {
      config = ''config bitbyte.ovpn '';
      autoStart = false;
    };
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jon = {
    isNormalUser = true;
    description = "jon";
    extraGroups = ["networkmanager" "wheel" "docker"];
    packages = with pkgs; [
      kdePackages.kate
      #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    kdePackages.discover # Optional: Install if you use Flatpak or fwupd firmware update sevice
    kdePackages.kcalc # Calculator
    kdePackages.kcharselect # Tool to select and copy special characters from all installed fonts
    kdePackages.kcolorchooser # A small utility to select a color
    kdePackages.kolourpaint # Easy-to-use paint program
    kdePackages.ksystemlog # KDE SystemLog Application
    kdePackages.sddm-kcm # Configuration module for SDDM
    kdiff3 # Compares and merges 2 or 3 files or directories
    kdePackages.isoimagewriter # Optional: Program to write hybrid ISO files onto USB disks
    kdePackages.partitionmanager # Optional Manage the disk devices, partitions and file systems on your computer
    hardinfo2 # System information and benchmarks for Linux systems
    haruna # Open source video player built with Qt/QML and libmpv
    wayland-utils # Wayland utilities
    wl-clipboard # Command-line copy/paste utilities for Wayland
    networkmanager-openvpn
    # kdePackages.wallpaper-engine-plugin

    git
    jujutsu
    wget
    discord-canary
    htop
    krita
    zed-editor
    obsidian
    meld
    vscode
    corectrl
    flatpak
    gparted
    gnome-disk-utility
    gparted
    rustup
    gcc
    glib
    lm_sensors
    coolercontrol.coolercontrol-gui
    coolercontrol.coolercontrold
    prometheus-nvidia-gpu-exporter
    peek
    cheese
    kicad
    freecad-wayland
    spotify
    cryptsetup
    sudo-rs
    zsh
    alejandra
    pre-commit
    qidi-slicer-bin
    evince
    cargo-generate
    chromium
    dnsutils
    signal-desktop
    onlyoffice-desktopeditors
    virt-viewer

    # python packages
    (python313.withPackages (ps:
      with ps; [
        pip
        virtualenv
        python-pipedrive
        requests
        numpy
        pandas
        matplotlib
        scikit-learn
        scikit-image
        scipy
        jupyterlab
      ]))

    # stable packages
    stablePkgs.darktable
    stablePkgs.prismlauncher
    stablePkgs.rustdesk-flutter
  ];

  # exclude packages
  environment.plasma6.excludePackages = [pkgs.kdePackages.baloo];

  # sudo stuff
  security.sudo-rs.enable = true;
  security.sudo.enable = false;

  #cooler control
  programs.coolercontrol.enable = true;
  boot.kernelModules = ["nct6775" "lm75"]; # needed for sensors

  # flatpak
  services.flatpak.enable = true;

  # docker
  virtualisation.docker.enable = true;

  # steam install
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

  environment.etc."sysconfig/lm_sensors".text = ''
    # Generated by sensors-detect on Wed Jul  9 00:06:28 2025
    # This file is sourced by /etc/init.d/lm_sensors and defines the modules to
    # be loaded/unloaded.
    #
    # The format of this file is a shell script that simply defines variables:
    # HWMON_MODULES for hardware monitoring driver modules, and optionally
    # BUS_MODULES for any required bus driver module (for example for I2C or SPI).

    HWMON_MODULES="lm75 nct6775"
  '';

  # impermanence stuff
  #    security.sudo-rs.extraConfig = ''
  #     # Rollback results in sudo lectures after each reboot
  #     Defaults lecture = false
  #   '';

  environment.persistence."/persistent" = {
    enable = true; # NB: Defaults to true, not needed
    hideMounts = true;
    directories = [
      "/etc/nixos"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
      "/var/lib/docker"
      "/etc/coolercontrol/"
      "/var/lib/flatpak/"
    ];
    files = [
      "/etc/machine-id"
    ];
  };
}
