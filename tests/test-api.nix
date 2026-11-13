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
  constructorChecks_ = helpers_.mkChecks {
    root = ./fixtures/test-api/constructor;
    overlayFile = "overlay.nix";
    args = args_ // {
      projectMarker = "scope-only";
      extraArgs.marker = "args-member";
    };
  };
  structuredRoot_ = ./fixtures/test-api/structured;
  structured_ = helpers_.mkChecks {
    root = structuredRoot_;
    overlayFile = "overlay.nix";
    separator = "-";
    args = args_;
    checks = {
      group = {
        first = initial_;
        unlisted = drv_;
        empty = { };
      };
      bundle.nested.check = initial_;
      ordinary = {
        packages = drv_;
        callPackage = drv_;
      };
      empty = { };
    };
  };
  explicitOnly_ =
    checks_: separator_:
    helpers_.mkChecks {
      root = basicRoot_ + "/empty";
      overlayFile = "overlay.nix";
      checks = checks_;
      separator = separator_;
    };
  replaceGroup_ =
    declared_: replacement_:
    helpers_.mkChecks {
      root = ./fixtures/test-api/explicit-shape;
      overlayFile = "overlay.nix";
      args = args_ // {
        replacement = replacement_;
      };
      checks.group = declared_;
    };
  resolvedScope_ = replaceGroup_ { first = initial_; } (
    lib.makeScope
      (
        extra_:
        lib.callPackageWith (
          lib.mergeAttrsList [
            args_
            extra_
          ]
        )
      )
      (self_: {
        first = drv_;
        extra = self_.first;
        helper = value_: value_;
        self = self_;
      })
  );
  tests_ = {
    constructorEnvironmentDefaultsEmpty = constructorChecks_.probe.constructorIsEmpty;
    constructorDoesNotConsumeScopeArgs = constructorChecks_.probe.scopeMarker == "scope-only";
    argsExtraArgsDoesNotBecomeConstructorArgs =
      constructorChecks_.probe.scopeExtraArgs == "args-member"
      && constructorChecks_.probe.constructorIsEmpty;

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
    invalidExplicitRootDerivation = rejects_ (explicitOnly_ drv_ "-");
    invalidExplicitRootBoolean = rejects_ (explicitOnly_ false "-");
    invalidExplicitRootMarkedDerivation = rejects_ (explicitOnly_ (lib.recurseIntoAttrs drv_) "-");
    structuredNames =
      builtins.attrNames structured_ == [
        "bundle-nested-check"
        "group-first"
        "group-second"
        "group-unlisted"
        "ordinary-callPackage"
        "ordinary-packages"
      ];
    structuredDerivations = builtins.all lib.isDerivation (builtins.attrValues structured_);
    nestedCheckOverride = structured_.group-first.testMarker == "overridden";
    nestedDependencyFromExplicitCheck = structured_.group-second.dependencyMarker == "initial";
    nestedSiblingUsesFinalOverride = structured_.group-second.testMarker == "overridden";
    finalScopeMembersNotSelected = builtins.attrNames resolvedScope_ == [ "group/first" ];
    finalScopeOverride = resolvedScope_."group/first".drvPath == drv_.drvPath;
    explicitPathsDoNotExpand =
      builtins.attrNames (
        replaceGroup_ { first = initial_; } {
          first = drv_;
          extra = drv_;
          helper = value_: value_;
          poison = throw "unselected final member must stay lazy";
        }
      ) == [ "group/first" ];
    emptyExplicitNamespaceDoesNotExpand = replaceGroup_ { } { extra = drv_; } == { };
    missingExplicitPath = rejects_ (replaceGroup_ { nested.check = drv_; } { nested = { }; });
    explicitNamespaceCannotBecomeDerivation = rejects_ (replaceGroup_ { check = drv_; } drv_);
    explicitDerivationCannotBecomeNamespace = rejects_ (replaceGroup_ drv_ { check = drv_; });
    explicitNamespaceCannotBecomeScalar = rejects_ (replaceGroup_ { check = drv_; } false);
    invalidInitialCheckCannotBeRepairedByOverlay = rejects_ (replaceGroup_ false drv_);
    explicitMarkedRootAndNamespace =
      builtins.attrNames (
        explicitOnly_ (lib.recurseIntoAttrs {
          alpha = drv_;
          nested = lib.recurseIntoAttrs { beta = drv_; };
        }) "-"
      ) == [
        "alpha"
        "nested-beta"
      ];
    explicitFalseMarkerRejected = rejects_ (explicitOnly_ { recurseForDerivations = false; } "-");
    explicitNestedFalseMarkerRejected = rejects_ (
      explicitOnly_ { nested.recurseForDerivations = false; } "-"
    );
    explicitMarkerNameDerivation =
      builtins.attrNames (explicitOnly_ { recurseForDerivations = drv_; } "-")
      == [ "recurseForDerivations" ];
    explicitMarkerNameNamespace =
      builtins.attrNames (explicitOnly_ { recurseForDerivations.check = drv_; } "-")
      == [ "recurseForDerivations-check" ];
    explicitOtherBooleanRejected = rejects_ (explicitOnly_ { other = true; } "-");
    explicitFunctionRejected = rejects_ (explicitOnly_ { group.helper = value_: value_; } "-");
    explicitMarkerDoesNotSelectFinalMember =
      builtins.attrNames (
        replaceGroup_ (lib.recurseIntoAttrs { first = drv_; }) {
          first = drv_;
          recurseForDerivations = drv_;
        }
      ) == [ "group/first" ];
    nestedExplicitSeparator =
      builtins.attrNames (explicitOnly_ { one.two.three = drv_; } ".") == [ "one.two.three" ];
    nestedExplicitEmptySeparator =
      builtins.attrNames (explicitOnly_ { one.two = drv_; } "") == [ "onetwo" ];
    nestedExplicitInvalidLeaf = rejects_ (explicitOnly_ { one.two = false; } "-");
    nestedExplicitEmptyTree = explicitOnly_ { one.two = { }; } "-" == { };
    derivationIsLeaf =
      builtins.attrNames (
        explicitOnly_ {
          one.two = lib.mergeAttrsList [
            drv_
            { poison = throw "must not traverse derivation"; }
          ];
        } "-"
      ) == [ "one-two" ];
    markedDerivationIsLeaf =
      let
        marked_ = explicitOnly_ { alpha = lib.recurseIntoAttrs drv_; } "-";
      in
      builtins.attrNames marked_ == [ "alpha" ]
      && lib.isDerivation marked_.alpha
      && marked_.alpha.drvPath == drv_.drvPath
      && marked_.alpha.recurseForDerivations;
    flattenedNameCollision = rejects_ (
      builtins.attrNames (
        explicitOnly_ {
          one-two = drv_;
          one.two = drv_;
        } "-"
      )
    );
    explicitDiscoveredNameCollision = rejects_ (
      helpers_.mkChecks {
        root = extractionRoot_;
        overlayFile = "overlay.nix";
        args = {
          branch = branch_;
        };
        checks."branch/child" = drv_;
      }
    );
    explicitSelectionDoesNotMaskInvalidDirectoryNamespace = rejects_ (
      helpers_.mkChecks {
        root = extractionRoot_;
        overlayFile = "overlay.nix";
        checks.branch = drv_;
      }
    );
    nestedMkChecks =
      builtins.attrNames (explicitOnly_ { wrapper = explicitOnly_ { group.check = drv_; } "-"; } "-")
      == [ "wrapper-group-check" ];
    markedLeafStillSkipped = skipLeaf_ (lib.recurseIntoAttrs { hidden = drv_; });
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
    overriddenCheckMustRemainValidTestTree = rejects_ (
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
