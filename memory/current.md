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
before commit against the same content. The test-suite migration below is now
staged and validated on top of it, without a project commit; no new project parent
is attached for those worktree changes. No ordinary project commit was created
by the agent.

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

`tests/default.nix` accepts `{ llib, lib, pkgs, overlayTree }` and now returns
check derivations directly. Ordinary suites live under tests/suites/{mergeAttrsRecursive,
overlays,packages}, with cases.nix, test-overlay.nix and any local fixtures.
The entry discovers only test-overlay.nix, constructs a scope, and uses lib.tests
to extract the reports. A shared local mkResultCheck wraps raw case results;
callPackage supplies report-wrapper arguments, not raw case results.

The root independently requires exactly mergeAttrsRecursive, overlays and
packages from discovery. testApi and three real API checks remain directly
wired, so collection failures cannot silently omit their own acceptance tests.
The merge standalone path remains a thin downward import of its moved cases.
All cross-parent dependencies use parameters/scope; no ancestor-relative imports.

Coverage remains 173 named cases on x86_64-linux: 43 merge, 54 packages (including
six real package-set evaluations), 29 generic overlays and 47 test API cases.
Three real writeText checks remain directly included. See
`memory/overlay-tests-design.md` for migration details and important scope findings.

Validation of the staged migration passed after final code fixes and formatting:

- Scoped nix fmt over flake.nix, tests/default.nix, the standalone merge shim and
  tests/suites; no public library source changed.
- Targeted nix build of the four JSON report checks.
- `timeout 10s nix-instantiate --eval --strict --readonly-mode --expr 'import ./tests/merge-attrs-recursive.nix { llib = import ./lib { lib = {}; }; }'`
- Pinned-baseline comparison against the committed public test API snapshot:
  all seven test check names and drvPaths are exactly unchanged (treefmt excluded).
- An injected testEntry verifier confirms normal assembly succeeds, while empty,
  missing-package and extra-check mkChecks results fail at the root name guard.
- `timeout 120s nix flake check --no-write-lock-file --show-trace` passed all
  suites, the three real checks and treefmt on x86_64-linux. Other systems skipped.

Static comparison confirmed original case logic unchanged except fixture paths
and formatting, and all 44 moved fixtures byte-identical. No lockfile update,
large ecosystem build, downstream edit or ancestor-relative import was introduced.
The verification script in ignored tmp/ takes all dependencies as function
parameters; its results are distilled above, not needed as a lasting test input.
All intended project changes are staged, with no unstaged project edits. These
results describe the worktree, not an uncreated migration commit.

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
contract and coverage. The owner requested `lib/tests/default.nix` to mirror
`lib/packages/default.nix`. Root library assembly injects lib and overlayTree.
Public tests.mkOverlays returns unapplied overlays without package defaults;
tests.mkChecks takes a caller-built scope and flattens directory-selected
derivations with separator defaulting to "/". Missing/non-derivation overlay
leaves are skipped; discovered namespaces must exist as non-derivation attrsets.
Factory relocation has no implicit path mapping. No registry, runner, helper
filter or arbitrary scope enumeration was added.

The owner approved and requested the subsequent own-suite migration. It is now
implemented and validated in the staged worktree: three ordinary suites use
lib.tests, while testApi acceptance remains independently loaded. The flake now
imports the complete check set without per-suite wrapping. README documents the
new local layout, root guard and preserved standalone merge entry. No public
API or assertions were changed. Next is owner review/project commit; the agent
must not create that commit. Broader package-set/runtime tests remain deferred.

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
