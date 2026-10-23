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
Public lib.tests is now implemented and validated on top of that baseline but
is staged, not committed. No additional project parent is attached for the
uncommitted feature. No ordinary project commit was created by the agent.

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

`tests/default.nix` accepts `{ llib, lib, pkgs, overlayTree }` and forwards
only used dependencies: merge takes `{ llib }`, packages takes `{ llib, lib,
pkgs }`, overlays takes `{ lib, overlayTree }`, and testApi takes `{ llib, lib,
pkgs }`. The root injects the internal
aggregator for independent tests without exposing it through the public library.
Cross-parent-directory dependencies must be passed
exclusively as function parameters. Parent-relative imports and equivalent
ancestor traversal are forbidden; downward and same-directory imports are used.

The merge suite contains 43 named evaluation cases covering recursive merging,
strict conflicts, input/options validation, functions, lists, laziness,
derivation-shaped leaves and later-entry precedence. The packages suite has
54 cases on x86_64-linux: 48 generic/mock cases and six real package-set
evaluations. The generic overlays suite adds 29 independent evaluation cases,
and the new public test API suite adds 47 cases. Three real writeText checks
are separately extracted by that API and built directly through flake checks.
See `memory/overlay-tests-design.md` for API/aggregation status and
`memory/package-aggregation-rules.md` for package coverage. Suites return boolean
results or throw failed case names. The flake injects
library and package dependencies and maps suites to per-system JSON checks via
`pkgs.writeText`. The existing treefmt/nixfmt check remains integrated.

Authorized validation passed for the staged public test API and final formatting:

- `timeout 120s nix fmt -- flake.nix lib/default.nix lib/tests tests/default.nix tests/test-api.nix tests/test-checks.nix tests/fixtures/test-api`
- `timeout 120s nix build --show-trace --no-link --no-write-lock-file .#checks.x86_64-linux.testApi .#checks.x86_64-linux.testApi/checks/alpha .#checks.x86_64-linux.testApi/checks/nested/beta .#checks.x86_64-linux.testApi/validators`
- `timeout 120s nix flake check --no-write-lock-file --show-trace`

The full check passed four evaluation suites (173 named cases), three real
extracted writeText checks and formatting on x86_64-linux. Original package,
merge and generic-overlay report derivations are unchanged. Other systems were
skipped. No lockfile update, large Emacs/TeX build or runtime ecosystem smoke
test was performed. Static review found no ancestor-relative dependencies or
whitespace errors. All intended project changes are staged, with no unstaged
project edits. This validation concerns the worktree before a feature commit.

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

The second delivery, public lib.tests, is implemented, documented and validated
in the staged worktree. Read `memory/overlay-tests-design.md` for the complete
contract and coverage. The owner requested `lib/tests/default.nix` to mirror
`lib/packages/default.nix`. Root library assembly injects lib and overlayTree.
Public tests.mkOverlays returns unapplied overlays without package defaults;
tests.mkChecks takes a caller-built scope and flattens directory-selected
derivations with separator defaulting to "/". Missing/non-derivation overlay
leaves are skipped; discovered namespaces must exist as non-derivation attrsets.
Factory relocation has no implicit path mapping. No registry, runner, helper
filter or arbitrary scope enumeration was added.

Existing boolean-to-JSON suites retain their wiring and assertions. Independent
API tests and three real extracted checks are added alongside them. Migrating
the repository's own suites to lib.tests remains explicitly deferred in backlog.
The next action is owner review and a project commit if desired. The agent must
not create that ordinary commit. No implementation or validation remains within
this bounded feature scope; other platforms remain unverified.

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
