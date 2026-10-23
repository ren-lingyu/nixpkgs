# Shared overlay aggregation and public test APIs: design review

## Status and motivation

The owner supplied a development guide for review, not implementation. Extract
the domain-neutral directory/overlay machinery from `lib.packages`, preserving
its existing behavior, and introduce parallel public `lib.tests.mkOverlays` and
`lib.tests.mkChecks` consumers. The internal aggregator is not a new public API.
After review the owner requested implementation, then split delivery: first
extract the generic layer and organize its tests into one project commit; only
after that proceed to public lib.tests. The first delivery is implemented in the
worktree, with 29 independent generic
test cases added and existing assertions retained. Scoped formatting, targeted
checks and full flake check have passed on x86_64-linux after explicit command
authorization. All extraction changes are staged, with no project commit yet.
Existing committed aggregation functionality and its validation remain
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

## Review findings and adopted extraction contract

The extraction is feasible with the current top-level dispatch design; ordinary
implicit values can close over domain-specific context without extending the
internal API. New defaults should remain lazy so absent/explicit special trees
do not unnecessarily evaluate TeX selection.

The owner adopted the following independent mkChecks contract, intentionally
close to mkLegacyPackages. This resolves an API ambiguity, not a request for
additional features. Directory structure determines traversal; scope supplies
only values at those paths. Never enumerate scope to discover extra checks.

| Discovered directory condition | mkChecks behavior |
| --- | --- |
| Overlay leaf with a derivation value | Extract the derivation. |
| Overlay leaf with a non-derivation value | Skip. |
| Overlay leaf with a missing corresponding path | Skip. |
| Ordinary attrset leaf without descendant overlays | Skip; do not enumerate its attributes. |
| Descendant overlays exist and corresponding value is a non-derivation attrset | Continue along the discovered directory tree. |
| Descendant overlays exist but corresponding path is missing | Error. |
| Descendant overlays exist but corresponding value is a derivation or other non-attrset value | Error. |

Derivations are atomic leaves even though represented as Nix attrsets. Apply
namespace validation to directories with discovered descendants before deciding
whether any value is an extractable leaf. Directory paths remain the basis for
flattened check names; scope management members and unrelated derivations are
not discovered through arbitrary attribute traversal.

The owner also adopted the factory path constraint: a factory owns descendant
overlay application, but supplies no path-remapping information to mkChecks.
If it relocates results, the caller must arrange their export; mkChecks cannot
recover the directory correspondence automatically. No mapping protocol is added.

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

The extraction contract and factory path constraint are now settled. Future
implementation must follow the table above, and treat the guide's own-suite
migration references (section 8.4, phase four and completion criterion 7) as
deferred work. The owner authorized implementing the plan, then narrowed the
current delivery
to generic-layer extraction and its tests. No public lib.tests API or own-suite
migration belongs in this first commit. Execution commands still require scoped
authorization under project policy.

## First delivery outcome: generic extraction

The generic implementation now lives at `lib/overlays/default.nix`; it exports
mkOverlays and directory helpers internally. `lib/default.nix` injects it into
the package consumer, which retains the exact extraction/module algorithms and
supplies its implicit rules through ordinary closures. The generic layer has
no domain names. Namespace diagnostics now use `overlays.mkOverlay` instead of
the former package prefix; failure conditions remain unchanged.

`tests/overlays.nix` takes `{ lib, overlayTree }` and uses dedicated downward
fixtures for generic ordinary/implicit/factory rules, existing scopes and
attrsets, dependency resolution, discovery boundaries, custom filenames and
invalid namespace collisions. The 29 cases pass alongside all original 54
package and 43 merge cases (126 total). Root flake assembly injects the internal
module into tests explicitly; existing suites were not migrated to lib.tests.
README reflects this test wiring. Targeted overlays/package check builds and
full flake check, including treefmt, passed on x86_64-linux. Other systems and
runtime ecosystem builds were not tested. No lockfile or reference repo changed.

The staged, validated extraction is the intended first project commit. Do not
attribute these tests to current committed HEAD or attach that baseline as a
new provenance parent for uncommitted implementation. After owner review/commit,
the next delivery is public lib.tests following the settled contract above.
