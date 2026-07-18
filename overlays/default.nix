let

  pkgs_ = import ../pkgs;

  lib_ = import ../lib;

in {

  default = final : prev : let

    lib = prev.lib;

    repoLib_ = lib_ { pkgs = prev; };

    packageTree_ = pkgs_ { pkgs = final; };

    packageTreeClean_ = repoLib_.stripPackageTreeMarkers packageTree_;

    overlayTree_ = repoLib_.mkRecursiveOverlay prev packageTree_;

    texlivePackageTree_ = packageTreeClean_.texlive or {};

    texlive_ = overlayTree_.texlive or prev.texlive;

    extraTexlivePackages_ = lib.mapAttrs (name_ : unused_value_ : texlive_.${name_}) texlivePackageTree_;

    extendTexlivePackageSet_ = ps_ : ps_ // extraTexlivePackages_;

    wrapTexliveEnv_ = texliveEnv_ : (
      if
        builtins.isAttrs texliveEnv_ && builtins.hasAttr "withPackages" texliveEnv_
      then
        texliveEnv_ // {
          withPackages = f_ : texliveEnv_.withPackages (ps_ : f_ (extendTexlivePackageSet_ ps_));
        }
      else
        texliveEnv_
    );

    texliveEnvNames_ = [
      "texliveBasic"
      "texliveBookPub"
      "texliveConTeXt"
      "texliveFull"
      "texliveGUST"
      "texliveInfraOnly"
      "texliveMedium"
      "texliveMinimal"
      "texliveSmall"
      "texliveTeTeX"
    ];

    wrappedTexliveEnvs_ = builtins.listToAttrs (
      map (name_ : {
        name = name_;
        value = wrapTexliveEnv_ prev.${name_};
      }) (builtins.filter (name_ : builtins.hasAttr name_ prev) texliveEnvNames_)
    );

  in lib.mergeAttrsList [

    overlayTree_

    wrappedTexliveEnvs_

    {
      texlive = lib.mergeAttrsList [
        texlive_
        {
          withPackages = f_ : texlive_.withPackages (ps_ : f_ (extendTexlivePackageSet_ ps_));
          combined = lib.mergeAttrsList [
            texlive_.combined
            (lib.mapAttrs (unused_name_ : texliveEnv_ : wrapTexliveEnv_ texliveEnv_) texlive_.combined)
          ];
        }
      ];
    }

  ];

}
