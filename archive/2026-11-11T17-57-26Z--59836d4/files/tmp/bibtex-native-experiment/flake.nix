{
  description = "Isolated experiment: discriminating native BibTeX acceptance";

  inputs.project.url = "git+file:///home/lingyu/nixpkgs";

  outputs = { project, ... }:
    let
      system = "x86_64-linux";
      pkgs = import project.inputs.nixpkgs { inherit system; };
    in {
      checks.${system}.default = pkgs.callPackage ./check.nix {
        formatter = project.legacyPackages.${system}.treefmt-wrapper;
      };
    };
}
