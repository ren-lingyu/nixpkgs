{
  llib,
  lib,
  pkgs,
}:
let
  helpers_ = llib.packages;
  leaf_ = marker_: {
    type = "derivation";
    marker = marker_;
  };
  original_ = (leaf_ "original") // {
    originalOnly = true;
  };
  selector_ = {
    existing = original_;
    untouched = leaf_ "untouched";
    nested = {
      edited = leaf_ "nested-original";
      kept = leaf_ "nested-kept";
    };
  };
  environment_ = {
    withPackages = f_: f_ selector_;
    sentinel = "preserved";
  };
  environmentNames_ = [
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
  base_ =
    final_:
    {
      inherit lib;
      parentMarker = "parent";
      newScope = scope_: lib.callPackageWith (final_ // scope_);
      emacsPackagesFor =
        emacs_:
        lib.makeScope final_.newScope (_: {
          runtime = leaf_ emacs_.variant;
        });
      emacsPackages = final_.emacsPackagesFor { variant = "default"; };
      texlivePackages = selector_;
      texlive = environment_ // {
        combined = {
          small = environment_;
          scalar = 7;
        };
      };
    }
    // lib.genAttrs environmentNames_ (_: environment_);

  overlays_ =
    root_: overlayFile_:
    helpers_.mkOverlays {
      root = root_;
      overlayFile = overlayFile_;
    };
  groupOverlays_ =
    root_: groups_:
    helpers_.mkOverlays {
      root = root_;
      overlayFile = "overlay.nix";
      groups = groups_;
    };
  applyGroup_ =
    root_: config_: extra_:
    lib.fix (
      lib.extends (lib.composeManyExtensions (
        [ (groupOverlays_ root_ { selected = config_; }).selected ] ++ extra_
      )) base_
    );
  apply_ =
    root_: overlayFile_: extra_:
    lib.fix (
      lib.extends (lib.composeManyExtensions (
        builtins.attrValues (overlays_ root_ overlayFile_) ++ extra_
      )) base_
    );
  implicitRoot_ = ./fixtures/implicit;
  implicit_ = apply_ implicitRoot_ "overlay.nix" [ ];
  ordinary_ = apply_ ./fixtures/ordinary "overlay.nix" [ ];
  factory_ = apply_ ./fixtures/factory "overlay.nix" [ ];
  custom_ = apply_ ./fixtures/custom "custom.nix" [ ];
  outside_ = apply_ implicitRoot_ "overlay.nix" [
    (final_: prev_: {
      texlivePackages = prev_.texlivePackages // {
        externalNew = leaf_ "external-added";
        untouched = leaf_ "external-replacement";
      };
    })
  ];
  genericOverlay_ = lib.composeManyExtensions (
    builtins.attrValues (overlays_ implicitRoot_ "overlay.nix")
  );
  existingScope_ = lib.fix (
    lib.extends genericOverlay_ (
      final_:
      base_ final_
      // {
        piPackages = lib.makeScope final_.newScope (self_: {
          kept = leaf_ "scope-kept";
          sibling = leaf_ "scope-old";
          dependent = leaf_ self_.sibling.marker;
        });
      }
    )
  );
  existingAttrset_ = lib.fix (
    lib.extends genericOverlay_ (final_: base_ final_ // { piPackages.kept = leaf_ "attrset-kept"; })
  );
  guardedEnvironments_ = lib.fix (
    lib.extends genericOverlay_ (
      final_: (builtins.removeAttrs (base_ final_) environmentNames_) // { texliveFull = 17; }
    )
  );
  extracted_ = (applyGroup_ implicitRoot_ { export = true; } [ ]).legacyPackages;
  rejects_ = value_: !(builtins.tryEval (builtins.seq value_ true)).success;

  parameterized_ = lib.fix (
    lib.extends (lib.composeManyExtensions (
      builtins.attrValues (
        helpers_.mkOverlays {
          root = ./constructor-fixtures;
          overlayFile = "overlay.nix";
          groups.legacy.export = true;
          extraArgs = {
            marker = "public-parameter";
            unused = throw "public unused constructor arg";
          };
        }
      )
    )) base_
  );
  groupRoot_ = ./group-fixtures;
  groups_ = groupOverlays_ groupRoot_ {
    default = { };
    share.exclude = [ "a" ];
    legacy.export = true;
    custom.export = "customName";
    off.export = false;
    empty = {
      exclude = [
        "a"
        "z"
      ];
      export = true;
    };
  };
  grouped_ = name_: lib.fix (lib.extends groups_.${name_} base_);
  groupRejects_ = groups_: rejects_ (groupOverlays_ groupRoot_ groups_);
  selectedLeaves_ =
    (applyGroup_ ./selector-fixtures {
      exclude = [ "missing" ];
      export = true;
    } [ ]).legacyPackages.leaves;
  tests_ = {
    publicApi =
      builtins.attrNames helpers_ == [
        "mkHomeModule"
        "mkNixosModule"
        "mkOverlays"
      ];
    emptyGroupsCompatible =
      builtins.attrNames (groupOverlays_ implicitRoot_ { })
      == builtins.attrNames (overlays_ implicitRoot_ "overlay.nix")
      &&
        (lib.fix (
          lib.extends (lib.composeManyExtensions (
            builtins.attrValues (groupOverlays_ implicitRoot_ { })
          )) base_
        )).piPackages.tool.marker == implicit_.piPackages.tool.marker;
    groupNames =
      builtins.attrNames groups_ == [
        "custom"
        "default"
        "empty"
        "legacy"
        "off"
        "share"
      ];
    groupOrder = (grouped_ "default").sequence == "az";
    groupExclusion = (grouped_ "share").sequence == "z" && !((grouped_ "share") ? a);
    groupIsolation = (grouped_ "default").a.marker == "a" && !((grouped_ "default") ? legacyPackages);
    groupExportOff = !((grouped_ "off") ? legacyPackages);
    groupExportValues =
      (grouped_ "legacy").legacyPackages.a.marker == "a"
      && (grouped_ "legacy").legacyPackages.z.marker == "z";
    groupOnlyDeclared =
      builtins.attrNames (grouped_ "legacy").legacyPackages == [
        "a"
        "z"
      ];
    groupCustomExport =
      (grouped_ "custom").customName.z.marker == "z" && !((grouped_ "custom") ? legacyPackages);
    groupEmptyExport = (grouped_ "empty").legacyPackages == { };
    groupEmptyOverlay =
      (groupOverlays_ groupRoot_ {
        empty.exclude = [
          "a"
          "z"
        ];
      }).empty
        { }
        { } == { };
    groupAppliesOnce = (grouped_ "legacy").applications == 2;
    groupFinalValues =
      (applyGroup_ groupRoot_ { export = true; } [ (final_: prev_: { a = leaf_ "final"; }) ])
      .legacyPackages.a.marker == "final";
    groupExcludedExport =
      let
        result_ = applyGroup_ groupRoot_ {
          exclude = [ "a" ];
          export = true;
        } [ (final_: prev_: { a = leaf_ "external"; }) ];
      in
      result_.a.marker == "external" && builtins.attrNames result_.legacyPackages == [ "z" ];
    groupPreviousCollision =
      rejects_
        (lib.fix (lib.extends groups_.legacy (final_: base_ final_ // { legacyPackages = { }; })))
        .legacyPackages;
    groupCustomPreviousCollision =
      rejects_
        (lib.fix (lib.extends groups_.custom (final_: base_ final_ // { customName = 17; }))).customName;
    groupCustomIgnoresLegacyName =
      (lib.fix (lib.extends groups_.custom (final_: base_ final_ // { legacyPackages = 17; })))
      .customName.a.marker == "a";
    groupOwnCollision = rejects_ (applyGroup_ groupRoot_ { export = "a"; } [ ]).a;
    groupNamespaceCollision =
      rejects_
        (applyGroup_ implicitRoot_ { export = "texlivePackages"; } [ ]).texlivePackages;
    groupExcludedConstructorLazy =
      (applyGroup_ ./lazy-fixtures {
        exclude = [ "excluded" ];
        export = true;
      } [ ]).legacyPackages.kept.marker == "kept";
    groupSiblingConstructorLazy =
      (groupOverlays_ ./lazy-fixtures {
        safe.exclude = [ "excluded" ];
        unsafe = { };
      }).safe
        { }
        { } == {
        kept = leaf_ "kept";
      };
    groupInvalidGroups = groupRejects_ [ ];
    groupInvalidConfig = groupRejects_ { bad = false; };
    groupUnknownField = groupRejects_ { bad.include = [ "a" ]; };
    groupInvalidExclude = groupRejects_ { bad.exclude = "a"; };
    groupInvalidExcludeMember = groupRejects_ { bad.exclude = [ 1 ]; };
    groupUnknownExclude = groupRejects_ { bad.exclude = [ "absent" ]; };
    groupEmptyDirectoryExclude = rejects_ (
      groupOverlays_ ./fixtures/empty { bad.exclude = [ "emacsPackages" ]; }
    );
    groupInvalidExport = builtins.all (export_: groupRejects_ { bad.export = export_; }) [
      ""
      0
      null
      [ ]
      { }
    ];
    groupValidatesAllConfigs =
      rejects_
        (groupOverlays_ groupRoot_ {
          good = { };
          bad.export = "";
        }).good;
    groupDuplicateExclude =
      (applyGroup_ groupRoot_ {
        exclude = [
          "a"
          "a"
        ];
        export = true;
      } [ ]).legacyPackages.z.marker == "z";
    factoryDirectorySelection =
      builtins.attrNames selectedLeaves_ == [ "kept" ] && selectedLeaves_.kept.marker == "selected";
    explicitFactoryExport =
      (applyGroup_ ./fixtures/factory { export = true; } [ ])
      .legacyPackages.emacsPackages.sample.applications == 1;
    customFileExport =
      let
        customOverlay_ =
          (helpers_.mkOverlays {
            root = ./fixtures/custom;
            overlayFile = "custom.nix";
            groups.legacy.export = true;
          }).legacy;
      in
      (lib.fix (lib.extends customOverlay_ base_)).legacyPackages.texlivePackages.added.marker
      == "custom";
    publicConstructorArgument = parameterized_.piPackages.sample.marker == "public-parameter";
    emacsConstructorArgument =
      (parameterized_.emacsPackagesFor { variant = "first"; }).sample.marker == "first:public-parameter";
    emacsConstructorVariants =
      (parameterized_.emacsPackagesFor { variant = "second"; }).sample.marker
      == "second:public-parameter";
    emacsParameterizedDescendantsOnce = parameterized_.emacsPackages.sample.applications == 1;
    texConstructorArgument =
      parameterized_.texlive.withPackages (ps_: ps_.added.marker) == "public-parameter";
    texConstructorPreservesExisting =
      parameterized_.texlive.withPackages (ps_: ps_.existing.marker) == "original";
    parameterizedExtraction =
      parameterized_.legacyPackages.piPackages.sample.marker == "public-parameter";
    publicArgsNotInPackageSet = !(parameterized_ ? extraArgs) && !(parameterized_ ? marker);

    immediateChildren =
      builtins.attrNames (overlays_ implicitRoot_ "overlay.nix") == [
        "emacsPackages"
        "piPackages"
        "texlivePackages"
      ];
    emptySpecialDirectories = overlays_ ./fixtures/empty "overlay.nix" == { };
    implicitEmacs = (implicit_.emacsPackagesFor { variant = "first"; }).sample.marker == "first:sample";
    emacsVariants =
      (implicit_.emacsPackagesFor { variant = "second"; }).sample.marker == "second:sample";
    emacsDescendantsOnce = implicit_.emacsPackages.sample.applications == 1;
    implicitTexNamespace = implicit_.texlivePackages.added.applications == 1;
    implicitTexSelector = implicit_.texlive.withPackages (ps_: ps_.added.marker) == "added";
    texSameNameSelector = implicit_.texlive.withPackages (ps_: ps_.existing.marker) == "replacement";
    texDerivationIsAtomic = implicit_.texlive.withPackages (ps_: !(ps_.existing ? originalOnly));
    texNestedReplacement =
      implicit_.texlive.withPackages (ps_: ps_.nested.edited.marker) == "nested-replacement";
    texNestedSiblingPreserved =
      implicit_.texlive.withPackages (ps_: ps_.nested.kept.marker) == "nested-kept";
    texSelectedResult =
      builtins.map (p_: p_.marker) (
        implicit_.texlive.withPackages (ps_: [
          ps_.existing
          ps_.added
        ])
      ) == [
        "replacement"
        "added"
      ];
    texCombined =
      implicit_.texlive.combined.small.withPackages (ps_: ps_.existing.marker) == "replacement";
    texCombinedScalarPreserved = implicit_.texlive.combined.scalar == 7;
    texAllEnvironments = builtins.all (
      name_:
      implicit_.${name_}.withPackages (ps_: ps_.existing.marker) == "replacement"
      && implicit_.${name_}.sentinel == "preserved"
    ) environmentNames_;
    texAbsentEnvironment = !(guardedEnvironments_ ? texliveSmall);
    texNonEnvironmentPreserved = guardedEnvironments_.texliveFull == 17;
    texOtherAdditions = outside_.texlive.withPackages (ps_: ps_.externalNew.marker) == "external-added";
    texUnrelatedReplacementNotForwarded =
      outside_.texlive.withPackages (ps_: ps_.untouched.marker) == "untouched";
    ordinaryParentScope = implicit_.piPackages.tool.marker == "parent:sibling";
    existingScopePreserved = existingScope_.piPackages.kept.marker == "scope-kept";
    existingScopeDependencyRebound = existingScope_.piPackages.dependent.marker == "sibling";
    existingAttrsetPreserved = existingAttrset_.piPackages.kept.marker == "attrset-kept";
    existingAttrsetSiblingResolution = existingAttrset_.piPackages.tool.marker == "parent:sibling";
    nestedEmacsNameIsGeneric = implicit_.piPackages.emacsPackages.nested.marker == "generic-nested";
    nestedTexNameIsGeneric = implicit_.piPackages.texlivePackages.nested.marker == "generic-tex-nested";
    ordinaryExplicitEmacs =
      ordinary_.explicitEmacs && ordinary_.emacsPackages.sample.marker == "ordinary";
    ordinaryExplicitEmacsSuppressesBuiltin =
      !((ordinary_.emacsPackagesFor { variant = "other"; }) ? sample);
    ordinaryExplicitTex = ordinary_.explicitTex && ordinary_.texlivePackages.added.marker == "ordinary";
    ordinaryLocalBeforeNamespace = ordinary_.texlivePackages.added.parentMarker == "parent-local";
    ordinaryExplicitTexSuppressesBuiltin = !(ordinary_.texlive.withPackages (ps_: ps_ ? added));
    explicitEmacsFactory =
      factory_.explicitEmacsFactory && factory_.emacsPackages.sample.applications == 1;
    explicitTexFactory =
      factory_.explicitTexFactory && factory_.texlivePackages.added.applications == 1;
    explicitTexFactorySuppressesBuiltin = !(factory_.texlive.withPackages (ps_: ps_ ? added));
    customFileEmacs = (custom_.emacsPackagesFor { variant = "custom"; }).sample.marker == "custom";
    customFileTex = custom_.texlive.withPackages (ps_: ps_.added.marker) == "custom";
    customFileGeneric = custom_.piPackages.sample.marker == "custom-generic";
    extractEmacs = extracted_.emacsPackages.sample.marker == "default:sample";
    extractTex = extracted_.texlivePackages.existing.marker == "replacement";
    extractNested = extracted_.texlivePackages.nested.edited.marker == "nested-replacement";
    extractOnlyDeclaredPackages =
      builtins.attrNames extracted_.texlivePackages == [
        "added"
        "existing"
        "nested"
      ];
    extractGeneric = extracted_.piPackages.tool.marker == "parent:sibling";
    namespaceCollisionScalar = rejects_ (
      (lib.fix (
        lib.extends (lib.composeManyExtensions (
          builtins.attrValues (overlays_ implicitRoot_ "overlay.nix")
        )) (final_: (base_ final_) // { piPackages = 1; })
      )).piPackages
    );
    namespaceCollisionDerivation = rejects_ (
      (lib.fix (
        lib.extends (lib.composeManyExtensions (
          builtins.attrValues (overlays_ implicitRoot_ "overlay.nix")
        )) (final_: (base_ final_) // { piPackages = leaf_ "collision"; })
      )).piPackages
    );
    extractionMissingNamespace =
      rejects_
        (applyGroup_ ./selector-fixtures {
          exclude = [ "leaves" ];
          export = true;
        } [ ]).legacyPackages.missing;
    extractionDerivationWithDescendants =
      rejects_
        (applyGroup_ implicitRoot_ { export = true; } [
          (final_: prev_: { piPackages = leaf_ "collision"; })
        ]).legacyPackages.piPackages;
    extractionScalarNamespace = rejects_ (
      (applyGroup_ implicitRoot_ { export = true; } [ (final_: prev_: { piPackages = 17; }) ])
      .legacyPackages.piPackages
    );
    nixosModuleDiscovery =
      (lib.evalModules {
        modules = [
          (helpers_.mkNixosModule {
            root = implicitRoot_;
            modulePath = "os/default.nix";
          })
        ];
      }).config.packageAggregationNixos == 42;
    homeModuleDiscovery =
      (lib.evalModules {
        modules = [
          (helpers_.mkHomeModule {
            root = implicitRoot_;
            modulePath = "hm/default.nix";
          })
        ];
      }).config.packageAggregationHome;
  };

  realPkgs_ = pkgs.appendOverlays [
    (groupOverlays_ ./fixtures/real { legacy.export = true; }).legacy
  ];
  realSelection_ =
    ps_:
    assert ps_.latex.testMarker == "replacement";
    assert ps_.personal-nixpkgs-probe.testMarker == "added";
    [
      ps_.latex
      ps_.personal-nixpkgs-probe
    ];
  realTests_ = lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
    realEmacsScope = lib.isDerivation (realPkgs_.emacsPackagesFor pkgs.emacs).personal-nixpkgs-probe;
    realEmacsNoxScope = lib.isDerivation (realPkgs_.emacsPackagesFor pkgs.emacs-nox)
      .personal-nixpkgs-probe;
    realEmacsDifferentScopes =
      (realPkgs_.emacsPackagesFor pkgs.emacs).personal-nixpkgs-probe.drvPath
      != (realPkgs_.emacsPackagesFor pkgs.emacs-nox).personal-nixpkgs-probe.drvPath;
    realEmacsExtraction = lib.isDerivation realPkgs_.legacyPackages.emacsPackages.personal-nixpkgs-probe;
    realTexSelection = builtins.isString (realPkgs_.texlive.withPackages realSelection_).drvPath;
    realTexMinimalSelection = builtins.isString (realPkgs_.texliveMinimal.withPackages realSelection_)
      .drvPath;
  };
  results_ = tests_ // realTests_;
  failed_ = builtins.filter (name_: !(results_.${name_})) (builtins.attrNames results_);
in
if failed_ == [ ] then
  results_
else
  builtins.throw "packages tests failed: ${builtins.toJSON failed_}"
