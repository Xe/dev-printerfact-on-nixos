{ system ? builtins.currentSystem, ... }:

let
  sources = import nix/sources.nix;
  pkgs = import sources.nixpkgs { inherit system; };

  kernel = pkgs.callPackage ./kernel.nix {
    version = "5.12.0-rc4";
    src = sources.linux;
  };

in kernel
