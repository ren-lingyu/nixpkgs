{ haskell, haskellPackages }:
haskell.lib.overrideCabal (haskellPackages.callCabal2nix "gitignore-fmt" ./cabal { }) (_: {
  doCheck = true;
  doHaddock = false;
  mainProgram = "gitignore-fmt";
})
