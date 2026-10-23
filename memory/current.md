# Current project state

## Project purpose

This repository is a personal nixpkgs: a shared foundation for flake-based
projects to consume as an input where needed. Its adopted description is
`Personal nixpkgs`. Shared functions are the current implemented scope;
framework components, possibly built on flake-parts, remain a future possibility.

The former NUR packaging role became obsolete after packaging moved to
`~/nixos.git`, according to the owner. Use **obsolete**, matching `nur_obsolete`.
Read `memory/obsolete-nur.md` for the old snapshot review and retention rationale.
Overall migration completeness and historical buildability remain unverified.

## Completed shared library

The owner has committed the shared-library baseline. The built-in aggregation
implementation has now been committed by the owner as
`feat(lib): add built-in Emacs and TeX Live aggregation rules`, including the
preparatory move from `lib/packages.nix` to `lib/packages/default.nix` and its
updated import. The committed diff was inspected and matches the staged candidate
reviewed before committing. An earlier checkpoint associates that inspected
project snapshot. The owner has now committed the generic extraction as
`refactor(lib): extract generic overlay tree aggregation`. Its committed diff
matches the reviewed and validated staged candidate, including the flat filename;
the project worktree was clean on inspection. An earlier checkpoint associates
that inspected snapshot. Validation ran before commit against the same content.
The owner has also committed public lib.tests as
`feat(lib): add test overlay aggregation and check extraction`. After detecting
HEAD movement, every file's blob and mode in the committed tree matched the
reviewed staged snapshot exactly (90 files), and the project worktree was clean.
An earlier checkpoint associates that inspected feature commit. Validation ran
before commit against the same content. The owner has now committed the test-suite migration below as
`test(lib): organize repository suites with lib.tests`. All 94 committed file
blobs and modes match the reviewed index snapshot exactly; the project worktree
was clean on inspection. An earlier checkpoint associates that inspected migration
commit. Validation ran before commit against the same content; no checks were
rerun just to establish provenance. No ordinary project commit was created by
the agent.

`lib.packages` exposes `mkOverlays`, `mkLegacyPackages`, `mkNixosModule` and
`mkHomeModule`. README.org documents their interfaces and directory conventions.
The original practice was inspected in `~/nixos/pkgs` and `~/emarccs`; their
library implementations matched this repository at the earlier comparison.
Runtime compatibility across all package-set mechanisms is not established.

`lib.mergeAttrsRecursive` accepts a named configuration argument
`{ allowOverrides ? false; }`, followed by a positional list of non-derivation
attribute sets. Shared ordinary attribute sets merge recursively. In strict
mode, repeated leaves conflict even when equal; set-versus-leaf collisions
also fail. Errors identify paths as JSON arrays, and all potential conflicts
are checked before returning the result while unique leaves remain lazy.
Functions and derivations are leaves. An empty input produces `{ }`.

When overrides are enabled, **later list entries win**. A leaf replaces an
entire earlier subtree. For example,
`[ { a.x = 1; } { a = 2; } { a.y = 3; } ]` produces `{ a.y = 3; }`.
This generic merge can combine repository-level libraries; leaf values are
not restricted to functions. The implementation uses builtins only.

## Tests and dependency boundary

`tests/default.nix` accepts `{ llib, lib, pkgs, overlayTree }` and returns
check derivations directly. Ordinary suites remain under tests/suites with
cases.nix, test-overlay.nix and local fixtures. The entry now supplies direct
API checks through mkChecks.checks and dependencies through mkChecks.args;
it no longer manually constructs a scope or composes overlays.

The root independently requires the exact complete output name set: existing
API checks plus mergeAttrsRecursive, overlays and packages. testApi and three
real API checks are defined independently of ordinary-suite discovery, then
supplied as existing checks. The standalone merge path remains a downward shim.
Cross-parent dependencies use parameters/scope; no ancestor-relative imports.

Coverage is now 184 named cases on x86_64-linux: 43 merge, 54 packages (including
six real package-set evaluations), 29 generic overlays and 58 test API cases.
The expanded API suite directly exercises mkChecks, including its exact public
namespace, preserving initial checks, actual replacement and prev/final order,
final dependency resolution, explicit callPackage argument precedence, unexported
argument derivations, defaults, invalid retained values and packages-name
resolution. It no longer builds caller scopes via public tests.mkOverlays.
Three real writeText checks remain included.

The owner committed the checks/args implementation and mkOverlays removal as
`feat(lib): consolidate test assembly in mkChecks`. The complete committed diff
matches the final reviewed candidate (13 files), and the project worktree was
clean on inspection. An earlier checkpoint associates that inspected source.
Scoped nix fmt and `timeout 120s nix flake check --no-write-lock-file --show-trace`
passed after the final public-interface removal and direct API regression
changes on x86_64-linux,
including all reports, three real checks and treefmt. Other systems were skipped.
The three ordinary report drvPaths and three real check drvPaths are unchanged;
testApi's report changes with the new assertions. No lockfile or downstream
repository was modified. Validation ran before commit against the same source;
no checks were rerun for grounding. See `memory/overlay-tests-design.md` for the
current contract and earlier migration evidence. The tests-side revision is
complete. The owner has adopted a uniform overlay constructor design for the
next development; see the constructor section below. Broader package-set/runtime
work remains deferred.

## Package-side design boundary

The owner considered moving overlay application into mkLegacyPackages,
passing external overlay inputs, retaining discovery metadata and exporting
an entire extended pkgs as legacyPackages. No redesign was adopted: the owner
explicitly deferred the package side. Keep packages.mkOverlays public and
mkLegacyPackages as extraction from already extended pkgs. Do not apply the
test API simplification or inferred extraArgs/pkgs parameters to packages.

## Overlay constructors: adopted revision, implementation pending

The owner superseded the mixed-format proposal and all four prior review
recommendations with a uniform constructor protocol. Every overlayTree-loaded
or implicit definition must use a constructor returning final: prev overlay;
only extraArgs and descendantOverlay are legal explicitly declared constructor
keys. Selective injection, defaulted declarations and laziness are required.
Only descendantOverlay owns descendants. No two-argument source compatibility
or package/test protocol mode is to be introduced. Public overlays remain
standard two-argument functions; ordinary final destructuring stays legal.

Read memory/parameterized-overlays.md for the full adopted contract, migration
scope and tests. packages.mkOverlays gains extraArgs; all source/fixture and
implicit definitions are migrated, including test entries. mkChecks keeps its
public API and args semantics, with constructor extraArgs defaulting to {}.
The earlier package-consumption redesign remains deferred.

This turn records the decision amendment. Source remains at the clean committed
checks-only baseline; no implementation or Nix validation of the new protocol
has occurred. Next: implementation under the revised scope when requested,
with separate exact-command authorization for staging, formatting and checks.

## Built-in aggregation rules: implemented and validated

Read `memory/package-aggregation-rules.md` for the contract and implementation
outcome. Root-child-name defaults now provide Emacs and TeX Live rules, with
explicit overlay precedence, unchanged public APIs and unchanged generic scope,
extraction and module-discovery algorithms. Emacs owns descendant application;
TeX uses a local integration overlay followed by the generic namespace overlay.

TeX forwards same-name replacements declared by the current TeX subtree into
selection callbacks, while preserving forwarding of new names from other
overlays. Replacement applies at package selection time; already instantiated
environments are not automatically rebuilt. Nested selection merges preserve
unrelated siblings and treat derivations atomically. These bounds were adopted
during implementation planning rather than broadening all external replacements.

README and tests are synchronized. The built-in rule implementation is committed;
the generic-layer extraction is committed and preserves those behaviors.
No additional package-specific implementation is outstanding. The local
`~/nixos` and `~/emarccs` references were read only and remain unchanged.

Read `memory/backlog.md` for broader package-set support, real consumer builds,
runtime smoke tests and other platforms. These remain non-blocking deferred
work. Overall historical buildability and the complete packaging migration
remain unverified.

## Shared overlay layer and lib.tests

The generic layer is committed at `lib/overlay-tree.nix`; the package adapter
supplies implicit Emacs/TeX rules and a directory-capturing selector. Its public
APIs and extraction/module algorithms are unchanged. Namespace diagnostics use
the domain-neutral `overlays.mkOverlay` prefix.

The second delivery, public lib.tests, is implemented, documented, validated
and committed by the owner. Read `memory/overlay-tests-design.md` for the complete
contract and coverage. The current module is `lib/tests.nix`. The owner
corrected the earlier directory preference: packages uses a directory because
it has additional rule files; a single-file module should remain flat. The owner
committed the byte-identical move from `lib/tests/default.nix` and updated the
root import as `refactor(lib): flatten tests module into a single file`. Inspection
confirmed only that move and import changed, with a clean project worktree.
An earlier checkpoint associates the inspected refactor; tests were not rerun for this
path-only change. Root library assembly injects lib and overlayTree.
The committed lib.tests namespace now exposes only mkChecks; the owner requested
removing public tests.mkOverlays because tests need a controlled checks entry,
while overlay discovery/composition remains internal.
The owner then requested replacing mkChecks.scope with checks and args, both
defaulting to empty attrsets. The implemented API now builds its own
independent test fixed point, applies discovered overlays and preserves initial
check names using final values, alongside directory-selected derivations.
separator still defaults to "/". Dependencies must be passed explicitly in args,
including writeText when needed; pkgs members are not implicitly injected. Missing/non-derivation overlay
leaves are skipped; discovered namespaces must exist as non-derivation attrsets.
Factory relocation has no implicit path mapping. No registry, runner, helper
filter or arbitrary scope enumeration was added. args values are not exported
unless selected by a discovered path; initial check names must finish as
derivations. checks wins initial name collisions with args. Flattened discovered
checks win output-name collisions with retained initial checks.

The owner approved and requested the subsequent own-suite migration. It is now
implemented, validated and committed by the owner: three ordinary suites use
lib.tests, while testApi acceptance remains independently loaded. The flake now
imports the complete check set without per-suite wrapping. README documents the
new local layout, root guard and preserved standalone merge entry. No public
API or assertions were changed in that completed migration. The subsequent
checks/args API revision, public mkOverlays removal and related caller/test
updates are also validated and committed by the owner. Broader package-set/runtime
tests remain deferred.

## Memory conventions

Start here for current state, follow `memory/package-aggregation-rules.md` for
the reviewed migration contract, `memory/backlog.md` for deferred work and
`memory/obsolete-nur.md` for the obsolete NUR history. Entry skills describe only
how to read memory. Skill changes require separate checkpoints from memory.
Use `feat(skills)` for a newly available skill; scope library-driven test
integration as `test(lib)` even when its wiring lives in `flake.nix`.

For GAW checkpoint messages, choose the type from the actual knowledge or
workflow change. Do not default to `docs` merely because memory is written in
Markdown; reserve `docs` for documentation changes. The owner explicitly asked
to avoid overusing `docs` in GAW. This is a forward-looking convention, not an
instruction to rewrite existing checkpoint history.

Checkpoint consequential findings and completed phases when they have recovery
value. Do not defer a warranted checkpoint merely because the owner did not
separately request one; the normal GAW memory loop is already authorized.
