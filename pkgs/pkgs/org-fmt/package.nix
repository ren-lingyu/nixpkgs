{
  callPackage,
  lib,
  emacs-nox,
  writeShellApplication,
}@args:
writeShellApplication {
  name = "org-fmt";
  text = ''exec ${lib.getExe' emacs-nox "emacs"} --batch -Q --script ${./org-fmt.el} "$@"'';
  passthru.tests.regressions = callPackage ./tests/check.nix {
    # Preserve argument overrides used by the fault-injection package.
    org-fmt = callPackage ./package.nix args;
  };
}
