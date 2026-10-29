{
  lib,
  emacs-nox,
  writeShellApplication,
}:
writeShellApplication {
  name = "org-fmt";
  text = ''exec ${lib.getExe' emacs-nox "emacs"} --batch -Q --script ${./org-fmt.el} "$@"'';
}
