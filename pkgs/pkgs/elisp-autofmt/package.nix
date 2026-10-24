{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  emacs-nox,
  python3,
  nix-update-script,
}:
let
  python = python3.withPackages (pythonPackages: [ pythonPackages.pygments ]);
in
stdenvNoCC.mkDerivation {
  pname = "elisp-autofmt";
  version = "0-unstable-2026-08-11";

  src = fetchFromGitHub {
    owner = "emacsmirror";
    repo = "elisp-autofmt";
    rev = "a41fe15d3d2c69a6f069bab4d90caab8a4b62be7";
    hash = "sha256-5UHY8xkdVlB+YZdXdaDYBeUg0tFYuU2gdNlVspm4Ons=";
  };

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

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch=master"
    ];
  };
}
