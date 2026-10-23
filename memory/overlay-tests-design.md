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
authorization. The owner committed that delivery as
`refactor(lib): extract generic overlay tree aggregation`; its committed diff
matches the reviewed candidate. Public lib.tests has subsequently been completed
and committed as well (see the second delivery outcome below). The owner later
approved migrating ordinary suites while retaining direct API acceptance; that
migration is now validated and committed (see the final section).
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
first delivery to generic-layer extraction and its tests. That delivery is now
committed, as is the subsequent public lib.tests delivery. Own-suite migration
was deferred during those deliveries and is now complete in a subsequent owner
commit. Execution commands still require scoped authorization under project policy.

## First delivery outcome: generic extraction

The generic implementation now lives at `lib/overlay-tree.nix`; it exports
mkOverlays and directory helpers internally. `lib/default.nix` injects it into
the package consumer, which retains the exact extraction/module algorithms and
supplies its implicit rules through ordinary closures. The generic layer has
no domain names. Namespace diagnostics now use `overlays.mkOverlay` instead of
the former package prefix; failure conditions remain unchanged.

`tests/suites/overlays/cases.nix` takes `{ lib, overlayTree }` and uses dedicated downward
fixtures for generic ordinary/implicit/factory rules, existing scopes and
attrsets, dependency resolution, discovery boundaries, custom filenames and
invalid namespace collisions. The 29 cases pass alongside all original 54
package and 43 merge cases (126 total). Root flake assembly injects the internal
module into tests explicitly; existing suites were not migrated to lib.tests.
README reflects this test wiring. Targeted overlays/package check builds and
full flake check, including treefmt, passed on x86_64-linux. Other systems and
runtime ecosystem builds were not tested. No lockfile or reference repo changed.

The owner committed the validated extraction. Inspection confirms the committed
diff matches the reviewed candidate; an earlier grounding checkpoint associates
that source snapshot. Checks ran before commit, not after it. The next delivery, now requested
by the owner, is public lib.tests following the settled contract above.

The owner prefers a flat module file while the generic implementation is a
single file. It was moved from lib/overlays/default.nix to lib/overlay-tree.nix,
matching existing kebab-case filenames, and both imports were updated. This
path-only adjustment is committed and the full authorized flake check passed again
after the move, including all 126 cases and formatting on x86_64-linux. It does
not change implementation content or add a public API.

## Second delivery outcome: public lib.tests

The module now lives at lib/tests.nix and is injected with lib and overlayTree
by the root library. The owner initially requested lib/tests/default.nix to
mirror packages, then corrected that choice: packages needs a directory for its
additional rule files, whereas this single-file module should remain flat.
The owner committed the byte-identical move and root import update as
`refactor(lib): flatten tests module into a single file`. The inspected commit
changes only these two paths; the project worktree was clean. This checkpoint
associates that source inspection, without claiming a new test run. It exposes exactly mkOverlays and
mkChecks. The former delegates without package defaults; the latter follows the
independent extraction table above, flattening only discovered directory paths.
Namespace errors identify paths as JSON arrays. Extraction reads filesystem
structure but never imports overlay definitions. No generic-layer or package
algorithm change was needed.

`tests/test-api.nix` adds 47 named evaluation cases using dedicated fixtures:
caller-owned scopes, shared and nested callPackage dependencies, dependency
replacement with changed derivation paths, generic handling of package-like
directory names, default/custom/empty separators, all leaf/namespace extraction
branches, root/empty discovery, laziness outside selected paths, management
member exclusion, helper-named derivation inclusion, custom filenames, factory
ownership and relocation failures. Throwing overlay fixtures prove extraction
does not load definitions. Scope helpers have no reserved directory role.

`tests/test-checks.nix` constructs an independent scope, extracts real writeText
derivations, and prefixes their names for flake integration. Three checks are
built directly: testApi/checks/alpha, testApi/checks/nested/beta and
testApi/validators. This consumer validates the new API without migrating the
original boolean suites. The testApi suite is added through their existing JSON
report mechanism. All cross-parent dependencies remain parameter-injected.

Scoped nix fmt, targeted API/real-check nix build and full nix flake check with
--no-write-lock-file --show-trace passed on x86_64-linux. All 173 evaluation cases
(43 merge, 54 packages, 29 generic overlays, 47 API), three real extracted checks
and treefmt passed. Existing report derivations are unchanged; other platforms
were skipped. No lockfile update, downstream reference changes or large ecosystem
builds occurred. README documents public APIs, caller scope assembly, discovery
boundaries, the extraction contract, separators and factory path limitations.

The owner committed the feature as
`feat(lib): add test overlay aggregation and check extraction`. The agent polled
HEAD after preparing the message, then compared the complete committed tree's
blob IDs and modes to the reviewed index snapshot: all 90 files match exactly.
The project worktree was clean then. An earlier checkpoint associates the
inspected feature commit. Agent checks and the owner's independent nix flake check passed before
commit against that content; no claim is made that checks were rerun after commit.
Both API deliveries are complete. Own-suite migration is covered below.

## Repository suite migration: completed and committed

The owner selected per-suite source/fixture consolidation and requested the
migration plan be implemented. tests/suites contains mergeAttrsRecursive,
overlays and packages. Each directory has raw cases.nix and test-overlay.nix;
overlay/package fixture trees moved beneath their corresponding suite. The root
uses test-overlay.nix to avoid collecting fixture overlay.nix files. The old
merge expression path remains a one-line downward import for standalone use.

The root entry returns checks directly, constructing a makeScope/overrideScope
scope with lib, pkgs, llib, overlayTree and local mkResultCheck. Per-suite
callPackage report wrappers evaluate cases via same-directory import and turn
results into the original named writeText JSON report. Flake checks simply
imports this entry. testApi and its three real checks remain directly loaded.
An independent root guard requires exactly the three ordinary suite names;
adding a suite requires updating that expectation intentionally.

Two implementation findings affect correct future use:

- callPackage adds makeOverridable metadata to attrset results, including override
  functions, which prevents JSON serialization and can overwrite a same-named
  assertion such as merge's overrideDerivation case. Apply callPackage to the
  report constructor returning a derivation; import raw cases with wrapper
  arguments directly. Do not strip metadata from raw results and lose assertions.
- makeScope reserves its packages member for the definition function. A packages
  suite is therefore masked in the managed scope object. The root passes
  scope.packages scope (the applied definitions) to mkChecks, preserving the
  suite name without altering public APIs or the scope implementation. This was
  confirmed against the locked Nixpkgs before applying the adaptation.

All 173 original assertions and the three real checks pass, with no new permanent
assertion cases. Scoped formatting, the four report builds, standalone merge
readonly evaluation and full flake check passed on x86_64-linux; other systems
were skipped. Comparison with the committed public API baseline confirms all
seven test check names and drvPaths unchanged (treefmt changes with source layout).
A temporary injected-entry verifier confirms normal assembly and root rejection
of empty, missing-package and extra-check collections. It accepts testEntry,
previousChecks, llib, lib, pkgs and overlayTree by parameter, using a pinned
baseline flake for comparison; no tracked implementation is mutated for negatives.

The 44 moved fixture files are byte-identical. Case expressions differ only in
fixture paths and formatting. README matches the new wiring, and no library API,
lockfile or downstream repository was changed. The owner committed the migration
as `test(lib): organize repository suites with lib.tests`. After HEAD moved,
the complete committed tree matched the reviewed index snapshot exactly: all 94
file blobs and modes agree. The project worktree was clean on inspection. This
checkpoint associates the inspected migration commit; the validation above ran
before commit against identical source, with no post-commit rerun. The migration
is complete. Broader runtime/platform work remains in backlog, outside its scope.
