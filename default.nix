{ pkgs ? import <nixpkgs> { } } : (import ./pkgs { inherit pkgs; }) // rec {

  lib = import ./lib { inherit pkgs; }; # functions
  nixosModules = import ./nixos-modules; # NixOS modules
  homeManagerModules = import ./home-manager-modules; # Home Manager modules
  homeModules = homeManagerModules;
  # darwinModules = { }; # nix-darwin modules
  # flakeModules = { }; # flake-parts modules
  overlays = import ./overlays; # nixpkgs overlays
  
}
