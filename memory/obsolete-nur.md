# Obsolete NUR review

## Scope and reason

The local remote-tracking branch `origin/nur_obsolete` was the only visible
`nur_` branch. `origin/main_old` pointed to the same snapshot. This describes
local refs at review time, without claiming the remote was checked.

The owner states that all packaging moved to `~/nixos.git`, making this
repository's NUR packaging role obsolete. No explicit migration or retirement
explanation was found in the inspected commit messages. The destination is
outside the reviewed workspace and was not inspected; the cause comes from
the owner, not a verified cross-repository comparison.

## Reviewed implementation

At the reviewed tip, `pkgs/default.nix` exposes `texlive.luadraw` 3.4 and
`wayfile` 1.1.0. The tree includes a TeX Live integration overlay and a Wayfile
Home Manager module. `default.nix` supplies the traditional NUR entry point;
`flake.nix` exposes `legacyPackages`, overlays and module outputs.

`lib/mk-recursive-overlay.nix` recursively combines attribute trees while
treating derivations as leaves. `lib/strip-package-tree-markers.nix` removes
configured package-tree markers while preserving derivations. These functions
are historical reference material, with no decision to reuse them yet.

The reviewed `main` and obsolete NUR histories have no common ancestor. The new
`main` therefore does not itself retain the old packaging history.

## Historical preservation

The memory checkpoint records the exact reviewed NUR snapshot as an additional
project parent. Its committed tree supplies the reviewed implementation and
its ancestry supplies the historical packaging context. Recover the association
from that checkpoint's actual parent list and inspect the corresponding tree;
do not depend on the old branch names surviving.

The owner intends to retain the commits even if the branch names are deleted,
to support historical builds. Keeping the checkpoint reachable retains the
associated commit and all its ancestors. No branch deletion is part of this
task. An OID written into prose would not provide that reachability.

The newly associated ancestry was screened through historical path listings
and all unique file blobs for oversized files and common credential patterns;
no oversized blobs or matching credentials were found. This was a bounded
retention review, not a claim of an exhaustive security audit.

Preservation retains Nix expressions, source revisions and available lock
files. It does not establish successful historical builds: upstream source
and dependency availability remain relevant. No Nix evaluation or build was
performed, and the existing non-flake entry point also accepts an external
`pkgs` argument or `<nixpkgs>` rather than fixing that environment itself.
