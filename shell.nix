{ nixpkgs ? import <nixpkgs> {}, compiler ? "ghc821Binary" }:
(import ./default.nix { inherit nixpkgs compiler; }).env

