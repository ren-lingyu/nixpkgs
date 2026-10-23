{ llib }:
let
  inherit (llib) mergeAttrsRecursive;

  merge_ = mergeAttrsRecursive { };
  override_ = mergeAttrsRecursive { allowOverrides = true; };
  rejects_ = sets_: !(builtins.tryEval (builtins.seq (merge_ sets_) true)).success;

  # A derivation-shaped leaf with deliberately unevaluable internals.
  derivationLeaf_ = {
    type = "derivation";
    outPath = throw "derivation internals must stay lazy";
  };

  tests_ = {
    empty = merge_ [ ] == { };
    emptyNamespaces =
      merge_ [
        { a = { }; }
        { a = { }; }
      ] == {
        a = { };
      };
    recursive =
      merge_ [
        { tools.editor = "emacs"; }
        { tools.search = "ripgrep"; }
        { tools.nested.a = 1; }
        { tools.nested.b = 2; }
      ] == {
        tools = {
          editor = "emacs";
          search = "ripgrep";
          nested = {
            a = 1;
            b = 2;
          };
        };
      };

    equalLeavesConflict = rejects_ [
      { a = 1; }
      { a = 1; }
    ];
    differentLeavesConflict = rejects_ [
      { a = 1; }
      { a = 2; }
    ];
    nullLeavesConflict = rejects_ [
      { a = null; }
      { a = null; }
    ];
    listsConflict = rejects_ [
      { a = [ 1 ]; }
      { a = [ 2 ]; }
    ];
    functionsConflict = rejects_ [
      { a = x_: x_; }
      { a = x_: x_; }
    ];
    leafAndSetConflict = rejects_ [
      { a = 1; }
      { a.b = 2; }
    ];
    setAndLeafConflict = rejects_ [
      { a.b = 2; }
      { a = 1; }
    ];
    emptySetAndLeafConflict = rejects_ [
      { a = { }; }
      { a = 1; }
    ];
    eagerNestedConflict = rejects_ [
      { a.b.c = 1; }
      { a.b.c = 2; }
    ];
    laterConflict = rejects_ [
      { a = 1; }
      { b = 2; }
      { a = 3; }
    ];
    derivationsAreLeaves = rejects_ [
      { a = derivationLeaf_; }
      { a = derivationLeaf_; }
    ];
    derivationAndSetConflict = rejects_ [
      { a = derivationLeaf_; }
      { a.extra = 1; }
    ];

    lazyUniqueLeaf =
      (merge_ [
        { a = throw "unique leaf forced"; }
        { b = 2; }
      ]).b == 2;
    lazyNestedLeaf =
      (merge_ [
        { a.x = throw "nested unique leaf forced"; }
        { a.y = 2; }
      ]).a.y == 2;
    lazyDerivation =
      (merge_ [
        { a = derivationLeaf_; }
        { b = 2; }
      ]).a.type == "derivation";
    preserveFunction = (merge_ [ { a = x_: x_ + 1; } ]).a 2 == 3;
    preserveList =
      (merge_ [
        {
          a = [
            1
            2
          ];
        }
      ]).a == [
        1
        2
      ];
    mergeFunctionLibraries =
      let
        merged_ = merge_ [
          { helpers.increment = x_: x_ + 1; }
          { helpers.double = x_: x_ * 2; }
        ];
      in
      merged_.helpers.increment 2 == 3 && merged_.helpers.double 2 == 4;
    specialAttributeName =
      merge_ [
        { "a.b".x = 1; }
        { "a.b".y = 2; }
      ] == {
        "a.b" = {
          x = 1;
          y = 2;
        };
      };

    nonListRejected = rejects_ { a = 1; };
    nonSetRejected = rejects_ [
      { a = 1; }
      2
    ];
    derivationRootRejected = rejects_ [ derivationLeaf_ ];
    invalidOption =
      !(builtins.tryEval (builtins.seq (mergeAttrsRecursive { allowOverrides = 1; } [ ]) true)).success;
    explicitStrict =
      !(builtins.tryEval (
        builtins.seq (mergeAttrsRecursive { allowOverrides = false; } [
          { a = 1; }
          { a = 1; }
        ]) true
      )).success;

    overrideEmpty = override_ [ ] == { };
    overrideLaterWins =
      override_ [
        { a = 1; }
        { a = 2; }
      ] == {
        a = 2;
      };
    overrideThreeInputs =
      override_ [
        { a = 1; }
        { a = 2; }
        { a = 3; }
      ] == {
        a = 3;
      };
    overrideRecursive =
      override_ [
        {
          a = 1;
          nested.x = 1;
        }
        {
          a = 2;
          nested.y = 2;
        }
      ] == {
        a = 2;
        nested = {
          x = 1;
          y = 2;
        };
      };
    overrideSetOverLeaf =
      override_ [
        { a = 2; }
        { a.x = 1; }
      ] == {
        a.x = 1;
      };
    overrideLeafOverSet =
      override_ [
        { a.x = 2; }
        { a = 1; }
      ] == {
        a = 1;
      };
    overrideSubtreeBarrier =
      override_ [
        { a.x = 1; }
        { a = 2; }
        { a.y = 3; }
      ] == {
        a.y = 3;
      };
    overrideMergeAfterBarrier =
      override_ [
        { a = 3; }
        { a.x = 1; }
        { a.y = 2; }
      ] == {
        a = {
          x = 1;
          y = 2;
        };
      };
    overrideLeafReplacesSets =
      override_ [
        { a.x = 1; }
        { a.y = 2; }
        { a = 3; }
      ] == {
        a = 3;
      };
    overrideEmptySetReplacesLeaf =
      override_ [
        { a = 1; }
        { a = { }; }
      ] == {
        a = { };
      };
    overrideFunction =
      (override_ [
        { a = x_: x_ + 1; }
        { a = x_: x_ + 2; }
      ]).a
        2 == 4;
    overrideList =
      (override_ [
        { a = [ 1 ]; }
        {
          a = [
            2
            3
          ];
        }
      ]).a == [
        2
        3
      ];
    overrideDerivation =
      (override_ [
        { a.extra = 1; }
        { a = derivationLeaf_; }
      ]).a.type == "derivation";
    overrideSetOverDerivation =
      override_ [
        { a = derivationLeaf_; }
        { a.extra = 1; }
      ] == {
        a.extra = 1;
      };
    overrideLazyLoser =
      (override_ [
        { a = throw "loser forced"; }
        { a = 1; }
      ]).a == 1;
    overrideLazySubtree =
      (override_ [
        { a.x = throw "discarded subtree forced"; }
        { a = 1; }
      ]).a == 1;
  };

  failed_ = builtins.filter (name_: !(tests_.${name_})) (builtins.attrNames tests_);
in
if failed_ == [ ] then
  tests_
else
  builtins.throw "mergeAttrsRecursive tests failed: ${builtins.toJSON failed_}"
