{ lib, overlayTree }:
let
  root_ = ./fixtures;
  overlays_ = overlayTree.mkOverlays {
    root = root_;
    overlayFile = "overlay.nix";
  };
  # The custom-filename fixture is selected only in its dedicated case.
  selected_ = builtins.removeAttrs overlays_ [ "custom" ];
  combined_ = lib.composeManyExtensions (builtins.attrValues selected_);
  base_ = final_: {
    inherit lib;
    parentMarker = "parent";
    newScope = scope_: lib.callPackageWith (final_ // scope_);
    plain = {
      kept = "plain-kept";
    };
  };
  apply_ =
    extra_: extension_: lib.fix (lib.extends extension_ (final_: base_ final_ // extra_ final_));
  generic_ = apply_ (_: { }) combined_;
  scoped_ = apply_ (final_: {
    space = lib.makeScope final_.newScope (self_: {
      sibling.marker = "old";
      dependent.marker = self_.sibling.marker;
      kept = "scope-kept";
    });
  }) combined_;
  attrset_ = apply_ (_: { space.kept = "attrset-kept"; }) combined_;
  implicitOverlays_ = {
    implicit = final_: prev_: {
      implicitSelected = true;
      implicit = {
        seed = "implicit-local";
      };
    };
    plain = throw "explicit ordinary overlays must take precedence";
    factory = throw "explicit factories must take precedence";
    empty = throw "empty directories must not evaluate implicit overlays";
    absent = throw "implicit rules must not create absent directories";
  };
  implicit_ = apply_ (_: { }) (
    lib.composeManyExtensions (
      builtins.attrValues (
        builtins.removeAttrs (overlayTree.mkOverlays {
          root = root_;
          overlayFile = "overlay.nix";
          implicitOverlays = implicitOverlays_;
        }) [ "custom" ]
      )
    )
  );
  factory_ = apply_ (_: { }) (
    lib.composeManyExtensions (
      builtins.attrValues (
        builtins.removeAttrs (overlayTree.mkOverlays {
          root = root_;
          overlayFile = "overlay.nix";
          implicitOverlays = {
            implicit = { descendantOverlay }: final_: prev_: {
              implicit =
                (lib.makeScope final_.newScope (_: {
                  seed = "implicit-factory";
                })).overrideScope
                  descendantOverlay;
            };
          };
        }) [ "custom" ]
      )
    )
  );
  custom_ = apply_ (_: { }) (
    lib.composeManyExtensions (
      builtins.attrValues (
        overlayTree.mkOverlays {
          root = root_ + "/custom";
          overlayFile = "custom.nix";
        }
      )
    )
  );
  rejects_ = value_: !(builtins.tryEval (builtins.seq value_ true)).success;
  tests_ = {
    discoveredChildren =
      builtins.attrNames overlays_ == [
        "custom"
        "factory"
        "implicit"
        "plain"
        "space"
      ];
    selectedOverlaysAreFunctions = builtins.all builtins.isFunction (builtins.attrValues selected_);
    genericWithoutImplicitRules = generic_.implicit.item.marker == "generic";
    genericHasNoImplicitMarker = !(generic_ ? implicitSelected);
    newScopeParentDependency = generic_.space.tool.marker == "parent:sibling";
    nestedNamespaces = generic_.space.implicit.item.marker == "nested-generic";
    ordinaryOverlayApplied = generic_.ordinarySelected;
    ordinaryBeforeNamespace = generic_.plain.item.marker == "local";
    plainAttrsetPreserved = generic_.plain.kept == "plain-kept";
    existingScopePreserved = scoped_.space.kept == "scope-kept";
    existingScopeDependencyRebound = scoped_.space.dependent.marker == "sibling";
    existingScopeCallPackage = scoped_.space.tool.marker == "parent:sibling";
    existingAttrsetPreserved = attrset_.space.kept == "attrset-kept";
    existingAttrsetCallPackage = attrset_.space.tool.marker == "parent:sibling";
    explicitFactoryApplied = generic_.explicitFactory;
    explicitFactoryOwnsDescendants = generic_.factory.item.applications == 1;
    implicitOrdinaryApplied = implicit_.implicitSelected;
    implicitOrdinaryBeforeNamespace = implicit_.implicit.item.marker == "implicit-local";
    implicitRuleTopLevelOnly = implicit_.space.implicit.item.marker == "nested-generic";
    explicitOrdinaryPrecedence = implicit_.plain.item.marker == "local";
    explicitFactoryPrecedence = implicit_.factory.item.applications == 1;
    implicitFactoryApplied = factory_.implicit.item.marker == "implicit-factory";
    implicitFactoryOwnsDescendants = factory_.implicit.item.applications == 1;
    emptyAndAbsentNotCreated = !(implicit_ ? empty) && !(implicit_ ? absent);
    emptyDiscovery =
      overlayTree.mkOverlays {
        root = root_ + "/empty";
        overlayFile = "overlay.nix";
        implicitOverlays.empty = throw "unused";
      } == { };
    customFilename = custom_.item == "custom";
    scalarCollision = rejects_ (apply_ (_: { space = 1; }) combined_).space;
    derivationCollision = rejects_ (apply_ (_: { space.type = "derivation"; }) combined_).space;
    missingNewScope =
      rejects_
        (lib.fix (
          lib.extends combined_ (_: {
            inherit lib;
            plain = { };
          })
        )).space;
  };
  failed_ = builtins.filter (name_: !(tests_.${name_})) (builtins.attrNames tests_);
in
if failed_ == [ ] then
  tests_
else
  builtins.throw "overlays tests failed: ${builtins.toJSON failed_}"
