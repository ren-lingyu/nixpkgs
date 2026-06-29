{ lib } : stripPackageTreeMarkers_ : oldTree_ : newTree_ : let
  
  deepOverlay_ = old_ : new_ : (
    if
      lib.isDerivation new_ || lib.isDerivation old_
    then
      new_
    else (
      if
        builtins.isAttrs old_ && builtins.isAttrs new_
      then
        old_ // lib.mapAttrs (name_ : newChild_ : deepOverlay_ (
          if
            builtins.hasAttr name_ old_
          then
            builtins.getAttr name_ old_
          else
            { }
        ) newChild_) new_
      else
        new_
    )
  );

  overlayTree_ = stripPackageTreeMarkers_ newTree_;

in (

  lib.mapAttrs (name_ : newValue_ : deepOverlay_ (
    if
      builtins.hasAttr name_ oldTree_
    then
      builtins.getAttr name_ oldTree_
    else
      { }
  ) newValue_) overlayTree_

)
