{
  sources,
  llib,
  treefmt-nix-lib,
}:
{
  overlays = llib.packages.mkOverlays {
    root = ./.;
    overlayFile = "overlay.nix";
    groups = {
      treefmt = {
        include = [
          "elisp-autofmt"
          "gitignore-fmt"
          "lisplens"
          "org-fmt"
          "text-fmt"
          "treefmt-wrapper"
        ];
      };

      nix = {
        include = [ "nix-flake-patched" ];
      };

      legacy = {
        export = true;
      };
    };
    extraArgs = { inherit sources treefmt-nix-lib; };
  };
}
