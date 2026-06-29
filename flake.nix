{
  
  description = "My personal NUR repository";

  inputs = {
    nixpkgs = {
      url = "git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-unstable&shallow=1";
      # type = "github";
      # owner = "NixOS";
      # repo = "nixpkgs";
      # ref = "nixos-unstable";
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
      # homeModules = import ./home-modules;
      # darwinModules = import ./darwin-modules;
      # flakeModules = import ./flake-modules;
      
    };
  
}
