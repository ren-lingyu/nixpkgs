{ pkgs } : {

  # example-package = pkgs.callPackage ./example-package { };
  # some-qt5-package = pkgs.libsForQt5.callPackage ./some-qt5-package { };
  
  texlive = {
    recurseForDerivations = true;
    luadraw = pkgs.callPackage ./texlive/luadraw { };
  };

}
