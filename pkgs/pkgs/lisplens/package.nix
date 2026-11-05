{
  src,
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  inherit src;

  pname = "lisplens";
  version = "0.6.0";

  cargoHash = "sha256-P5tHg8le05a45SC6iRPs9S9yxPLkvrBB0+WP8IvvP0M=";

  meta = {
    description = "Polyglot Lisp CLI with dialect-aware formatting and structural editing";
    homepage = "https://github.com/rigortype/lisplens";
    changelog = "https://github.com/rigortype/lisplens/releases/tag/v0.6.0";
    license = lib.licenses.mpl20;
    mainProgram = "lisplens";
    platforms = lib.platforms.unix;
  };
}
