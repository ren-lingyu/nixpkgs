{
  llib,
  lib,
  pkgs,
}:
let
  helpers_ = llib.tests;
  basicRoot_ = ./fixtures/test-api/basic;
  extractionRoot_ = ./fixtures/test-api/extraction;
  makeScope_ =
    root_: overlayFile_: initial_:
    (lib.makeScope pkgs.newScope (_: { inherit lib pkgs llib; } // initial_)).overrideScope (
      lib.composeManyExtensions (
        builtins.attrValues (
          helpers_.mkOverlays {
            root = root_;
            overlayFile = overlayFile_;
          }
        )
      )
    );
  scope_ = makeScope_ basicRoot_ "overlay.nix" { };
  checks_ = helpers_.mkChecks {
    root = basicRoot_;
    overlayFile = "overlay.nix";
    scope = scope_;
  };
  renamed_ =
    separator_:
    helpers_.mkChecks {
      root = basicRoot_;
      overlayFile = "overlay.nix";
      scope = scope_;
      separator = separator_;
    };
  drv_ = pkgs.writeText "test-api-extraction" "extraction";
  extract_ =
    scope_:
    helpers_.mkChecks {
      root = extractionRoot_;
      overlayFile = "overlay.nix";
      scope = scope_;
    };
  branch_ = {
    child = drv_;
  };
  extracted_ = extract_ {
    leaf = drv_;
    branch = branch_;
  };
  skipLeaf_ =
    leaf_:
    builtins.attrNames (extract_ {
      leaf = leaf_;
      branch = branch_;
    }) == [ "branch/child" ];
  rejects_ = value_: !(builtins.tryEval (builtins.deepSeq value_ true)).success;
  factoryRoot_ = ./fixtures/test-api/factory;
  factoryScope_ = makeScope_ factoryRoot_ "overlay.nix" { };
  factoryChecks_ = helpers_.mkChecks {
    root = factoryRoot_;
    overlayFile = "overlay.nix";
    scope = factoryScope_;
  };
  relocatedRoot_ = ./fixtures/test-api/relocated;
  relocatedScope_ = makeScope_ relocatedRoot_ "overlay.nix" { };
  customRoot_ = ./fixtures/test-api/custom;
  customChecks_ = helpers_.mkChecks {
    root = customRoot_;
    overlayFile = "check.nix";
    scope = makeScope_ customRoot_ "check.nix" { };
  };
  changedScope_ = scope_.overrideScope (final_: prev_: { shared = "replacement"; });
  realChecks_ = import ./test-checks.nix { inherit llib lib pkgs; };
  tests_ = {
    topLevelOverlays =
      builtins.attrNames (
        helpers_.mkOverlays {
          root = basicRoot_;
          overlayFile = "overlay.nix";
        }
      ) == [
        "checks"
        "emacsPackages"
        "helpers"
        "missing"
        "shared"
        "texlivePackages"
        "validators"
        "values"
      ];
    scopeIsCallerConstructed = scope_ ? callPackage && scope_ ? overrideScope && scope_ ? newScope;
    siblingDependency = scope_.checks.alpha.testMarker == "scope-dependency:alpha";
    nestedDependency = scope_.checks.nested.beta.testMarker == "scope-dependency:beta";
    topLevelDependency = scope_.validators.testMarker == "scope-dependency:validators";
    overriddenDependency = changedScope_.checks.alpha.testMarker == "replacement:alpha";
    overriddenDependencyChangesDerivation =
      changedScope_.checks.alpha.drvPath != scope_.checks.alpha.drvPath;
    emacsNameIsGeneric = scope_.emacsPackages.sample.marker == "generic-emacs-name";
    texNameIsGeneric = scope_.texlivePackages.sample.marker == "generic-tex-name";
    noPackageFactories = !(scope_ ? emacsPackagesFor) && !(scope_ ? texlive);
    flatNames =
      builtins.attrNames checks_ == [
        "checks/alpha"
        "checks/nested/beta"
        "validators"
      ];
    allChecksAreDerivations = builtins.all lib.isDerivation (builtins.attrValues checks_);
    originalDerivationsPreserved = checks_."checks/alpha".drvPath == scope_.checks.alpha.drvPath;
    defaultSeparator = checks_ ? "checks/nested/beta";
    dashSeparator =
      builtins.attrNames (renamed_ "-") == [
        "checks-alpha"
        "checks-nested-beta"
        "validators"
      ];
    dotSeparator =
      builtins.attrNames (renamed_ ".") == [
        "checks.alpha"
        "checks.nested.beta"
        "validators"
      ];
    emptySeparator =
      builtins.attrNames (renamed_ "") == [
        "checksalpha"
        "checksnestedbeta"
        "validators"
      ];
    managementMembersNotExported =
      !(checks_ ? callPackage) && !(checks_ ? newScope) && !(checks_ ? overrideScope);
    helperFunctionNotExported = builtins.isFunction scope_.helpers && !(checks_ ? helpers);
    helperNamedDerivationIsExported =
      (helpers_.mkChecks {
        root = basicRoot_;
        overlayFile = "overlay.nix";
        scope = scope_ // {
          helpers = drv_;
        };
      }).helpers.drvPath == drv_.drvPath;
    valueAttrsetNotTraversed = lib.isDerivation scope_.values.nested && !(checks_ ? "values/nested");
    unmatchedOutputNotExported =
      scope_.unmapped == "not a directory-matched check" && !(checks_ ? unmapped);
    extractionDoesNotImportOverlays =
      builtins.attrNames extracted_ == [
        "branch/child"
        "leaf"
      ];
    extractionLeafIdentity = extracted_.leaf.drvPath == drv_.drvPath;
    skipStringLeaf = skipLeaf_ "value";
    skipFunctionLeaf = skipLeaf_ (x_: x_);
    skipListLeaf = skipLeaf_ [ drv_ ];
    skipNullLeaf = skipLeaf_ null;
    skipBoolLeaf = skipLeaf_ false;
    skipAttrsetLeaf = skipLeaf_ {
      hidden = drv_;
      poison = throw "do not traverse leaf attributes";
    };
    skipMissingLeaf =
      builtins.attrNames (extract_ {
        branch = branch_;
      }) == [ "branch/child" ];
    namespaceOnlyUsesDirectoryChildren =
      builtins.attrNames (extract_ {
        branch = branch_ // {
          extra = throw "do not traverse extra namespace members";
        };
        unrelated = throw "do not enumerate scope members";
        ignored = throw "directories without overlays must not force values";
      }) == [ "branch/child" ];
    missingNamespaceFails = rejects_ (extract_ {
      leaf = drv_;
    });
    scalarNamespaceFails = rejects_ (extract_ {
      branch = 7;
    });
    nullNamespaceFails = rejects_ (extract_ {
      branch = null;
    });
    functionNamespaceFails = rejects_ (extract_ {
      branch = x_: x_;
    });
    derivationWithDescendantsFails = rejects_ (extract_ {
      branch = drv_;
    });
    missingNestedLeafSkipped = extract_ { branch = { }; } == { };
    rootOverlayIgnored =
      helpers_.mkChecks {
        root = extractionRoot_ + "/leaf";
        overlayFile = "overlay.nix";
        scope = drv_;
      } == { };
    emptyTree =
      helpers_.mkChecks {
        root = basicRoot_ + "/empty";
        overlayFile = "overlay.nix";
        scope = throw "empty discovery must not force scope";
      } == { };
    explicitFactoryDescendantsOnce = factoryScope_.group.check.applications == 1;
    explicitFactoryExtraction = builtins.attrNames factoryChecks_ == [ "group/check" ];
    relocatedFactoryResultExists = lib.isDerivation relocatedScope_.relocated.check;
    relocatedFactoryDoesNotRemap = rejects_ (
      helpers_.mkChecks {
        root = relocatedRoot_;
        overlayFile = "overlay.nix";
        scope = relocatedScope_;
      }
    );
    customFilename =
      builtins.attrNames customChecks_ == [ "item" ] && lib.isDerivation customChecks_.item;
    realSmokeCheckNames =
      builtins.attrNames realChecks_ == [
        "testApi/checks/alpha"
        "testApi/checks/nested/beta"
        "testApi/validators"
      ];
    realSmokeChecksAreDerivations = builtins.all lib.isDerivation (builtins.attrValues realChecks_);
  };
  failed_ = builtins.filter (name_: !(tests_.${name_})) (builtins.attrNames tests_);
in
if failed_ == [ ] then
  tests_
else
  builtins.throw "test API tests failed: ${builtins.toJSON failed_}"
