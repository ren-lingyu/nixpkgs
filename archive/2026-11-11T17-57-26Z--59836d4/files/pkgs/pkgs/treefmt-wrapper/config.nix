{ pkgs, lib, ... }: {
  enableDefaultExcludes = lib.mkForce false;

  settings = {
    excludes = lib.mkDefault [ ];
    on-unmatched = "fatal";
    formatter = {
      gitignore-fmt = {
        command = lib.getExe pkgs.gitignore-fmt;
        includes = [
          "gitignore"
          "**/gitignore"
          ".gitignore"
          "**/.gitignore"
          "*.gitignore"
          "**/*.gitignore"
        ];
      };

      text-fmt = {
        command = lib.getExe pkgs.text-fmt;
        includes = [
          "*.txt"
          "**/*.txt"
        ];
      };

      org-fmt = {
        command = lib.getExe pkgs.org-fmt;
        includes = [
          "*.org"
          "**/*.org"
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

      bibtex-tidy = {
        command = lib.getExe (
          pkgs.writeShellScriptBin "bibtex-tidy" ''
            # Treefmt supplies file paths even when stdin is not a terminal.
            export PRE_COMMIT=1
            exec ${lib.getExe pkgs.bibtex-tidy} "$@"
          ''
        );
        options = [
          "--modify"
          "--no-backup"
          "--space=2"
          "--align=14"
          "--blank-lines"
          "--no-sort"
          "--no-curly"
          "--no-numeric"
          "--no-escape"
          "--no-lowercase"
          "--no-remove-dupe-fields"
          "--tidy-comments"
          "--no-strip-comments"
          "--no-remove-empty-fields"
          "--no-wrap"
        ];
        includes = [
          "*.bib"
          "**/*.bib"
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
}
