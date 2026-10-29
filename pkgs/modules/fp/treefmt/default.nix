{ lib, moduleLocation, ... }: {
  config = {
    perSystem = { pkgs, ... }: {
      treefmt = {
        flakeFormatter = true;
        flakeCheck = lib.mkDefault true;
        enableDefaultExcludes = lib.mkForce false;
        projectRootFile = builtins.baseNameOf (toString moduleLocation);

        settings = {
          excludes = lib.mkDefault [ ];
          on-unmatched = "fatal";
          formatter = {
            gitignore-fmt = {
              command = lib.getExe pkgs.gitignore-fmt;
              includes = [
                ".gitignore"
                "**/.gitignore"
              ];
            };

            lisplens = {
              command = lib.getExe pkgs.lisplens;
              options = [ "format" ];
              includes = [
                "*.scm"
                "**/*.scm"
              ];
            };

            elisp-autofmt = {
              command = lib.getExe pkgs.elisp-autofmt;
              includes = [
                "*.el"
                "**/*.el"
              ];
            };

            cabal-project-fmt = {
              command = lib.getExe pkgs.haskellPackages.cabal-fmt;
              options = [
                "--no-cabal-file"
                "--inplace"
              ];
              includes = [
                "**/cabal*.project"
                "**/cabal.project.local"
              ];
            };
          };
        };

        programs = {
          nixfmt = {
            enable = true;
            package = pkgs.nixfmt;
            width = 100;
            indent = 2;
            strict = true;
          };

          shfmt = {
            enable = true;
            package = pkgs.shfmt;
            indent_size = 2;
            simplify = false;
          };

          prettier = {
            enable = true;
            package = pkgs.prettier;
            settings = {
              printWidth = 100;
              tabWidth = 2;
              proseWrap = "preserve";
              endOfLine = "lf";
            };
          };

          fourmolu = {
            enable = true;
            package = pkgs.haskellPackages.fourmolu;
          };

          cabal-fmt = {
            enable = true;
            package = pkgs.haskellPackages.cabal-fmt;
          };

          xmllint = {
            enable = true;
            package = pkgs.libxml2;
          };

          ruff-format = {
            enable = true;
            package = pkgs.ruff;
            lineLength = 100;
          };

          taplo = {
            enable = true;
            package = pkgs.taplo;
          };
        };
      };
    };
  };
}
