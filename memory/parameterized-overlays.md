# Parameterized overlay construction: proposal review

## Status and scope

The owner requested review, not implementation, of a guide based on the current
committed checks-only API baseline. Source inspection confirmed that baseline
and a clean project worktree. Earlier GAW history already associates the source;
this planning checkpoint introduces no additional project parent. No project
files were changed or validation commands run for this review.

The proposed bounded extension adds packages.mkOverlays.extraArgs, default {},
and the same optional parameter to internal overlayTree.mkOverlays. Keep
mkLegacyPackages extraction-only, package outputs unchanged, and tests.mkChecks
unchanged in signature and args semantics. Consumer repositories are not to be
modified. The older package-consumption redesign remains deferred.

## Proposed contract

Overlay definitions may be ordinary final: prev functions, constructors taking
{ extraArgs }, existing { descendantOverlay } factories, or constructors taking
both names in one outer attrset. Only descendantOverlay owns descendant
application. Inject only explicitly declared constructor keys, preserving strict
attrset-pattern compatibility. Extra arguments remain in lexical closures;
never merge them into final/prev/pkgs or callPackage environments automatically.
Use the same extraArgs lazily at all recursion levels, including factory-owned
and implicit Emacs descendants. Preserve generic scope algorithms, overlay
ordering, explicit rule precedence, TeX selection and root/empty discovery.

## Review findings, not yet owner-adopted changes

The extension fits the existing instantiateOverlay_/loadOverlay_/mkOverlay_
structure and can reuse its ownership check. Complete propagation is necessary
through both top-level dispatch and recursive namespace/factory paths.

The main wording conflict is in the tests boundary. Once the shared aggregator
recognizes { extraArgs } with a default empty environment, unchanged mkChecks
inherits that recognition, with extraArgs = {}. It cannot also guarantee that
parameterized test overlays remain unrecognized. Recommend describing the
boundary as no new public tests parameter and no automatic mapping from args,
while retaining existing behavior. Do not introduce a mode flag solely to
force rejection unless the owner expressly requires that restriction.

Constructor names should be documented as reserved in the outer attrset
pattern. A standard overlay destructuring final with a field named extraArgs
would now be interpreted as a constructor; compatibility is therefore scoped
to ordinary positional overlays and the established descendantOverlay protocol,
not every hypothetical attrset-pattern final argument. Apply declared optional
constructor fields as well as required ones; field presence determines injection,
not whether its functionArgs boolean marks a default.

The guide says extraArgs applies only to directory-loaded definitions, while
existing instantiateOverlay_ is also used for implicitOverlays values. Current
built-ins do not request extraArgs, so compatibility is not blocked. Clarify
whether the shared constructor protocol may apply to implicit definitions too;
avoid accidentally promising different rules without an implementation reason.

Useful focused tests beyond the supplied matrix: strict constructor patterns
receive no undeclared key; omitted extraArgs supplies {}; unused extraArgs and
unused members may throw without being forced; constructor defaults do not
suppress explicit injection; simultaneous extraArgs/descendantOverlay works at
nested levels; public packages wrapper really forwards the environment; and
extraArgs never leaks into pkgs or callPackage through the aggregator. Existing
Emacs/TeX and 184-case baseline checks remain regression evidence, not proof
that the proposed unimplemented behavior works.

Next: clarify the tests wording and constructor contracts, then await owner
instruction. Review does not authorize implementation, staging or Nix commands.
