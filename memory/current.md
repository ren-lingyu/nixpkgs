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
the project worktree was clean on inspection. This checkpoint associates that
inspected snapshot. Validation ran before commit against the same content. No ordinary project
commit was created by the agent.

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
pkgs }`, and overlays takes `{ lib, overlayTree }`. The root injects the internal
aggregator for independent tests without exposing it through the public library.
Cross-parent-directory dependencies must be passed
exclusively as function parameters. Parent-relative imports and equivalent
ancestor traversal are forbidden; downward and same-directory imports are used.

The merge suite contains 43 named evaluation cases covering recursive merging,
strict conflicts, input/options validation, functions, lists, laziness,
derivation-shaped leaves and later-entry precedence. The packages suite has
54 cases on x86_64-linux: 48 generic/mock cases and six real package-set
evaluations. The new generic overlays suite adds 29 independent evaluation
cases; see `memory/overlay-tests-design.md` for extraction status and
`memory/package-aggregation-rules.md` for package coverage. Suites return boolean
results or throw failed case names. The flake injects
library and package dependencies and maps suites to per-system JSON checks via
`pkgs.writeText`. The existing treefmt/nixfmt check remains integrated.

Authorized validation passed for the generic extraction and its final formatting:

- `timeout 120s nix fmt -- flake.nix lib/default.nix lib/packages/default.nix lib/overlays tests/default.nix tests/overlays.nix tests/fixtures/overlays`
- `timeout 120s nix build --show-trace --no-link --no-write-lock-file .#checks.x86_64-linux.overlays .#checks.x86_64-linux.packages`
- `timeout 120s nix flake check --no-write-lock-file --show-trace`

The full check passed all three suites (126 cases) and formatting on
x86_64-linux. Package and merge report derivations are unchanged from the
pre-refactor versions. Other systems were skipped. The first targeted build
attempt was blocked by sandbox access to the Nix daemon; the same authorized
command passed outside the sandbox. No lockfile update, large Emacs/TeX build
or runtime ecosystem smoke test was performed. Static review found no
ancestor-relative dependencies, no domain names in the generic layer and no
whitespace errors. The owner subsequently preferred a flat single-file module name. The extraction
now uses `lib/overlay-tree.nix`, with both imports updated and all changes committed.
Its implementation bytes are unchanged by the move. The full authorized flake
check was rerun after the rename and passed all 126 cases and formatting on
x86_64-linux; other platforms remain unverified. The formatter command above
records its original pre-rename path rather than a current runnable path.

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

## Proposed shared overlay layer and lib.tests

The owner reviewed a new guide and then requested implementation. See
`memory/overlay-tests-design.md` for the proposed architecture and the owner's
adopted mkChecks extraction contract: skip missing/non-derivation overlay leaves,
traverse only discovered descendants through non-derivation attrset namespaces,
and error on missing/incompatible namespace paths. Never enumerate arbitrary
scope attributes. Factories supply no extraction path mapping; callers handle
relocated exports. Migrating this repository's own test suites remains deferred;
independent fixtures can validate the API while existing checks stay intact.
The owner split implementation into deliveries. The first delivery is now
committed: shared-layer extraction and an independent overlays test suite,
validated before the owner committed it. The internal
aggregator at `lib/overlay-tree.nix` accepts `implicitOverlays`, while the
package adapter supplies Emacs/TeX rules and a directory-capturing TeX selector.
Public APIs remain unchanged. Namespace errors now use the domain-neutral
`overlays.mkOverlay` diagnostic prefix. Package extraction and module algorithms
are unchanged, using injected directory helpers.

The owner now requested updating GAW and proceeding with public lib.tests under
the settled contract. This second delivery is starting; no tests API implementation
or validation has run yet. Preserve the existing boolean-to-JSON suites and add
independent API cases plus a real extracted check. Repository test-suite migration
remains deferred independently.
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
