# Package groups and shared discovery

## Objective and adopted contract

Implement the owner's reviewed package aggregation plan. Eliminate separate
directory interpretation in overlays, TeX selection and package exports using a
single lazy description tree per packages.mkOverlays call. Add groups, then remove
public mkLegacyPackages without a final compatibility layer. Keep generic scope,
constructor, module and mkChecks public behavior intact.

- Missing/empty groups preserve the independent top-level overlays. Nonempty
  groups independently filter and compose in attrValues/name order.
- Group keys are exclude (string list, default []) and export (false, true for
  legacyPackages, or nonempty string). Reject other fields, invalid types and
  unknown excluded overlay names; duplicate exclusions are allowed.
- Append export as the final extension: check that extension's prev for name
  collisions, select directory-constrained paths from final. Never apply base
  overlays again to select packages. Exclusion constrains participation and
  export paths, not arbitrary attributes in final.
- Discovery, constructor import/classification, instantiation and application
  remain lazy and distinct. Excluding a subtree must not force its constructor.
- Preserve Emacs variants and TeX new-package forwarding, declared replacements,
  nested siblings and atomic derivation behavior. TeX uses the shared subtree.
- Selector error tests use a factory that omits its namespace, or later overlays
  replacing namespaces with scalars/derivations. Ordinary overlays cannot delete
  existing attributes by returning removeAttrs prev.
- Intermediate stage B may delegate the old API to the new selector; stage D
  removes it and migrates all entry points. No new public tree/selector API.

## Scope and verification

Current repository implementation, tests and README only. The owner selected
separate downstream acceptance: do not access or edit nixos.git for this task.
Use local tests for equivalent consumer groups. Real consumer migration and
major-package builds remain a separate follow-up.

The implementation request authorizes the planned source/test/document changes.
Build/check/format commands require the repository's explicit command authority;
announce exact commands and their cache/store/network effects before execution.
No ordinary project staging, commit or lockfile change is planned.

## Current state and next action

Baseline inspected: packages has a filesystem-recursive mkLegacyPackages;
overlay-tree repeats hasEntries/getDirectories recursion; TeX closes over a
separate selector scan. mkChecks independently uses the generic entry and helper
functions, which must remain compatible. Existing package tests include real
Emacs/TeX evaluation plus direct selector failures needing migration.

Stage A implemented discoverTree and mkOverlaysFromTree; generic overlay recursion
now consumes shared lazy children. The original packages/overlays/testApi targeted
Nix build completed successfully after retry outside the sandbox (the initial
attempt could not open the user fetcher SQLite cache). The command uses a 120s
timeout, --no-write-lock-file and --no-link.

Stage B's tree-based selector and TeX subtree injection passed the same targeted
checks while the old API delegated to the selector.

Groups/config validation, final-extension exports and fixtures are now written;
the old API has been removed and test callers migrated. Tests add ordered groups,
all validation branches, upstream/own collisions, later final replacements,
factory omissions, invalid final namespaces and excluded constructor laziness.
Direct workspace package evaluation passed all returned assertions, including
the six existing real Emacs/TeX evaluations. One initial test used a marker absent
from the existing factory fixture; corrected it to assert applications == 1.
README now documents the new API, alternatives for group application, validation,
prev collision checks, final selection, exclusions and package-selection bounds.
Next: scoped formatting, complete flake checks including untracked fixtures,
structural/diff review and final memory consistency check.

New fixtures are untracked, and no project staging is authorized/planned. Normal
Git flake sources omit those files. Evaluate workspace tests directly with Nix
--impure first; use a filtered source snapshot including only project source and
metadata for the final full flake check, without including .git/.agents/tmp.
