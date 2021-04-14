let
  sources = import ./nix/sources.nix;
  pkgs = sources.nixpkgs;
in import "${pkgs}/nixos/tests/make-test-python.nix" ({ pkgs, ... }: {
  system = "x86_64-linux";

  nodes.machine = { config, pkgs, ... }: {
    nixpkgs.overlays = [
      (self: super: {
        Xelinux = super.callPackage ./. { };
        XelinuxPackages = super.linuxPackagesFor self.Xelinux;
      })
    ];

    virtualisation.graphics = false;

    boot.kernelPackages = pkgs.XelinuxPackages;
  };

  testScript = ''
    start_all()
  '';
})
