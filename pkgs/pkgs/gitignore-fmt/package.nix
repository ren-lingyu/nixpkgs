{
  callPackage,
  writeShellApplication,
  coreutils,
  diffutils,
}@args:
writeShellApplication {
  name = "gitignore-fmt";
  runtimeInputs = [
    coreutils
    diffutils
  ];
  text = builtins.readFile ./gitignore-fmt.sh;
  passthru.tests.regressions = callPackage ./tests/check.nix {
    # Preserve argument overrides used by the fault-injection package.
    gitignore-fmt = callPackage ./package.nix args;
  };
}
