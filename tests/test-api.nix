{
  llib,
  lib,
  pkgs,
}:
let
  helpers_ = llib.tests;
  args_ = {
    inherit lib pkgs llib;
    inherit (pkgs) writeText;
  };
  basicRoot_ = ./fixtures/test-api/basic;
  extractionRoot_ = ./fixtures/test-api/extraction;
  checks_ = helpers_.mkChecks {
    root = basicRoot_;
    overlayFile = "overlay.nix";
    args = args_;
  };
  renamed_ =
    separator_:
    helpers_.mkChecks {
      root = basicRoot_;
      overlayFile = "overlay.nix";
      args = args_;
      separator = separator_;
    };
  drv_ = pkgs.writeText "test-api-extraction" "extraction";
  extract_ =
    scope_:
    helpers_.mkChecks {
      root = extractionRoot_;
      overlayFile = "overlay.nix";
      args = scope_;
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
  factoryChecks_ = helpers_.mkChecks {
    root = factoryRoot_;
    overlayFile = "overlay.nix";
    args = args_;
  };
  relocatedRoot_ = ./fixtures/test-api/relocated;
  customRoot_ = ./fixtures/test-api/custom;
  customChecks_ = helpers_.mkChecks {
    root = customRoot_;
    overlayFile = "check.nix";
    args = args_;
  };
  changedChecks_ = helpers_.mkChecks {
    root = basicRoot_;
    overlayFile = "overlay.nix";
    args = args_ // {
      writeText = name_: text_: (pkgs.writeText name_ "injected:${text_}") // { injected = true; };
    };
  };
  realChecks_ = import ./test-checks.nix { inherit llib lib pkgs; };
  initial_ = drv_ // {
    testMarker = "initial";
  };
  assembled_ = helpers_.mkChecks {
    root = ./fixtures/test-api/assembly;
    overlayFile = "overlay.nix";
    checks = {
      existing = initial_;
      retained = drv_;
    };
    args = args_ // {
      existing = throw "initial checks must win over args";
      dependencyDrv = drv_;
      unused = throw "unselected args must stay lazy";
    };
  };
  tests_ = {
    existingCheckRetained = assembled_.retained.drvPath == drv_.drvPath;
    existingCheckReplacementChangesDerivation = assembled_.existing.drvPath != initial_.drvPath;
    existingCheckOverriddenInOrder = assembled_.existing.testMarker == "initial:first:second";
    explicitCallPackageArgumentWins = assembled_.dependent.explicitMarker == "initial";
    callPackageUsesFinalChecks = assembled_.dependent.testMarker == "initial:first:second";
    argsDerivationNotExported = !(assembled_ ? dependencyDrv);
    packagesNameNotMasked = lib.isDerivation assembled_.packages;
    callPackageResolvesPackagesCheck = assembled_.dependent.packagesPath == assembled_.packages.drvPath;
    assembledNames =
      builtins.attrNames assembled_ == [
        "dependent"
        "existing"
        "packages"
        "retained"
      ];
    defaultChecksAndArgs =
      helpers_.mkChecks {
        root = basicRoot_ + "/empty";
        overlayFile = "overlay.nix";
      } == { };
    existingChecksWithoutDirectories =
      (helpers_.mkChecks {
        root = basicRoot_ + "/empty";
        overlayFile = "overlay.nix";
        checks.retained = drv_;
      }).retained.drvPath == drv_.drvPath;
    invalidExistingCheckFails = rejects_ (
      helpers_.mkChecks {
        root = basicRoot_ + "/empty";
        overlayFile = "overlay.nix";
        checks.invalid = "not a derivation";
      }
    );
    onlyMkChecksPublic = builtins.attrNames helpers_ == [ "mkChecks" ];
    callPackageAndNewScopeAvailable = checks_.validators.scopeObservation.helpersAvailable;
    siblingDependency = checks_."checks/alpha".testMarker == "scope-dependency:alpha";
    nestedDependency = checks_."checks/nested/beta".testMarker == "scope-dependency:beta";
    topLevelDependency = checks_.validators.testMarker == "scope-dependency:validators";
    injectedDependency = changedChecks_."checks/alpha".injected;
    injectedDependencyChangesDerivation =
      changedChecks_."checks/alpha".drvPath != checks_."checks/alpha".drvPath;
    emacsNameIsGeneric = checks_.validators.scopeObservation.emacsMarker == "generic-emacs-name";
    texNameIsGeneric = checks_.validators.scopeObservation.texMarker == "generic-tex-name";
    noPackageFactories = checks_.validators.scopeObservation.noPackageFactories;
    flatNames =
      builtins.attrNames checks_ == [
        "checks/alpha"
        "checks/nested/beta"
        "validators"
      ];
    allChecksAreDerivations = builtins.all lib.isDerivation (builtins.attrValues checks_);
    originalDerivationsPreserved =
      checks_."checks/alpha".drvPath == (pkgs.writeText "test-api-alpha" "scope-dependency:alpha")
      .drvPath;
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
    helperFunctionNotExported =
      checks_.validators.scopeObservation.helperIsFunction && !(checks_ ? helpers);
    overriddenCheckMustRemainDerivation = rejects_ (
      helpers_.mkChecks {
        root = basicRoot_;
        overlayFile = "overlay.nix";
        args = args_;
        checks.helpers = drv_;
      }
    );
    valueAttrsetNotTraversed =
      checks_.validators.scopeObservation.hiddenValueIsDerivation && !(checks_ ? "values/nested");
    unmatchedOutputNotExported =
      checks_.validators.scopeObservation.unmapped == "not a directory-matched check"
      && !(checks_ ? unmapped);
    directorySelectedExtraction =
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
        args = {
          ignored = drv_;
        };
      } == { };
    emptyTree =
      helpers_.mkChecks {
        root = basicRoot_ + "/empty";
        overlayFile = "overlay.nix";
        args = throw "empty discovery must not force args";
      } == { };
    explicitFactoryDescendantsOnce = factoryChecks_."group/check".applications == 1;
    explicitFactoryExtraction = builtins.attrNames factoryChecks_ == [ "group/check" ];
    relocatedFactoryDoesNotRemap = rejects_ (
      helpers_.mkChecks {
        root = relocatedRoot_;
        overlayFile = "overlay.nix";
        args = args_;
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
