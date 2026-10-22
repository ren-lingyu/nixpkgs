# Backlog

## Package aggregation and package-set integration tests

Status: planned; feasibility assessed, implementation and execution pending.
The owner requested preserving this plan before returning to the work.

### Goal and boundaries

Verify that `lib.packages` aggregation works with representative Nixpkgs
package-set mechanisms. Start with `mkOverlays` and `mkLegacyPackages`, with
companion module-discovery cases for `mkNixosModule` and `mkHomeModule`.
Package existence alone is insufficient: tests must establish that dependency
resolution and final environments actually use the extended package set.

Use the practices in `~/nixos/pkgs` and `~/emarccs` as design evidence, not as
runtime filesystem dependencies. Keep fixtures and test packages inside this
repository and use its locked Nixpkgs. Test overlays remain internal; do not
export them through the flake's `overlays` output. Fixture packages can be
referenced by checks without becoming public package outputs. Whether any
real package should later become a public output is a separate decision.

Tests receive `llib`. Add `lib` or `pkgs` only where used. All dependencies
across parent-directory boundaries must be passed as function parameters;
parent-relative imports and equivalent ancestor traversal are forbidden.
A caller can load library and tests downward and inject the required values.

### Coverage matrix

- Top-level packages: overlay application and package-tree extraction agree.
- New scopes and nested namespaces, inspired by `piPackages`: sibling packages
  resolve each other through the intended `callPackage`, including multiple
  namespace levels and dependencies supplied by the parent scope.
- Existing scopes with `overrideScope`: replacing a dependency changes the
  dependent package, while unrelated packages remain available.
- Ordinary attribute sets: preserve existing entries and verify local scope
  binding. Specifically investigate whether an inherited `callPackage` shadows
  the new scope's caller, and distinguish newly defined dependents from already
  instantiated derivations that are not automatically rebound.
- Emacs: use the `emacsPackagesFor` factory pattern from emarccs; check generated
  scopes for selected Emacs variants and load a minimal package in the resulting
  environment. Do not require building the full personal configuration.
- TeX Live: use the custom-package and environment pattern from nixos/pkgs;
  verify package visibility through the intended environment interface and
  compile a minimal document that consumes it.
- Python: exercise a native extension/factory path and verify that the matching
  interpreter environment imports the added package and its intended dependency.
- Haskell: exercise its native override interface, preserving existing overrides,
  and verify a small consumer. Compiler cost may justify an optional heavier tier.

Cover mechanisms rather than claiming every named Nixpkgs package set has the
same interface. Python, Haskell and environment builders may require explicit
factory adapters; generic namespace merging alone is not proven sufficient.
Select concrete representatives against the locked Nixpkgs during implementation.

### Validation layers

1. Evaluation cases for discovery, namespace shape, overlay ordering, factory
   ownership of `descendantOverlay`, and package-tree extraction. Force only
   the relevant results rather than traversing all of Nixpkgs.
2. Small local builds with a producer and consumer whose output proves which
   dependency was selected. Include dependency replacement, not only additions.
3. Selected real ecosystem smoke tests: Emacs loading, Python import, a small
   Haskell consumer and TeX compilation. Keep heavy application builds outside
   the default fast tier.

Include expected failures for namespace collisions with derivations or scalar
values, missing selected namespace paths, descendant overlays under a selected
derivation, and module files with nested module entries. Cover empty discovery
results, multi-input overlay composition and factory descendants applied once.

### Sequence and acceptance

Start with evaluation cases and small generic builds on `x86_64-linux`, then
add Emacs and TeX Live examples and broaden to Python/Haskell and other platforms.
Determine the fast/default and heavy/optional tiers before adding expensive
checks. Flake check integration, new dependencies, downloads and execution need
their own implementation scope and command authorization.

The plan is satisfied when selected mechanisms have explicit behavioral tests,
negative cases fail as intended, successful consumers use the extended
packages, and all overlays remain internal. Record any unsupported mechanisms
and platform limits rather than asserting universal package-set compatibility.
No implementation or validation of this backlog item has been performed.
