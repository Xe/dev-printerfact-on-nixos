{ lib, llvmPackages_11, rustPlatform, rustfmt, rust-bindgen, buildLinux
, linuxManualConfig, kernelPatches

, src, version }@args:

let
  llvmPackages = llvmPackages_11;
  inherit (llvmPackages) clang stdenv;

  rustcNightly = rustPlatform.rust.rustc.overrideAttrs (oldAttrs: {
    configureFlags = map (flag:
      if flag == "--release-channel=stable" then
        "--release-channel=nightly"
      else
        flag) oldAttrs.configureFlags;
  });

  addRust = old: {
    buildInputs = (old.buildInputs or [ ]) ++ [ rustcNightly ];
    nativeBuildInputs = (old.nativeBuildInputs or [ ])
      ++ [ (rust-bindgen.override { inherit clang llvmPackages; }) rustfmt ];
    postPatch = ''
      substituteInPlace rust/Makefile --replace 'rustc_src = $(rustc_sysroot)/lib/rustlib/src/rust' "rust_lib_src = ${rustPlatform.rustLibSrc}"
      substituteInPlace rust/Makefile --replace '$(rustc_src)/library' '$(rust_lib_src)'
    '';
    ignoreConfigErrors = true;
  };

in (linuxManualConfig rec {
  inherit src version stdenv lib;

  kernelPatches = with args.kernelPatches; [
    bridge_stp_helper
    request_key_helper
  ];

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion = version;

  # branchVersion needs to be x.y
  extraMeta = { branch = lib.versions.majorMinor version; };

  randstructSeed = "";

  configfile = (buildLinux {
    inherit src version stdenv modDirVersion kernelPatches extraMeta;

    structuredExtraConfig = with lib.kernel; {
      RUST = yes;
      PRINTERFACT = yes;
    };
  }).configfile.overrideAttrs addRust;

  config = {
    CONFIG_MODULES = "y";
    CONFIG_FW_LOADER = "n";

    "CONFIG_SERIAL_8250_CONSOLE" = "y";
    "CONFIG_SERIAL_8250" = "y";
    "CONFIG_VIRTIO_CONSOLE" = "y";
    "CONFIG_VIRTIO_BLK" = "y";
    "CONFIG_VIRTIO_PCI" = "y";
    "CONFIG_VIRTIO_NET" = "y";
    "CONFIG_EXT4_FS" = "y";
    "CONFIG_NET_9P_VIRTIO" = "y";
    "CONFIG_9P_FS" = "y";
    "CONFIG_BLK_DEV" = "y";
    "CONFIG_PCI" = "y";
    "CONFIG_NETDEVICES" = "y";
    "CONFIG_NET_CORE" = "y";
    "CONFIG_INET" = "y";
    "CONFIG_NETWORK_FILESYSTEMS" = "y";
    "CONFIG_OVERLAY_FS" = "y";
    "CONFIG_DEVTMPFS" = "y";
    "CONFIG_CGROUPS" = "y";
    "CONFIG_SIGNALFD" = "y";
    "CONFIG_TIMERFD" = "y";
    "CONFIG_EPOLL" = "y";
    "CONFIG_NET" = "y";
    "CONFIG_SYSFS" = "y";
    "CONFIG_PROC_FS" = "y";
    "CONFIG_FHANDLE" = "y";
    "CONFIG_CRYPTO_USER_API_HASH" = "y";
    "CONFIG_CRYPTO_HMAC" = "y";
    "CONFIG_CRYPTO_SHA256" = "y";
    "CONFIG_DMIID" = "y";
    "CONFIG_AUTOFS4_FS" = "y";
    "CONFIG_TMPFS_POSIX_ACL" = "y";
    "CONFIG_TMPFS_XATTR" = "y";
    "CONFIG_SECCOMP" = "y";
    "CONFIG_TMPFS" = "y";
    "CONFIG_BLK_DEV_INITRD" = "y";
    "CONFIG_BINFMT_ELF" = "y";
    "CONFIG_UNIX" = "y";
    "CONFIG_INOTIFY_USER" = "y";
  };
  allowImportFromDerivation = true;
}).overrideAttrs addRust
