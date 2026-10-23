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
  extracted_ = helpers_.mkLegacyPackages {
    root = implicitRoot_;
    overlayFile = "overlay.nix";
    pkgs = implicit_;
  };
  rejects_ = value_: !(builtins.tryEval (builtins.seq value_ true)).success;

  tests_ = {
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
        (helpers_.mkLegacyPackages {
          root = implicitRoot_;
          overlayFile = "overlay.nix";
          pkgs = { };
        }).piPackages;
    extractionDerivationWithDescendants =
      rejects_
        (helpers_.mkLegacyPackages {
          root = implicitRoot_;
          overlayFile = "overlay.nix";
          pkgs = {
            piPackages = leaf_ "collision";
          };
        }).piPackages;
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

  realPkgs_ = pkgs.appendOverlays (builtins.attrValues (overlays_ ./fixtures/real "overlay.nix"));
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
    realEmacsExtraction =
      lib.isDerivation
        (helpers_.mkLegacyPackages {
          root = ./fixtures/real;
          overlayFile = "overlay.nix";
          pkgs = realPkgs_;
        }).emacsPackages.personal-nixpkgs-probe;
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
