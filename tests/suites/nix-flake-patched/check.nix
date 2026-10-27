{ pkgs, nixFlakePatched }:
let
  base = nixFlakePatched.package.baseNix;
  inherit (nixFlakePatched.package) patches;
  circular = base.appendPatches [ (builtins.elemAt patches 0) ];
  nested = base.appendPatches [ (builtins.elemAt patches 1) ];
  runner = pkgs.writeText "nix-flake-patched-tests.py" (import ./runner.nix);
  fixtures = pkgs.writeText "nix-flake-patched-fixtures.json" (
    builtins.toJSON (import ./fixtures.nix)
  );
in
assert base.version == "2.35.3";
assert pkgs.lib.isDerivation nixFlakePatched.package;
assert nixFlakePatched.package.drvPath != base.drvPath;
assert nixFlakePatched.package.drvPath == nixFlakePatched.legacyPackage.drvPath;
assert nixFlakePatched.defaultNix.drvPath == pkgs.nix.drvPath;
pkgs.runCommand "nix-flake-patched-regressions" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  ${pkgs.python3}/bin/python ${runner} ${fixtures} \
    ${base}/bin/nix ${circular}/bin/nix ${nested}/bin/nix \
    ${nixFlakePatched.package}/bin/nix "$out"
''
