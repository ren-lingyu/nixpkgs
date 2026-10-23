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
reviewed before committing; the project worktree is clean. This checkpoint
associates that inspected project snapshot. Validation below ran before the
commit, against the same implementation content; it was not rerun after commit.
No ordinary project commit was created by the agent.

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

`tests/default.nix` accepts `{ llib, lib, pkgs }` and forwards dependencies
only where used: the merge suite takes `{ llib }`, and the packages suite takes
`{ llib, lib, pkgs }`. Cross-parent-directory dependencies must be passed
exclusively as function parameters. Parent-relative imports and equivalent
ancestor traversal are forbidden; downward and same-directory imports are used.

The merge suite contains 43 named evaluation cases covering recursive merging,
strict conflicts, input/options validation, functions, lists, laziness,
derivation-shaped leaves and later-entry precedence. The packages suite has
54 cases on x86_64-linux: 48 generic/mock cases and six real package-set
evaluations. See `memory/package-aggregation-rules.md` for their scope and limits.
Suites return boolean results or throw failed case names. The flake injects
library and package dependencies and maps suites to per-system JSON checks via
`pkgs.writeText`. The existing treefmt/nixfmt check remains integrated.

Authorized validation passed after the final implementation changes:

- `timeout 120s nix fmt -- flake.nix lib/packages tests/default.nix tests/packages.nix tests/fixtures/packages`
- `timeout 120s nix build --show-trace --no-link --no-write-lock-file .#checks.x86_64-linux.packages`
- `timeout 120s nix flake check --no-write-lock-file --show-trace`

The final full check passed both suites (97 cases total) and formatting on
x86_64-linux. Other systems were skipped. No large Emacs/TeX environment was
built, no runtime ecosystem smoke test was performed, and the lockfile was not
updated. Static review found no ancestor-relative dependencies in package library
or test Nix files; the staged diff has no whitespace errors or unstaged edits.

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

README and tests are synchronized and the implementation is committed.
No further implementation or validation is currently outstanding within this
bounded scope. Future work should be selected separately from backlog. The local
`~/nixos` and `~/emarccs` references were read only and remain unchanged.

Read `memory/backlog.md` for broader package-set support, real consumer builds,
runtime smoke tests and other platforms. These remain non-blocking deferred
work. Overall historical buildability and the complete packaging migration
remain unverified.

## Proposed shared overlay layer and lib.tests

The owner requested review of a new guide, not implementation. See
`memory/overlay-tests-design.md` for the proposed architecture and the owner's
adopted mkChecks extraction contract: skip missing/non-derivation overlay leaves,
traverse only discovered descendants through non-derivation attrset namespaces,
and error on missing/incompatible namespace paths. Never enumerate arbitrary
scope attributes. Factories supply no extraction path mapping; callers handle
relocated exports. Migrating this repository's own test suites remains deferred;
independent fixtures can validate the API while existing checks stay intact.
The contract questions are settled; implementation awaits a separate request.
The completed package migration above remains the implemented baseline.

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
