# Shared overlay aggregation and public test APIs: design review

## Status and motivation

The owner supplied a development guide for review, not implementation. Extract
the domain-neutral directory/overlay machinery from `lib.packages`, preserving
its existing behavior, and introduce parallel public `lib.tests.mkOverlays` and
`lib.tests.mkChecks` consumers. The internal aggregator is not a new public API.
No implementation, project file edits or test execution were requested in this
review. Existing committed aggregation functionality and its validation remain
as described in `memory/package-aggregation-rules.md`.

The owner subsequently deferred migrating this repository's own test suites to
the new APIs. That migration is not an acceptance condition or implementation
phase of the initial feature. Keep existing checks executable; use independent
fixtures to demonstrate the new scope/dependency and derivation extraction APIs.

## Proposed architecture from the supplied guide

- Root `lib/default.nix` imports the internal aggregator and injects it into
  `lib.packages` and `lib.tests`; no cross-parent-directory imports.
- Internal `mkOverlays { root, overlayFile, implicitOverlays ? {}; }` returns
  one overlay per discovered immediate child, without applying overlays or
  constructing the final scope. No hardcoded package/test directory roles.
- Implicit ordinary overlays or descendantOverlay factories apply only to
  immediate children with descendants and no explicit overlayFile. Preserve
  ordinary local-before-namespace composition, factory ownership, empty/root
  exclusion, new scopes, existing overrideScope and ordinary attrset behavior.
- Packages supplies its current Emacs/TeX implicit rules. TeX's selector closure
  must capture the selected child under the caller's root and overlayFile;
  preserve declared replacement boundaries, nested siblings and atomic derivations.
- Public tests.mkOverlays uses the same mechanism without package defaults.
- Proposed tests.mkChecks { root, overlayFile, scope, separator ? "/"; }
  selects derivations by discovered directory paths and flattens their names.
  Scope is caller-built and may contain arbitrary helpers and values.
  Custom-separator collisions are explicitly caller responsibility; no registry
  or helper derivation marker/exclusion protocol is requested.
- Keep package extraction and module API/algorithms stable. Do not force shared
  extraction if it changes behavior. Keep downstream reference repos read only.

## Review findings and unresolved contract

The extraction is feasible with the current top-level dispatch design; ordinary
implicit values can close over domain-specific context without extending the
internal API. New defaults should remain lazy so absent/explicit special trees
do not unnecessarily evaluate TeX selection.

Before implementing mkChecks, define how each discovered directory behaves when
its corresponding scope value is missing, non-derivation, or an attrset without
discovered descendants. Also define a derivation encountered above discovered
descendants. The guide permits helper values but leaves these cases ambiguous.
Current mkLegacyPackages skips an overlay-only leaf whose value is missing or
not a derivation, while requiring namespace structure for discovered descendants.
Reusing it mechanically would silently adopt those choices. No new choice was
adopted by this review. Do not recursively enumerate arbitrary scope attributes:
management members and derivations unrelated to discovered paths must not leak.
Factories may reshape their results, but extraction follows actual directory
paths; it cannot infer a remapping from overlay source code.

For later own-suite migration, current tests/fixtures contains many overlay.nix
files. Scanning tests/ using that filename would aggregate fixtures under test.
Choose a distinct discovery filename or bounded source layout at the consumer,
without hardcoded exclusions. This is deferred with the migration itself.

## Validation and next action

Initial acceptance should preserve all existing package assertions and checks,
add domain-neutral aggregation and lib.tests cases, and include at least one
real writeText/runCommand derivation. Cover non-derivation helper leaves,
missing/incompatible paths, directory-bounded flattening, separator behavior,
factory ownership, cross-directory scope dependencies and unaffected package
rules. No runtime framework, global overlay ordering policy or all-derivation
scope restriction is needed.

Next: settle the extraction contract and revise the guide's own-suite migration
references (section 8.4, phase four and completion criterion 7) to deferred work.
Implementation and its command authorization remain a subsequent task.
