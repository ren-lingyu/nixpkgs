# Built-in package aggregation rules

## Status, purpose and source boundary

This is the owner's scoped development contract, reviewed against the current
aggregator and the two local reference implementations. Implementation is pending.
The present request authorizes document review and GAW memory organization, not
starting implementation or executing validation commands.

Move existing Emacs and TeX Live aggregation practice into `lib.packages`, with
automatic selection by immediate child-directory name. Reuse the current scope,
namespace and descendant-overlay mechanisms. The owner's later supplement adds
one intentional enhancement: support same-name TeX package overrides through
the existing environment-selection entry points, in addition to new names.

The owner permits read-only source, history and relevant documentation inspection
throughout `~/nixos` and `~/emarccs`. Never modify files, switch branches or create
commits there. Design references are:

- `~/emarccs/pkgs/emacsPackages/overlay.nix`: Emacs factory.
- `~/nixos/pkgs/pkgs/texlivePackages/overlay.nix`: TeX environment integration.
- `~/nixos/pkgs/pkgs/piPackages/`: ordinary child overlays, without a parent rule.

These are owner-reported working examples and were inspected as source. No
runtime validation of this migration has been performed.

## Workspace baseline and organization

The supplied guide names `lib/packages.nix`. At review time the owner had already
staged its 100%-identical move to `lib/packages/default.nix`, with the corresponding
`lib/default.nix` import changed to `./packages`. Keep that existing preparation;
use the current paths rather than recreating the old file. The staged move was
not committed or otherwise changed by the agent.

Keep the public namespace `lib.packages`. Independent internal rule functions
can live at `lib/packages/rules/emacsPackages.nix` and
`lib/packages/rules/texlivePackages.nix`. The aggregator chooses and composes
rules. Do not duplicate namespace/scope algorithms or create a rule registry.
Rules need not be exposed as `lib.packages.rules`.

Cross-parent-directory dependencies must flow through function parameters;
no parent-relative imports or equivalent ancestor traversal. The aggregator
may import rule files downward and inject required functions or data.

## Dispatch contract

Dispatch belongs only in the outer `mkOverlays_` path, using `root`'s immediate
child directory names. Leave ordinary recursive `mkOverlay_` discovery generic.

| Child condition | Required composition |
| --- | --- |
| Explicit caller-selected `overlayFile` exists | Keep existing explicit loading and composition; no built-in rule. |
| No explicit file, descendants exist, name is `emacsPackages` | Built-in Emacs factory owns `descendantOverlay`; no automatic namespace overlay for those descendants. |
| No explicit file, descendants exist, name is `texlivePackages` | Built-in ordinary local integration overlay, followed by existing namespace overlay. |
| No explicit file, descendants exist, any other name | Existing generic namespace aggregation. |
| No explicit file and no descendant overlays | No result entry, including the two special names. |

An explicit ordinary overlay is followed by the existing automatic namespace
overlay when descendants exist. An explicit `{ descendantOverlay }` factory
owns those descendants and suppresses automatic namespace aggregation. Its mere
presence disables the built-in rule even when the name matches a special case.
Preserve relative composition order. Do not apply Emacs descendants twice or
omit the TeX namespace overlay. Return one composable overlay per selected
immediate child. The root's own overlay file remains ignored.

`overlay.nix` in examples denotes the caller's `overlayFile`; do not hardcode
that name or alter its relative-path meaning. Do not add dispatch options.
Nested occurrences of special directory names must remain generic.

## Emacs rule

Migrate the existing factory behavior:

```nix
{ descendantOverlay }:
final: prev: {
  emacsPackagesFor = emacs:
    (prev.emacsPackagesFor emacs).overrideScope descendantOverlay;
}
```

Reuse the existing descendantOverlay protocol. This extends the scope for each
chosen Emacs derivation, rather than merely merging the default `emacsPackages`
attribute set. Built-in factory classification cannot depend solely on
`isOverlayFactory_` reading a file that is absent: the selected implicit rule
must also suppress the generic namespace overlay.

## TeX Live rule and same-name overrides

Keep the original rule as an ordinary local overlay. Existing
`mkNamespaceOverlay_` remains responsible for populating final `texlivePackages`.
Preserve the reference rule's wrapping, merge priorities, conditional guards and
handling of `texlive.withPackages`, `texlive.combined`, and the supported top-level
environments. Do not expand its environment list:

`texliveBasic`, `texliveBookPub`, `texliveConTeXt`, `texliveFull`, `texliveGUST`,
`texliveInfraOnly`, `texliveMedium`, `texliveMinimal`, `texliveSmall`, `texliveTeTeX`.

Review finding: generic namespace overlays can replace an existing package
attribute. However, the reference integration's `extraTexlivePackages_` explicitly
filters out every name already present in `prev.texlivePackages`. It therefore
does not explicitly forward same-name replacements into selection callbacks.
Static inspection does not prove whether a particular upstream closure happens
to pick up a replacement anyway; complete replacement support is not established.

The owner requires explicit support in this development scope. Both additions
and same-name custom replacements must be visible through the existing package
selection interfaces, and a selected replacement must reach the resulting TeX
environment. Verify with distinct original/replacement markers, not attribute
existence alone. Preserve unrelated packages and original merge priorities.

This is an intentional functional extension to the migration-only instruction,
authorized by the owner's supplement. Do not retain the old new-names-only
filter as the full contract, and do not silently broaden this into a TeX package
set redesign. Choose a bounded selection mechanism during implementation; report
any further required behavior change before introducing it.

## Unchanged APIs and excluded work

Keep the public signatures of `mkOverlays { root, overlayFile }`,
`mkLegacyPackages { root, overlayFile, pkgs }`,
`mkNixosModule { root, modulePath }` and `mkHomeModule { root, modulePath }`.
`mkLegacyPackages` extracts packages from an already extended package set using
overlay directory structure. Do not restore packagePath discovery or recursive
callPackage-based construction. Do not refactor the two module aggregators.

`piPackages` needs no rule file. Keep existing `mkNamespaceOverlay_` and
`mkAttrsetOverlay_` behavior. Exclude automatic `package.nix` discovery, new
configuration options, registry frameworks, scope-algorithm redesign, other
package-set-specific rules, the full package-set test matrix and downstream
consumer changes. Additional package-set support is a non-blocking backlog item,
not a prerequisite for completing these two built-in rules.

## Implementation sequence and minimal acceptance

1. Inspect the reference rules and current loader/composition helpers; retain
   existing behavior except the requested TeX same-name enhancement.
2. Add independent internal rule files, then wire top-level dispatch while
   reusing existing composition and descendant-overlay machinery.
3. Use local fixtures or temporary copies to model absent parent overlays.
   Never remove the real reference files. Inject `llib` and any actually needed
   `lib` or `pkgs`; preserve the test dependency boundary.
4. Verify both implicit built-ins, ordinary namespaces including piPackages,
   empty directories, nested special names, custom overlayFile names, and
   explicit ordinary/factory priority. Confirm Emacs descendants apply once,
   and TeX descendants populate the namespace as well as selection entry points.
5. Lightly evaluate Emacs scopes for different Emacs inputs and TeX selection
   callbacks. Include newly named and same-name TeX packages, unchanged packages,
   and extraction through unchanged `mkLegacyPackages`. Do not rely only on the
   default Emacs namespace if that would miss per-Emacs factory behavior.
6. The existing checks and full `nix flake check` must pass for completion.
   No prior full-check success should be assumed. Large Emacs/TeX builds are not
   required for this migration; commands still need task-appropriate authorization.
7. Update README aggregation documentation to match dispatch, special names,
   explicit-file precedence, TeX replacement support and unchanged extraction.

Completion requires unchanged public APIs and generic behavior, working internal
rules and dispatch, explicit-rule priority, the requested TeX replacement
behavior, consistent documentation and successful minimal validation. Downstream
parent overlays may become removable in a later separately scoped migration;
this work does not delete them or modify the reference repositories.
