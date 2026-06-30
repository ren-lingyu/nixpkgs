{
  
  description = "My personal NUR repository";

  inputs = {
    nixpkgs = {
      url = "git+https://github.com/NixOS/nixpkgs?ref=refs/heads/nixos-unstable&shallow=1";
    };
  };
      
  outputs = { self, ... }@inputs : let
    
    forAllSystems = inputs.nixpkgs.lib.genAttrs inputs.nixpkgs.lib.systems.flakeExposed;
    
  in
    {
      
      legacyPackages = forAllSystems (system : let
        pkgs_ = import inputs.nixpkgs { inherit system; };
      in ((import ./lib { pkgs = pkgs_; }).stripPackageTreeMarkers (import ./pkgs { pkgs = pkgs_; })));
      # packages = forAllSystems (system : self.legacyPackages.${system});
      overlays = import ./overlays;
      nixosModules = import ./nixos-modules;
      homeManagerModules = import ./home-manager-modules;
      homeModules = self.homeManagerModules;
      # darwinModules = import ./darwin-modules;
      # flakeModules = import ./flake-modules;
      
    };
  
}
