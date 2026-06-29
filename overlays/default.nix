let

  pkgs_ = import ../pkgs;

  lib_ = import ../lib;
    
in {
  
  default = final : prev : let
    repoLib_ = lib_ {
      pkgs = prev;
    };
    packageTree_ = pkgs_ {
      pkgs = final;
    };
  in repoLib_.mkRecursiveOverlay prev packageTree_;
  
}
