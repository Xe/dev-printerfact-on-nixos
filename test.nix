let
  sources = import ./nix/sources.nix;
  pkgs = sources.nixpkgs;
in import "${pkgs}/nixos/tests/make-test-python.nix" ({ pkgs, ... }: {
  system = "x86_64-linux";

  nodes.machine = { config, pkgs, ... }: {
    nixpkgs.overlays = [
      (self: super: {
        Xelinux = super.linuxPackages_5_11
          // super.linuxPackages_5_11.overrideAttrs
          (old: { kernel = super.callPackage ./. { }; });
      })
    ];

    virtualisation.graphics = false;

    boot.kernelPackages = pkgs.Xelinux;
  };

  testScript = ''
    start_all()
  '';
})
