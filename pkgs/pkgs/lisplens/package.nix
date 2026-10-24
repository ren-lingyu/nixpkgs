{
  lib,
  fetchFromGitHub,
  rustPlatform,
  nix-update-script,
}:
rustPlatform.buildRustPackage {
  pname = "lisplens";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "rigortype";
    repo = "lisplens";
    rev = "v0.6.0";
    hash = "sha256-K0QzGwW7pSQ5hJn5W6iJffqaQeaGx1guPHomLKEXzzc=";
  };

  cargoHash = "sha256-P5tHg8le05a45SC6iRPs9S9yxPLkvrBB0+WP8IvvP0M=";

  meta = {
    description = "Polyglot Lisp CLI with dialect-aware formatting and structural editing";
    homepage = "https://github.com/rigortype/lisplens";
    changelog = "https://github.com/rigortype/lisplens/releases/tag/v0.6.0";
    license = lib.licenses.mpl20;
    mainProgram = "lisplens";
    platforms = lib.platforms.unix;
  };

  passthru.updateScript = nix-update-script { extraArgs = [ "--flake" ]; };
}
