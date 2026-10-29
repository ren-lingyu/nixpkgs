{
  pkgs,
  org-fmt,
  documents ? { },
}:
let
  # Fault advice exercises the packaged CLI without production test switches.
  faults = pkgs.writeText "org-fmt-faults.el" ''
    ;;; -*- lexical-binding: t; -*-
    (dolist (name '(org-element-interpret-data make-nearby-temp-file
                    write-region set-file-modes rename-file))
      (advice-add
       name :around
       (let ((operation name))
         (lambda (original &rest args)
           (if (equal (getenv "ORG_FMT_TEST_FAILURE") (symbol-name operation))
               (progn
                 (when (eq operation 'write-region)
                   (funcall original "partial output" nil (nth 2 args) nil 'silent))
                 (error "injected %s failure" operation))
             (apply original args))))))
  '';
  faultyEmacs = pkgs.writeShellScriptBin "emacs" ''
    script=$4
    shift 4
    exec ${pkgs.lib.getExe' pkgs.emacs-nox "emacs"} \
      --batch -Q --load ${faults} --load "$script" "$@"
  '';
  faulty = org-fmt.override { emacs-nox = faultyEmacs; };
  runner = pkgs.writeText "org-fmt-tests.py" (import ./runner.nix);
  semantics = pkgs.writeText "org-fmt-semantics.el" (import ./semantics.nix);
  documentList = pkgs.writeText "org-fmt-documents.json" (builtins.toJSON documents);
in
pkgs.runCommand "org-fmt-regressions" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  ${pkgs.python3}/bin/python ${runner} \
    ${pkgs.lib.getExe org-fmt} ${pkgs.lib.getExe faulty} \
    ${pkgs.lib.getExe' pkgs.emacs-nox "emacs"} ${semantics} ${documentList} "$out"
''
