{ pkgs, gitignore-fmt }:
let
  shim =
    command:
    pkgs.writeShellScriptBin command ''
      if [[ ''${GITIGNORE_FMT_FAIL-} == ${command} ]] || {
        [[ ${command} == cp && ''${GITIGNORE_FMT_FAIL-} == cp-preserve && $1 == --preserve=mode ]]
      } || {
        [[ ${command} == mktemp && ''${GITIGNORE_FMT_FAIL-} == mktemp-replacement && $1 == -- ]]
      }; then
        if [[ ${command} == cat ]]; then printf 'partial output'; fi
        printf 'injected ${command} failure\n' >&2
        exit 2
      fi
      exec ${if command == "cmp" then pkgs.diffutils else pkgs.coreutils}/bin/${command} "$@"
    '';
  faulty = gitignore-fmt.override {
    coreutils = pkgs.symlinkJoin {
      name = "gitignore-fmt-fault-coreutils";
      paths =
        (map shim [
          "sort"
          "cmp"
          "cat"
          "cp"
          "mv"
          "mktemp"
          "mkdir"
        ])
        ++ [ pkgs.coreutils ];
    };
  };
  runner = pkgs.writeText "gitignore-fmt-tests.py" (import ./runner.nix);
in
pkgs.runCommand "gitignore-fmt-regressions" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  ${pkgs.python3}/bin/python ${runner} \
    ${pkgs.lib.getExe gitignore-fmt} ${pkgs.lib.getExe faulty} "$out"
''
