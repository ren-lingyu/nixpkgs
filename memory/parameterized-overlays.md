# Overlay constructors: adopted design revision

## Status and scope

The owner replaced the earlier mixed two-/three-layer input proposal with a
uniform constructor protocol. This revision supersedes all four earlier review
recommendations and the mixed-format compatibility plan. Original guidance
remains applicable only where not overridden. The owner requested implementation
and authorized the exact staging, scoped
formatting and full-check commands for this task. The constructor mechanism,
package forwarding, source migration, README and focused tests are implemented,
validated and committed by the owner as
`feat(lib): add parameterized overlay constructors`. The entire committed tree
matches the reviewed index snapshot: all 117 file blobs and modes agree. The
project worktree was clean on inspection. This checkpoint associates that
inspected commit. Tests ran before commit against the same content, not again
for grounding. Earlier GAW history associates the preceding baseline.

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
Malformed old-style inputs may fail only on instantiation/application. The owner
selected tests-only return-type validation during planning: do not
add runtime return-shape wrappers or arity inference. Tests verify resulting
functions and non-derivation attribute sets; malformed values use native Nix
errors. Runtime validation is limited to allowed constructor argument names.

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

Implementation uses optionalAttrs to build only declared constructor keys and
threads extraArgs through the existing recursion. TeX is wrapped at registration.
Ordinary fixture/source migration adds only an empty constructor; existing
factories and ignored throwing fixtures retain their roles. Added local fixture
trees exercise the new protocol and package adapter without parent traversal.

## Implementation outcome and verification

All 49 modified pre-existing source/fixture overlay files are byte-identical to
baseline after accounting for the added empty constructor prefix. Existing
factories and intentionally ignored throwing files remain intact. TeX was
wrapped at registration; rules business implementations, lib/tests.nix,
mkLegacyPackages and module extraction algorithms were not changed.

Nineteen new local fixture files and focused cases cover selective constructor
injection, defaulted and open patterns, nested factory-owned scope propagation,
unknown arguments alone/mixed, function/path values, whole-environment/member
laziness, explicit callPackage forwarding and absence of package-set pollution.
Public package adapter tests cover generic, Emacs variants and TeX selection,
plus extraction of the parameterized results. API tests prove default-empty
constructor environment and separation from scope args, even if args contains
an extraArgs-named member. No parent-directory imports were introduced.

The first full check exposed infinite recursion in the new final-destructuring
fixture because attrset argument matching strictly forces final during its own
fixed-point construction. The fixture was corrected to apply that standard
overlay to a concrete final attrset; fixed-point tests exclude that one entry.
This preserves ordinary Nix strictness instead of adding a special runtime
wrapper. README and the case comment explain the limitation. It is not evidence
that destructured final always works inside a recursive package fixed point.

After that test correction, scoped nix fmt and
`timeout 120s nix flake check --no-write-lock-file --show-trace` passed on
x86_64-linux: 217 named cases (43 merge, 62 packages, 51 generic overlays,
61 tests API), three real extracted writeText checks and treefmt. This adds
33 cases to the prior baseline; package tests still include six real Emacs/TeX
evaluations. Other systems were skipped. No large ecosystem build or lockfile
update occurred. The merge report and three real check drvPaths are unchanged;
overlay/package/API report paths changed with their added assertions.

Final read-only review confirmed the 49 mechanical migrations, no unstaged
project changes, diff-check cleanliness and unchanged extraction/scope business
algorithms. The owner committed all 74 changed paths. The exact 117-file
committed-tree comparison confirms that the reviewed and validated source
content is the committed content. This checkpoint associates the inspected
commit; no post-commit test rerun is claimed. This implementation is complete.
Next: await the owner's next objective.
External consumer repositories remain unmodified and will require a separate
migration of their loaded two-argument source overlays.
