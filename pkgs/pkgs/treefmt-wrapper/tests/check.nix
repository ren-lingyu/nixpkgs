{ pkgs, treefmt-wrapper }:
let
  runner = pkgs.writeText "bibtex-regressions.py" (import ./runner.nix);
  fixtures = pkgs.writeText "bibtex-fixtures.json" (builtins.toJSON (import ./fixtures.nix));
in
pkgs.runCommand "treefmt-wrapper-bibtex-regressions" { } ''
  ${pkgs.python3}/bin/python ${runner} ${treefmt-wrapper}/bin/treefmt ${fixtures} "$out"
''
