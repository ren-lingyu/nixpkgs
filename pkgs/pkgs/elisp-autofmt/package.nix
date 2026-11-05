{
  src,
  lib,
  stdenvNoCC,
  makeWrapper,
  emacs-nox,
  python3,
}:
let
  python = python3.withPackages (pythonPackages: [ pythonPackages.pygments ]);
in
stdenvNoCC.mkDerivation {
  inherit src;

  pname = "elisp-autofmt";
  version = "0.1";

  patches = [ ./load-use-package.patch ];

  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -d "$out/bin"
    install -d "$out/libexec/elisp-autofmt"
    install -d "$out/share/doc/elisp-autofmt"

    install -m644 \
      elisp-autofmt.el \
      elisp-autofmt.py \
      elisp-autofmt.overrides.json \
      "$out/libexec/elisp-autofmt/"

    install -m755 \
      elisp-autofmt-cmd.py \
      "$out/libexec/elisp-autofmt/"

    install -m644 \
      LICENSE \
      readme.rst \
      "$out/share/doc/elisp-autofmt/"

    makeWrapper \
      ${python}/bin/python3 \
      "$out/bin/elisp-autofmt" \
      --add-flags "$out/libexec/elisp-autofmt/elisp-autofmt-cmd.py" \
      --prefix PATH : "${
        lib.makeBinPath [
          emacs-nox
          python
        ]
      }"

    runHook postInstall
  '';

  meta = {
    description = "Automatic formatter for Emacs Lisp";
    homepage = "https://codeberg.org/ideasman42/emacs-elisp-autofmt";
    license = lib.licenses.gpl3Plus;
    mainProgram = "elisp-autofmt";
    platforms = lib.platforms.unix;
  };
}
