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
  networking.hostId = "9695e88e"; # regenerate with: head -c4 /dev/urandom | od -A none -t x4 | tr -d ' '
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

  boot.kernelParams = ["nohibernate" "zfs.zfs_arc_max=${toString (arcMaxMiB * 1024 * 1024)}"];
  boot.initrd.systemd.services.zfsRollback = {
    description = "Rollback ZFS datasets to a pristine state";
    wantedBy = [
      "initrd.target"
    ]; 
    after = [
      "zfs-import-zroot.service"
    ];
    before = [ 
      "sysroot.mount"
    ];
    path = with pkgs; [
      zfs
    ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.zfs}/bin/zfs rollback -r zroot/root@blank";
    };
  };

  boot.zfs.forceImportRoot = false;

  fileSystems = {
    "/" = {
      device = "zroot/root";
      fsType = "zfs";
      neededForBoot = true;
    };
    "/persistent".neededForBoot = true;
    "/var/log".neededForBoot = true;
  };

  services.udev.extraRules = ''
    # STMicroelectronics ST-LINK V1
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3744", MODE="660", GROUP="plugdev", TAG+="uaccess"

    # STMicroelectronics ST-LINK/V2
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3748", MODE="660", GROUP="plugdev", TAG+="uaccess"

    # STMicroelectronics ST-LINK/V2.1
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374b", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3752", MODE="660", GROUP="plugdev", TAG+="uaccess"

    # STMicroelectronics STLINK-V3
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374d", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374e", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374f", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3753", MODE="660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3754", MODE="660", GROUP="plugdev", TAG+="uaccess"

    # Digilent USB Devices
    ATTR{idVendor}=="0403", ATTR{idProduct}=="6010", MODE="0660", GROUP="plugdev"
    ATTR{idVendor}=="0403", ATTR{idProduct}=="6014", MODE="0660", GROUP="plugdev"
    ATTR{idVendor}=="1443", MODE="0660", GROUP="plugdev"
  '';

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

  networking.hostName = "TenForward"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  systemd.network.wait-online.enable = false; # Disable wait-online, as it can cause issues with NetworkManager

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

  # Enable the COSMIC Desktop Environment.
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  # Configure keymap in X    11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

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

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;


  users.groups.plugdev = {};    # stm32 programmer group
  users.users.jon = {
    isNormalUser = true;
    description = "jon";
    extraGroups = ["networkmanager" "wheel" "docker" "plugdev" "dialout"];
    shell = pkgs.fish;
    packages = [];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [

    #### System utilities ####
    sudo-rs
    cryptsetup

    #### Terminal emulators ####
    ghostty
    rio

    #### Shell and prompt ####
    starship
    nushell

    # fish plugins
    fishPlugins.done
    fishPlugins.fzf-fish
    fishPlugins.forgit
    fishPlugins.hydro
    fzf
    fishPlugins.grc
    grc

    #### Rust CLI utilities ####
    bat
    rip2
    ripgrep
    zellij
    jujutsu

    #### Dev tools ####
    vim
    helix
    git
    pre-commit
    wget
    htop
    btop
    rustup
    cargo-generate
    nil
    nixd
    nixfmt
    ruff
    lldb

    #### Misc system tools ####
    file
    usbutils
    dnsutils
    zfs-prune-snapshots

    #### Python ####
    (python313.withPackages (ps:
      with ps; [
        pip
        virtualenv
        requests
        debugpy
      ]))

    #### GUI Applications ####
    wayland-utils
    wl-clipboard
    hardinfo2
    krita
    meld
    flatpak
    gparted
    gnome-disk-utility
    evince
    chromium
  ];

  # sudo stuff
  security.sudo-rs.enable = true;
  security.sudo.enable = false;

  # flatpak
  services.flatpak.enable = true;

  # terminal stuff
  programs.fish.enable = true;
  programs.starship.enable = true;

  # setup direnv stuff for vscode + projects
  # programs.direnv.enable = true;

  # make sure emergency bash shells switch to fish
  # https://nixos.wiki/wiki/Fish
  programs.bash = {
    interactiveShellInit = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };

  # docker
  virtualisation.docker.enable = true;

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
  system.stateVersion = "26.05"; # Did you read the comment?

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
      "/var/lib/flatpak/"
    ];
    files = [
      "/etc/machine-id"
    ];
  };
}
