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

The owner has committed the flake infrastructure, shared library, tests and
checks integration. The project worktree was clean at checkpoint preparation.
The associated project snapshot is the final committed state inspected during
this review; no ordinary project commits were created by the agent.

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

`tests/default.nix` and its merge suite accept `{ llib }`; tests inherit the
function from that library. Add `lib` or `pkgs` only when actually needed.
Cross-parent-directory dependencies must be passed exclusively as function
parameters. Parent-relative imports and equivalent ancestor traversal are
forbidden. The root loads library and tests downward; the test aggregator
loads only its same-directory suite. Test cases perform no imports.

The merge suite contains 43 named evaluation cases. It returns boolean results
or throws with failed case names. Cases cover recursive merging, strict
conflicts, input/options validation, functions, lists, laziness, derivation-shaped
leaves and later-entry precedence including subtree replacement barriers.
Derivation fixtures use a type marker, not real package builds.

The flake passes `llib` to the test entry and maps suites to per-system checks.
A failed suite stops evaluation; successful checks write JSON reports via
`pkgs.writeText`. The existing treefmt/nixfmt check remains configured. README
contains standalone evaluation and flake check commands.

Validation: 43 cases passed local evaluation before the final `llib` parameter
wiring. The final wiring then passed the authorized targeted build:
`timeout 120s nix build --no-link --no-write-lock-file .#checks.x86_64-linux.mergeAttrsRecursive`.
That build ran against the integration worktree before the owner's final
commit. The final committed integration was subsequently inspected; its source
differs from the built version only in formatting. The checkpoint associates
that final inspected snapshot, not a claim that the build ran at committed HEAD.
No full `nix flake check`, formatting check or real ecosystem build was run by
the agent. Previous single-run command authorizations are consumed.

## Backlog and next action

Read `memory/backlog.md` for package aggregation and real package-set integration
tests. That plan covers representative mechanisms, dependency-binding checks,
internal overlays, staged validation costs and acceptance criteria. It remains
unimplemented; recording it does not authorize implementation or execution.
Await the owner's next task or selection of backlog work.

## Memory conventions

Start here for current state, follow `memory/backlog.md` for deferred work and
`memory/obsolete-nur.md` for the obsolete NUR history. Entry skills describe only
how to read memory. Skill changes require separate checkpoints from memory.
Use `feat(skills)` for a newly available skill; scope library-driven test
integration as `test(lib)` even when its wiring lives in `flake.nix`.

Checkpoint consequential findings and completed phases when they have recovery
value. Do not defer a warranted checkpoint merely because the owner did not
separately request one; the normal GAW memory loop is already authorized.
