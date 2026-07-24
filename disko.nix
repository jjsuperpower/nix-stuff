{
  disko.devices = {
    disk = {
      root = {
        type = "disk";
        device = "/dev/mmcblk0";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["nofail"];
              };
            };
            encryptedSwap = {
              size = "6G";
              content = {
                type = "swap";
                randomEncryption = true;
                priority = 100; # prefer to encrypt as long as we have space for it
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
    };
    zpool = {
      zroot = {
        type = "zpool";
        rootFsOptions = {
          mountpoint = "legacy";
          compression = "zstd";
          acltype = "posixacl";
          xattr = "sa";
          encryption = "aes-256-gcm";
          keyformat = "passphrase";
          #keylocation = "file:///tmp/secret.key";
          keylocation = "prompt";
          "com.sun:auto-snapshot" = "false";
        };
        options.ashift = "12";

        datasets = {
          "root" = {
            type = "zfs_fs";
            options.mountpoint = "none";
            mountpoint = "/";
            postCreateHook = ''
              zfs snapshot zroot/root@blank
            '';
          };

          "system" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };

          "system/var/log" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/var/log";
          };

          "system/nix" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
              dedup = "on";
            };
            mountpoint = "/nix";
          };

          "safe" = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
            };
          };

          "safe/home" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
              "com.sun:auto-snapshot" = "true";
            };
            mountpoint = "/home";
          };

          "safe/persistent" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/persistent";
          };

          #           # README MORE: https://wiki.archlinux.org/title/ZFS#Swap_volume
          #           "swap" = {
          #             type = "zfs_volume";
          #             size = "32000M";
          #             content = {
          #               type = "swap";
          #             };
          #             options = {
          #               volblocksize = "4096";
          #               compression = "zle";
          #               logbias = "throughput";
          #               sync = "always";
          #               primarycache = "metadata";
          #               secondarycache = "none";
          #               "com.sun:auto-snapshot" = "false";
          #             };
          #           };
        };
      };
    };
  };
}
