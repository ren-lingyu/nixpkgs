# Overlay constructors: adopted design revision

## Status and scope

The owner replaced the earlier mixed two-/three-layer input proposal with a
uniform constructor protocol. This revision supersedes all four earlier review
recommendations and the mixed-format compatibility plan. Original guidance
remains applicable only where not overridden. The decision is adopted, not
implemented: project source remains at the clean committed checks-only baseline.
No Nix validation or project-file mutation occurred in this decision turn.
Earlier GAW history already associates that baseline; this planning checkpoint
has no additional project parent.

The bounded change extends packages.mkOverlays with extraArgs ? {} and internal
overlayTree.mkOverlays with the same default. Keep mkLegacyPackages extraction,
namespace algorithms, business package rules and mkChecks.args scope semantics
unchanged. The older redesign of package consumption/output ownership remains
deferred; this constructor change is an explicitly adopted additive capability
plus an incompatible source-protocol migration, not that redesign.

## Uniform constructor protocol

Every definition loaded or instantiated by overlayTree, including explicit
files and implicitOverlays values, is a constructor returning a standard overlay:

```
{ /* declared constructor arguments */ }: final: prev: { ... }
```

Use { }: for definitions with no construction needs. Only extraArgs and
descendantOverlay are allowed explicit names in the first-layer pattern;
reject unknown names, including when mixed with a supported name. Inspect
builtins.functionArgs and pass only the declared supported keys in one call.
Optional declarations such as extraArgs ? {} still receive the supplied
value: parameter presence, not its default marker, determines injection.
Only declaring descendantOverlay transfers ownership of descendant application.
Declaring extraArgs alone leaves automatic namespace aggregation in place.

The second/third function layers retain ordinary Nix overlay syntax, including
attribute-set destructuring of final. Do not inspect their parameter names as
constructor declarations. The source format is intentionally incompatible with
old two-argument definitions; do not add compatibility detection or mode flags.
The public mkOverlays return values remain standard final: prev overlay functions.

{ ... }: is accepted, while { }: is preferred for no-argument constructors.
functionArgs cannot distinguish empty/open attrset patterns from positional
lambda arguments; do not pretend to statically enforce the first pattern shape
or implement arity inference. Always apply the first function as a constructor.
Malformed old-style inputs may fail only on instantiation/application. Type
checks may validate returned function and eventual non-derivation attrset, but
full static detection of every malformed function shape is not promised.

## Propagation, isolation and laziness

Carry the same extraArgs through mkOverlays_, mkOverlay_, loadOverlay_,
instantiateOverlay_, namespace descendants and factory-owned descendants.
Parameters remain lexical closure dependencies. Do not merge them into final,
prev, pkgs or callPackage automatically; overlays explicitly forward values to
package functions when needed. Unknown constructor fields are not an invitation
to inject arbitrary named args from the extraArgs namespace.

Do not force extraArgs if undeclared or unused, nor force unread members.
An unused extraArgs = throw value must remain safe. Strict attrset patterns
must never receive undeclared constructor keys. Recursive scope/newScope and
ordinary local-before-namespace composition, explicit rule precedence and empty
or root discovery behavior remain unchanged.

Implicit definitions use exactly the same instantiation rules as directory
files. Existing Emacs { descendantOverlay }: factory stays intact. Adapt the
ordinary TeX rule with an empty constructor at registration or definition,
preserving its directory-capturing selectPackages closure and business logic.

## Consumer and fixture migration

Migrate test-overlay.nix suite entries and every actually loaded fixture overlay,
including custom discovery filenames (custom.nix/check.nix), not just files named
overlay.nix. Update inline implicitOverlays definitions used by generic tests.
Keep direct standard overlays passed to composeManyExtensions/appendOverlays
outside overlayTree as standard overlays; they are not constructor inputs.
Ignored/throwing fixtures should retain their intended discovery assertions.

mkChecks keeps its public signature and supplies no extraArgs; the shared
aggregator uses default {}. Do not map mkChecks.args to constructor extraArgs.
Test source definitions now use constructors too, without changing test scope,
callPackage, extraction or test business logic. No package/test protocol switch.
External consumer repositories are outside this migration.

## Verification and implementation scope

Test all four supported constructor patterns, defaulted parameters, unknown
names alone and with supported names, empty/open first patterns, destructured
final, strict-pattern selective injection, default-empty environment and both
whole-environment/member laziness. Exercise recursive namespaces, explicit
factories and implicit Emacs descendants, TeX behavior, and unchanged mkChecks
args semantics. Cover the public packages.mkOverlays forwarding path in addition
to internal tests. Verify constructed values are functions and their applied
results are the intended non-derivation attrsets. No large software builds needed.

The stated modification scope includes overlay-tree.nix, the package adapter,
necessary test adapter changes, minimal internal rule wrapping, related source
and fixture constructors, and README.org. Do not change mkLegacyPackages,
namespace/scope algorithms or concrete package build logic. Update README for
the new source contract, extraArgs and its distinction from mkChecks.args.

Next: implement this adopted revision when implementation is requested, then
obtain command authorization for its exact staging/formatting/validation scope.
Prior checks (184 named cases on x86_64-linux) validate the old source snapshot,
not this unimplemented protocol. No project code or test results are claimed
for the new design yet.
