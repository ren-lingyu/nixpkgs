{ lib } : markerNames_ : tree_ : let
  
  hasMarkerName_ = name_ : builtins.elem name_ markerNames_;

  stripMarkers_ = value_ : (
    if
      lib.isDerivation value_
    then
      value_
    else (
      if
        builtins.isAttrs value_
      then
        lib.mapAttrs (unused_name_ : child_ : stripMarkers_ child_) (
          lib.filterAttrs (name_: unused_child_: !(hasMarkerName_ name_)) value_
        )
      else
        value_
    )
  );

in (

  stripMarkers_ tree_

)
