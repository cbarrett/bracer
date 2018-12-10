{ nixpkgs ? import <nixpkgs> {}, compiler ? "ghc821Binary" }:
nixpkgs.pkgs.haskell.packages.${compiler}.callPackage ./bracer.nix {}
