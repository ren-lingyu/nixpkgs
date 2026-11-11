{ lib, moduleLocation, ... }: {
  config = {
    perSystem = { pkgs, ... }: {
      treefmt = {
        imports = pkgs.treefmt-wrapper.passthru.imports;
        flakeFormatter = true;
        flakeCheck = lib.mkDefault true;
        projectRootFile = builtins.baseNameOf (builtins.toString moduleLocation);
      };
    };
  };
}
