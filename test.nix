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

    machine.wait_for_console_text("printerfact")

    chardev = [
        x
        for x in machine.wait_until_succeeds("cat /proc/devices").splitlines()
        if "printerfact" in x
    ][0].split(" ")[0]

    machine.wait_until_succeeds("mknod /dev/printerfact c {} 1".format(chardev))
    machine.wait_for_file("/dev/printerfact")

    print(machine.wait_until_succeeds("stat /dev/printerfact"))
    machine.wait_until_succeeds("cat /dev/printerfact")
  '';
})
