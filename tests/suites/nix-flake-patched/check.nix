{ pkgs, nix-flake-patched }:
let
  base = nix-flake-patched.baseNix;
  inherit (nix-flake-patched) patches;
  circular = base.appendPatches [ (builtins.elemAt patches 0) ];
  nested = base.appendPatches [ (builtins.elemAt patches 1) ];
  runner = pkgs.writeText "nix-flake-patched-tests.py" (import ./runner.nix);
  fixtures = pkgs.writeText "nix-flake-patched-fixtures.json" (
    builtins.toJSON (import ./fixtures.nix)
  );
in
assert base.version == "2.35.3";
assert pkgs.lib.isDerivation nix-flake-patched;
assert nix-flake-patched.drvPath != base.drvPath;
pkgs.runCommand "nix-flake-patched-regressions" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  ${pkgs.python3}/bin/python ${runner} ${fixtures} \
    ${base}/bin/nix ${circular}/bin/nix ${nested}/bin/nix \
    ${nix-flake-patched}/bin/nix "$out"
''
