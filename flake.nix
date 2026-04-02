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
      
  outputs = { self, nixpkgs }:  
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
      {
        legacyPackages = forAllSystems (system: import ./default.nix {
          pkgs = import nixpkgs { inherit system; };
        });
        packages = forAllSystems (system: self.legacyPackages.${system});
        nixosModules = import ./nixos-modules;
        # homeModules = import ./home-modules;
        # darwinModules = import ./darwin-modules;
        # flakeModules = import ./flake-modules;
      };
  
}
