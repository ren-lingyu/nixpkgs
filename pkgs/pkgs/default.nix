{ llib }: {
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
        ];
      };

      nix = {
        include = [ "nix-flake-patched" ];
      };

      legacy = {
        export = true;
      };
    };
  };
}
