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
checks integration. The previous shared-library checkpoint associated the final
committed baseline inspected then. The current review observes a user-staged
100%-identical move from `lib/packages.nix` to `lib/packages/default.nix` and its
updated import. That preparation is preserved and is not yet a committed source
snapshot. No ordinary project commits were created by the agent.

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
differs from the built version only in formatting. The earlier shared-library
checkpoint associates that final inspected snapshot, not a claim that the build
ran at committed HEAD.
No full `nix flake check`, formatting check or real ecosystem build was run by
the agent. Previous single-run command authorizations are consumed.

## Next scoped development: built-in aggregation rules

Read `memory/package-aggregation-rules.md` for the owner's reviewed development
contract. It introduces root-child-name defaults for Emacs and TeX Live while
preserving explicit overlay precedence and the existing public APIs. The owner's
supplement requires TeX same-name package replacements to reach the existing
selection/environment entry points. The reference rule explicitly forwards only
new names, so this is an intentional enhancement rather than mechanical copying.

The current request is review and memory organization only. No implementation
or validation of the built-in rules has started. The next development step is
reference/loader inspection under that contract when implementation is requested.
Local `~/nixos` and `~/emarccs` repositories are authorized read-only references.

Read `memory/backlog.md` for broader package-set tests and non-blocking future
support for package sets beyond the two named built-ins. That broader work must
not block this bounded migration. Overall historical buildability and the complete
packaging migration remain unverified.

## Memory conventions

Start here for current state, follow `memory/package-aggregation-rules.md` for
the reviewed migration contract, `memory/backlog.md` for deferred work and
`memory/obsolete-nur.md` for the obsolete NUR history. Entry skills describe only
how to read memory. Skill changes require separate checkpoints from memory.
Use `feat(skills)` for a newly available skill; scope library-driven test
integration as `test(lib)` even when its wiring lives in `flake.nix`.

Checkpoint consequential findings and completed phases when they have recovery
value. Do not defer a warranted checkpoint merely because the owner did not
separately request one; the normal GAW memory loop is already authorized.
