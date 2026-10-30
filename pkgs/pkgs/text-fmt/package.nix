{ haskell, haskellPackages }:
haskell.lib.overrideCabal (haskellPackages.callCabal2nix "text-fmt" ./cabal { }) (_: {
  doCheck = true;
  doHaddock = false;
  mainProgram = "text-fmt";
})
