# Current project state

## Initial 0.1.0 changelog: development draft created, not frozen

The owner plans 0.1.0 but explicitly says scope/TODOs are not frozen. They asked
for CHANGELOG.org maintenance under the supplied git-maintenance changelog skill
and a deeper review of commit history. No prior changelog or local release tags
were found. Read bounded history from the initial commit through the current
changelog-whitelist commit, including bodies and selected historical library API
trees, and verified the resulting public source. Created only CHANGELOG.org,
using the adopted Org lifecycle metadata and a new TODO 0.1.0 entry, with Fixed
and Added summaries. No NEXT/DONE, CLOSED, early CUSTOM_ID, release date, tag or
publication claim. No detailed CHANGELOGS file yet; scope/version identity and
complete detailed notes remain prerequisites for later human freeze/release work.

The draft covers the final shared library/constructor/group/mkChecks contracts,
mkFlake argument function and per-system packages, treefmt/language support,
formatter packages and patched-Nix outputs, independent checks and key fixes
(diagnostics, safe formatter failures/writeback, root matcher and .gitmodules).
Superseded development-only APIs were not mislabeled as upgrades from a released
version. Baseline is committed source; no staged/worktree implementation change
was used. Recent .gitignore commits corrected .gitmodules and explicitly admit
CHANGELOG.org plus CHANGELOGS/*.org. Read-only check-ignore --no-index matches the
root file's negation rule; it is untracked, not ignored. No project staging,
build, formatter, test, README or configuration edit was performed.

Remaining scope: owner review/freeze decisions, later detailed release manuscript
and release verification. Root treefmt excludes README.org but not CHANGELOG.org,
with on-unmatched=fatal and no configured Org formatter visible; matching/check
behavior for this new document needs verification or a separately authorized
configuration change. Existing README also predates formatter activation and
root-input simplification. These were reported, not silently fixed. Await next
instruction; preserve the new untracked CHANGELOG.org.

## gitignore-fmt: hardening, root matching and activation committed

The owner committed the whitelist-style formatter package, treefmt integration
and formatted root .gitignore. At review HEAD is
`style(git): format .gitignore with pkgs.gitignore-fmt`; project was clean at start.
The owner initially requested review/test design, including errors, idempotence
and simplification, then authorized optimizing the script and adding tests, with
further fixes driven by test failures. Execution/format/build commands still
require separate authorization. Inspected the complete 181-line script and
current suite wiring.

Static findings: format_file is invoked in an if condition, so its commands cannot
rely on set -e for failure propagation (confirmed in the GNU Bash set manual).
mkdir, sort, reads and writes need explicit failure handling. In particular a
failed sort can feed empty data into rendering; a failed cat write can be masked
by the following successful printf. cmp's different/error statuses are conflated
by if ! cmp. Final cat > file truncates before writing and is not a safe commit
boundary. These are static code-path findings, not executed reproductions.

Implemented test contract: byte-exact golden fixtures, exit/status/diagnostic and
unchanged-input assertions; format twice equals once, then --check succeeds
without writes for every valid fixture. Check mode returns 0 for formatted,
1 for needs-formatting, 2 for invalid input/operational failure.
Cover headers/sections, anchors, root/directory/glob grouping, stable sorting
within detached-comment barriers, attached/EOF comments, CRLF/empty/missing-LF,
escaped !/#/spaces and duplicate retention. Add CLI paths, mixed multi-file
statuses, injected sort/cmp/write failures, cleanup and per-file non-destructive
failure tests. Avoid comparing general Git semantics across intentional root
anchoring/header insertion; semantic checks belong to already-conforming inputs.

Recommend retaining --check for standalone CI and read-only verification; current
treefmt integration uses normal mode. Prefer explicit error propagation and safe
writeback before performance rewrites. Tests should run the packaged command via
a small isolated suite using Python byte fixtures, injected arguments and the
existing lib.tests path; no parent-directory imports or self-discovered test
acceptance changes.
Implementation written: explicit error propagation, separate rendering,
same-directory temporary replacement preserving mode, explicit symlink rejection,
and isolated package-level tests including command-failure injection. Wire the
package through the root/test args as with nix-flake-patched, preserving independent
mkChecks acceptance. Added a runner with 51 named cases (golden bytes, all-valid
idempotence/check invariants, invalid inputs, paths/permissions/symlinks, mixed
multi-file modes and nine command-failure injections). The owner authorized
repeated scoped formatting and a targeted Nix build of the suite from worktree
paths, since the new tests were initially untracked and omitted from Git flake sources.
The first run passed 47/51: the mock cmp incorrectly assumed coreutils contains
cmp, which also exposed the package's missing explicit diffutils dependency.
Added diffutils to runtimeInputs and fixed the shim; the next build passed all
51 cases. Subsequently strengthened fault tests to verify check mode never
reaches writeback commands. The owner approved final package.nix formatting and
a build through tests/default.nix; both passed, including all 51 strengthened
tests through the real assembly/name guard. Normal package and fault-injection
package builds passed writeShellApplication's checks. Validation is x86_64-linux
only and does not run the heavy nix-flake-patched regression or full flake check.

CLI now accepts -- before file names and rejects unknown leading flags, NUL
bytes and symlinks explicitly. Normalization/order/comment rules are otherwise
retained. Invalid/failed files are unchanged; multi-file processing continues and
aggregates errors. Same-directory replacement preserves mode; already formatted
files and --check preserve bytes, mode, mtime and inode. No claim of a lock or
concurrent-writer exclusion is made. Final scoped formatting and diff --check
passed. The owner staged and committed all seven files as
`fix(pkgs/pkgs/gitignore-fmt): handle failures safely and add regression coverage`.
Every committed file blob and mode matches the reviewed staged implementation,
including the runner and root/test wiring. Tests ran before commit, not after.

The owner requested commit drafting, waiting for HEAD movement, then waiting for
their root excludes edit/staging and a second draft/commit before updating GAW.
After the first commit, the owner paused to correct formatter includes separately:
`fix(treefmt): explicitly match root gitignore files` adds literal .gitignore
alongside **/.gitignore. That committed diff was inspected. The owner then
committed `feat(treefmt): include the root gitignore in formatting checks`, removing
.gitignore from the root treefmt.settings.excludes list. Its full diff matches the
reviewed staged deletion. No staged or unstaged project files remain. This
checkpoint associates the inspected final activation snapshot, retaining the
reviewed hardening and matching correction. No README or lockfile change was
made. README still describes .gitignore as excluded and lacks this new tool/suite.

No treefmt pattern-matching test, formatter execution or full flake check was run
after the matching/exclusion edits. The owner described includes as seemingly
fixed; this is not runtime evidence. The 51 passing script regressions validate
the tool, not the final treefmt integration. Await the next instruction.

## mkFlake argument diagnostics: committed

The owner reported an unreadable list-comparison assertion for a missing
moduleLocation. pkgs/flake.nix now computes missingArgs and uses nixpkgs.lib.assertMsg
for the existing return-attrset, required-attributes and specialArgs-attrset checks.
Missing-field errors identify mkFlake, list the absent attributes and suggest
moduleLocation = ./flake.nix; or __curPos.file in the argument function's result.
The original validation conditions and argument semantics are unchanged, with
the additional function-type guard described below. Only pkgs/flake.nix was
modified. The owner authorized scoped nix fmt and a
30s impure nix eval deliberately omitting moduleLocation. Formatting and diff
--check passed. Eval initially could not access the daemon in the sandbox; the
same authorized command succeeded in reaching the intended failure after
escalation, emitting the new explicit message. Exit 1 is expected for that probe;
no full flake check or builds were run.
Follow-up: the owner requires diagnostic names to use mkFlake at most, never
lib.mkFlake. All four messages now use that prefix. Added a leading isFunction
assertion for argsFun before args is forced, with an argument-function example.
This prevents the generic non-function call error for a second argument attrset.
The owner separately authorized formatting and a 30s eval passing {} as that
argument. Formatting changed no files; the probe reached the expected explicit
mkFlake error (exit 1).
The owner requested commit drafting, waiting for HEAD movement, then GAW update.
Drafted `fix(lib.mkFlake): clarify invalid argument errors` from the staged diff.
Polling observed HEAD move from the locked-Nixpkgs update to that diagnostics
commit; its complete committed diff matches the reviewed staged change. Project
worktree is clean. This checkpoint associates the inspected diagnostics snapshot.
The two negative probes ran before commit; no full check, build or post-commit
rerun was performed. Await the next instruction.

## nix-flake-patched: implementation and README committed

Completed follow-up: the owner rejected the default-package/legacy-export equality
assertion and redundant defaultNix argument, changed flake.nix to pass
nix-flake-patched = pkgs.nix-flake-patched directly, and requested only tests/
adaptation. Updated tests/default.nix and the package suite check.nix to accept
that derivation directly, obtain baseNix/patches from it, and remove both the
legacy-export equality and defaultNix comparison. Retained base version/type/
different-from-base checks and the original four-variant runner.

The suite overlay explicitly passes nix-flake-patched = prev.nix-flake-patched
to check.nix. This is necessary because its output check has the same name;
automatic final-scope injection would otherwise recurse into the check itself.
Read the existing mkChecks fixed-point implementation to confirm this routing.
Scoped nix eval of checks.x86_64-linux.nix-flake-patched.drvPath succeeds and
returns the unchanged a3mp3m0kszc4hnn2s12rnarmkzz43mga regression derivation.
No build, formatter or runtime regression was run; diff --check passed. Only
three tests/ files were edited; the owner's flake.nix edit was preserved, and
the owner has now committed all four files as
`test(nix-flake-patched): simplify regression check arguments`. The complete
committed diff matches the reviewed staged change and the project is clean.
No post-commit build/test was run. The owner requested README synchronization,
now committed as `docs(readme): describe patched Nix outputs and test wiring`.

Also inspected the intervening complete package/dev-shell export commit: internal
groups are now treefmt (lisplens, elisp-autofmt), nix (nix-flake-patched), and
legacy (all directory-selected packages, exported). mkFlake applies treefmt and
nix overlays and provides devShells.nix with the patched binary first on PATH.
The root exports packages.nix as the patched package. pkgs.nix itself remains
unmodified. README now documents these group/output details, explicit shell selection, the
direct test argument and prev injection, as well as the existing patch exclusion
and Cabal project formatter. Source claims were checked against current committed
files. diff --check passed; no build/test/formatter ran. The full committed
README diff matches the reviewed staged documentation. Project worktree/index
are clean. This checkpoint grounds the inspected committed documentation and
implementation; no post-commit build/test was run. Await the next instruction.

The owner approved the standalone package plan, the name nix-flake-patched,
flake-check integration and 1800-second heavy builds. Use the five reference
repositories only for input topology; the owner explicitly replaced live consumer
integration with minimal synthetic flakes. No reference repository was changed.
The owner committed the reviewed delivery as
`feat(nix-flake-patched): add Nix with nested relative input fixes`.
All 11 committed file blobs and modes match the staged diff reviewed for the
commit draft; the project worktree/index were clean at that delivery. The owner reports manual
build/test success and supplied successful cached reruns before committing.
No checks were rerun merely to associate the now-committed source. The delivery
checkpoint associates that inspected project snapshot; its parent history was
already retained, and the newly associated delivery diff was fully reviewed.
The agent made no project commit, staging, root lockfile change, reference-repo
change or system Nix replacement. The core package delivery is complete; the
active interface follow-up is described above.

Pinned Nixpkgs (5adc50831c259f87faeb09ddf930d43597197473) provides nix_2_35 at
2.35.3 with appendPatches. Package overlay adds only nix-flake-patched. The two
patches stay separate: #4811 uses an active relative SourcePath ancestor stack
(accessor and canonical flake path, root seed, RAII cleanup, new/retained nodes),
while retaining the original non-relative FlakeRef guard. #14762 uses the unchanged
C++ hunk from PR #15982, commit 3337ecd3b0ce0dea6200364ccb2afd82f43a692f, selectively
refetching kept flakes with relative inputs. Upstream release-note/test hunks are
omitted in favor of local package tests. Both patches apply independently and
together to 2.35.3. Remove fixes independently when included in a future base.

Unmodified Nix reproduces both bugs. Both single-patch full packages and the final
combined full package built successfully using upstream appendPatches; upstream
unit/functional build gates remain enabled. The final package reports
nix (Nix) 2.35.3+2. Root legacyPackages.x86_64-linux.nix-flake-patched builds to
exactly the same derivation/output as the tested combined package at original
acceptance. The old export/default-Nix equality assertions were subsequently
removed at the owner's request; current tests retain base version/type and
different-from-base assertions.

The four-full-package matrix passed 106 isolated command outcomes, including
expected baseline failures (23 baseline/setup, 16 circular-only, 27 nested-only,
40 combined). Each variant/case has private local store/state/cache and disables
registry/substituters/user config; no host daemon or remote fixtures are used.
Tests verify isolation first, then same-source/cross-source repeated relative
paths, self/two-node/dotdot-alias/absolute cycles, shared siblings, fresh nested
locking, dependency-owned/root lock reuse, nested v1-to-v2 source updates preserving
an unrelated dependency, and root-only lock recreation. All expected true cycles
produce the cycle diagnostic, not timeout/unrelated errors. A separate final audit
confirmed symlink-directory inputs are rejected identically by upstream and combined
Nix before traversal; no symlink workaround was added.

Synthetic topology models nixos -> path:./pkgs -> emarccs -> org-texmacs and
pkgs -> git-agent-workflow, repeated personal-nixpkgs -> path:./pkgs and shared
follows. Cross-source edges use local file:// tarballs. Combined package passes
local-nixpkgs -v -L, nested targeted updates and root lock recreation. Assertions
check evaluated per-directory owner trees, relative nodes' original/locked paths
and parent input paths, plus unchanged source identities by declared input path
instead of generated node names. No real NixOS/editor/GAW builds are claimed.

The complete flake check passed with --no-write-lock-file -L --max-jobs 1 --cores 2
against tmp/nix-flake-patched-source. All 9 x86_64-linux check derivations evaluate;
the new functional check ran all 106 outcomes inside the Nix build sandbox and
existing checks passed/reused their outputs. Treefmt traversed 143 files, processed
137 and changed none. Other incompatible systems were skipped, not validated.
For original acceptance, the 143-file snapshot matched the project files and
modes before and after that validation; root export build/version and diff --check
passed. Source manifest/results/logs are incidental tmp artifacts, not required
for interpreting these distilled conclusions. At original acceptance new files were untracked, so the checked snapshot
explicitly included them without agent staging. They are now owner-staged and
normal Git Flake filtering includes them.

README describes usage/temporary status/regression cost and the direct
nix-flake-patched test argument. .gitignore narrowly admits this package's patches;
the owner subsequently changed root treefmt to exclude *.patch, which was preserved. Test dependencies flow through root/test
arguments; no cross-parent fixture imports or shared-library changes were made.

Resource history: an initial process disappeared after a possible owner-reported
OOM (not proven). The combined four-version build later hit its 1800-second timeout.
The owner explicitly authorized one version at a time with --max-jobs 1 --cores 2;
all three patched complete packages then succeeded within their individual limits.
Keep these conservative resource settings for future cold builds. Earlier review
item 6 was an already-planned prerequisite, not an additional requirement.
Initial validation checkpoints omitted project parents because the tested source
was uncommitted. The committed delivery is now associated after matching its
blobs/modes to the reviewed staged source; this does not claim post-commit tests.

### Passthru follow-up: verified

The owner requested carrying both patch files and the underlying unmodified Nix
in the package passthru. package.nix now defines baseNix and the ordered patches
once, exposing passthru.baseNix/passthru.patches and the standard top-level
baseNix/patches accessors. lib.extendDerivation preserves the upstream overriding
methods and propagates this metadata to each output without changing the build.
Tests obtain their base and single-patch inputs from the package; the root no
longer duplicates patch paths. README explains the accessors and test wiring.

Evaluation confirms the package drvPath/output are exactly unchanged from original
acceptance; top-level/passthru values match, output metadata exists, and appendPatches
and overrideScope remain functions. Scoped formatting of the three Nix files and
full root nix flake check --no-write-lock-file -L --max-jobs 1 --cores 2 passed.
The regression drvPath is unchanged, so its earlier 106 successful outcomes were
reused, not rerun; only the changed treefmt check rebuilt (143 traversed, 137
processed, no changes). Other systems remain unvalidated. User staging and existing
unstaged edits were preserved; that four-file follow-up was subsequently staged
by the owner.

### Remote #14762 patch source: owner-validated

The owner requested switching the upstream-identical patch to remote fetching,
but explicitly prohibited building for this change. package.nix now uses fetchpatch
with immutable commit URL
https://github.com/NixOS/nix/commit/3337ecd3b0ce0dea6200364ccb2afd82f43a692f.patch,
name fix-nested-relative-path.patch, includes = [ "src/libflake/flake.cc" ], and
hash sha256-c9BGEKrtwRw6+y8AtALfWgwXhuydASQEwTHu851Yi70=.
The local fix-nested-relative-path.patch was removed; #4811 remains local.
README explains the source distinction. passthru.patches still supplies both
sources to the tests; no test/root patch wiring change is needed.

To obtain a real hash without a Nix build/evaluation, downloaded the immutable
commit patch (identical to the previous PR download) and copied the existing
patchutils 0.3.3 binary from cache.nixos.org using nix copy, which does not build.
The pinned Nixpkgs fetchpatch explicitly uses patchutils_0_3_3. Applied its exact
lsdiff/sorted per-file filterdiff --strip=0 --clean and final -p1 include filtering
in tmp, then SHA-256/SRI hashed the 1309-byte result. Normalizing the former local
patch yielded exactly the same C++ diff. No fake hash was used. Read-only diff
--check passed. No nix build, evaluation, formatter or regression was executed.
The owner subsequently reports having manually run the actual package build and
tests successfully, followed by supplied cached reruns of:
- nix build -v -L .#legacyPackages.x86_64-linux.nix-flake-patched: exit 0.
- nix flake check: exit 0, all checks passed, running 0 flake checks (cache hits).
The remote-source regression derivation evaluates to
a3mp3m0kszc4hnn2s12rnarmkzz43mga-nix-flake-patched-regressions.drv, distinct from
the earlier local-patch check. Thus remove the pending-validation blocker; the
fresh execution is owner-reported, while the provided repeat logs directly show
successful cached acceptance rather than a fresh 106-operation run. Other
systems were omitted and remain unvalidated. No redundant agent build/test ran.

Read-only inspection confirms the owner also refactored package.nix to accept
{ fetchpatch, lib, nix } and use nix.appendPatches; overlay.nix explicitly passes
nix = final_.nixVersions.nix_2_35. passthru.baseNix = nix; patches remain exposed.
The existing test still asserts base.version == "2.35.3". The owner subsequently
committed all 11 delivery files. Their full blob/mode identities match the reviewed
staged diff, and project status was clean then. The delivery checkpoint associates the inspected
committed state; the earlier user-run validation remains pre-commit evidence,
not an independently repeated post-commit run.

## Groups: external overlays, include/exclude and documentation committed

The owner requests groups.<name>.overlays for packages.mkOverlays: a function
list defaulting to [], applied in list order before selected local overlays and
the final export extension. Exclusion and export paths remain local-directory
based; external overlays are group-local and export collision checks remain.
Scope: pkgs/lib/packages/default.nix validation/composition plus package-suite
tests; do not change overlay-tree discovery or extraArgs. Project and memory were
clean at start. Implementation now accepts only lists of functions, preserves
per-group configuration validation and prepends config_.overlays before the local
group extension and export. No discovery, constructor or selector change was made.

Added 14 package-suite cases using inline external overlays and existing fixtures:
explicit empty-list compatibility, ordered external/local composition, prev and
final dependencies, local precedence, group isolation (including an unused
throwing overlay), external-only derivations excluded from exports, exclusions
affecting only local paths, all-local-excluded exports, default/custom export
collisions, invalid list/member types and validation of invalid sibling groups.
Existing assertions and fixtures, including independent mkChecks acceptance,
remain unchanged. Only the implementation file and tests/suites/packages/cases.nix
were changed for this delivery. The owner staged and committed this delivery as
`feat(lib.packages): support external overlays in groups`; the inspected two-file
summary agrees with the reviewed scope.

The owner authorized both exact commands: timeout 120s nix fmt --
pkgs/lib/packages/default.nix tests/suites/packages/cases.nix, and timeout 120s
nix flake check --no-write-lock-file -L. Scoped formatting passed, followed by all
8 x86_64-linux checks (reports, three real checks, treefmt). Treefmt traversed 135
files, processed 131 and changed none. Other systems were skipped. diff --check
passed; lockfile and overlay-tree source are unchanged. Validation ran against
the dirty worktree before the owner committed the reviewed implementation.

The owner requested three sequential project commits: external overlays,
include/exclude selection, then README synchronization, updating current memory
after each owner commit and checkpointing finally. All three phases are complete;
project commits were owner-operated. include defaults directly to attrNames of the
already discovered local overlays, not null or an all sentinel; select include
then remove exclude. Explicit [] selects no locals. Validate both lists and all
names against local discovery, allow duplicates, retain local name order and
group isolation. External overlays stay outside these filters; export follows
the selected local tree. Implementation filters local overlays by membership then
exclusion without changing name order. Added 18 named tests covering subset/all/
empty/duplicate selection, exclusion priority and outside-include exclusions,
external-only groups, export paths, constructor laziness, group isolation,
invalid types/names/empty directories and sibling validation. Updated the old
unknown-field test to use unknown rather than newly supported include. Separate
authorization for scoped formatting and the full flake check was granted. Both
commands passed: x86_64-linux checks succeed, other systems skipped; only package
report and treefmt needed rebuilding, all other report/check derivations unchanged
from the external-overlay delivery. The owner approved staging and committed
`feat(lib.packages): select group overlays with include and exclude`; the two-file
summary matches the reviewed scope. Its committed source is the reviewed and
formatted implementation. No checks were rerun merely to attach a parent.
README now documents both group features: all four fields/defaults, inclusion
then exclusion, validation, ordering, group isolation, external-only cases, local
export paths and collision handling. Updated the consumer example and package
suite coverage description; diff --check passed. After explicit staging approval,
the owner committed `docs(readme): explain group overlay selection and composition`.
Its full committed diff matches the reviewed documentation update. This final
checkpoint associates that inspected project snapshot, which contains both API
extensions and their tests. No project files remain staged or unstaged. Other
systems/downstream acceptance remain unverified; await the next instruction.

## Cabal project formatter: committed, awaiting next instruction

The owner added cabal-project-fmt in pkgs/modules/fp/treefmt/default.nix and
requested a commit draft, current-memory update, then waiting for project HEAD
movement. The reviewed change uses haskellPackages.cabal-fmt with
--no-cabal-file and --inplace for **/cabal*.project and **/cabal.project.local.
Drafted `feat(treefmt): add a Cabal project formatter` in tmp/commit.md from that
diff. Polling observed HEAD move from the README documentation commit to the
owner's `feat(treefmt): add a Cabal project formatter` commit. Its full committed
diff matches the reviewed formatter addition; the project worktree is clean.
This checkpoint associates that inspected project snapshot. No formatter/build/
test was run. README's formatter table has not been expanded for these project
file patterns; no README edit was requested in this task. Await next instruction.

## Shared foundation: argument function, Lisp formatters and README committed

The owner committed `feat(flake): add mkFlake with shared modules and formatting
defaults`, then `refactor(flake): extract shared foundation into a local subflake`.
Subsequent owner commits integrate package overlays, scope gitignore to the new
layout, stop loading flake-parts' modules module, move legacy-package assembly
into the subflake, and simplify mkFlake argument handling. Current source and the
complete aggregate diff from the prior associated subflake snapshot were read.
Since then the owner committed the two Lisp packages, their treefmt integration,
and `refactor(lib.mkFlake): construct arguments through a function`. The owner
prefers refactor for that interface restructuring, allows uppercase in scopes,
and chose lib.mkFlake as a precise scope. Breaking API changes still warrant a
BREAKING-CHANGE footer independently of type. The complete aggregate source diff
and resulting source were inspected, not built. The owner subsequently committed
`docs(readme): describe the shared flake foundation`; its full committed diff
matches the agent's reviewed README update. This checkpoint associates that
inspected project snapshot. The agent ran no Nix command in this work.

The root consumes local-nixpkgs at path:./pkgs, with nixpkgs, flake-parts and
treefmt-nix following the root inputs; flake.lock records that local input without
changing upstream locked revisions. pkgs/flake.nix uses native flake-parts to
assemble its lib and export mkFlake before the root flake assembles itself. Root
calls inputs.local-nixpkgs.lib.mkFlake inputs.nixpkgs and passes that input's lib
as llib and the full local-nixpkgs input as lpkgs.
The root explicitly exports mkFlake, mergeAttrsRecursive, packages and tests;
the subflake lib also contains the internal overlays entry for repository tests.

Shared code moved unchanged from lib/ to pkgs/lib/, and the treefmt module from
modules/fp/treefmt/ to pkgs/modules/fp/treefmt/. Older paths elsewhere in memory
describe pre-move implementation history; use the new paths for current source.
mkFlake's current signature is nixpkgs: argsFun: module. It calls argsFun with
{ lib = nixpkgs.lib; } and asserts that the result is an attrset containing inputs
and moduleLocation, and any explicit specialArgs is an attrset. It no longer
accepts an args attrset directly. It assembles specialArgs with lib = nixpkgs.lib
and llib/lpkgs defaulting to {}, merges caller specialArgs with later-entry
overrides, then constructs flakeArgs while removing top-level llib/lpkgs. Root
uses the argument-function protocol. README documents the API and a usage example.
It loads treefmt-nix and the local treefmt module before the caller's module;
the former automatic flake-parts modules-module import is removed. The shared
treefmt configuration enables nixfmt, shfmt, prettier, fourmolu, cabal-fmt,
xmllint, ruff-format and taplo, plus custom lisplens format for root/nested *.scm
and elisp-autofmt for root/nested *.el. It provides a formatter/default check, forces default
excludes off, derives projectRootFile from moduleLocation and treats unmatched
files as fatal. There is no nonempty-excludes assertion. Root supplies its own
exclusion list. README now uses ./pkgs/lib for direct imports and the standalone
merge-test command, and distinguishes filesystem helpers from subflake mkFlake.

pkgs/pkgs/default.nix now organizes default and legacy groups through
llib.packages.mkOverlays. The owner intends these packages for flake modules
loaded through mkFlake. The wrapper defaults perSystem.nixpkgs.overlays to the
subflake's internal default group, defines that list option and forces the
per-system pkgs argument to import the supplied nixpkgs with that overlay list.
The subflake separately applies its legacy group and exports legacyPackages by
system; it no longer exports overlays. Root forwards lpkgs.legacyPackages.${system}
rather than applying the legacy overlay itself. A temporary touchup proposal
to hide root formatter/legacyPackages was not retained in current source.

The owner removed perSystem._module.args.lib = mkForce nixpkgs.lib because module
arguments already supplied by the module system or specialArgs take precedence
over config._module.args. mkForce controls option merging, not argument-source
selection. General upstream source confirmed the args.name-or-config._module.args
fallback and perSystem's separate evalModules call; do not assume all top-level
specialArgs directly propagate into perSystem. Sources consulted (not a pinned
dependency revalidation): https://github.com/NixOS/nixpkgs/blob/master/lib/modules.nix
and https://github.com/hercules-ci/flake-parts/blob/main/modules/perSystem.nix.

An owner-run nix flake check initially failed because root's legacy group had
already added pkgs.legacyPackages and tests/suites/packages/cases.nix:realPkgs_
appended another export-enabled fixture group. The guard correctly rejected
the repeated export name. Root now passes a separately imported clean Nixpkgs
as tests' pkgs argument. tests' lib argument still comes from the enclosing
per-system pkgs.lib; no further isolation change was made. Keep fixture export
checks and independent mkChecks acceptance intact. The owner later supplied two
successful nix flake show outputs for intermediate dirty states (x86_64-linux
checks resolved to derivations, other systems omitted); exact source snapshots
were not captured. This is evaluation evidence, not successful flake-check builds
or validation of the latest commit. Runtime/build/platform validation remains open.

The four package files under pkgs/pkgs/elisp-autofmt/ and pkgs/pkgs/lisplens/ are
now committed. elisp-autofmt installs upstream scripts/config and wraps Python
with Emacs and Pygments; lisplens 0.6.0 uses buildRustPackage. Both have overlay
entries and nix-update-script. No package builds or formatter smoke tests were
performed by the agent; do not treat source inspection as runtime verification.

README was audited against the committed implementation from its prior update
through the current source. It now covers the subflake layout/outputs, mkFlake
protocol, shared formatting defaults, packages/internal groups, migrated import
paths and test-pkgs isolation while preserving independent mkChecks acceptance.
The user explicitly requested the sequence edit README, request staging approval,
wait, draft commit message, wait for owner commit, then maintain GAW. That sequence
was followed: only README.org was staged after approval, the owner committed it,
and the project worktree is clean. Read-only diff --check passed; no build/test/
format command was run. No project source or lockfile was changed by the agent.
Await the next instruction.

## Remove duplicate overlay-tree injection: both steps implemented

The owner intends to wrap flake-parts/treefmt-nix as a common project foundation,
but requested no framework plan yet. Preparatory work must remove the independent
overlay-tree import where llib is already available. The owner split implementation
into two steps, committed the first as
`refactor(lib): centralize overlay aggregation access through llib`, then requested
the second. lib/default.nix now exposes
overlays.mkOverlays through llib; flake.lib explicitly exports only
mergeAttrsRecursive, packages and tests, so this helper is not exported by the
flake. The owner requires explicit exports rather than exclusion filtering.
flake.nix no longer imports or injects overlayTree through specialArgs.
The first commit included a temporary checks adapter, overlayTree = llib.overlays,
which kept the old tests entry compatible until the second step.

The owner committed the second step as
`test(lib): use llib for generic overlay aggregation tests`; its complete five-file
committed diff matches the reviewed implementation. tests/default.nix accepts
only llib, lib and pkgs, its scope no longer carries overlayTree, and the generic
overlay suite uses llib.overlays.mkOverlays for all nine calls. Removed the flake
adapter and synchronized README's tests entry signature. Fixtures, call arguments
and assertions are unchanged. Independent mkChecks acceptance in tests/test-api.nix
and the three real checks in tests/test-checks.nix are untouched; directChecks_
and the exact output-name guard remain at the root. The owner explicitly requires
tests/ to continue separately testing the test-assembly function. Do not replace
generic aggregation with packages.mkOverlays, which adds domain rules and lacks
implicitOverlays. Read-only diff review and git diff --check passed; no formatting,
evaluation, build or test was run. Runtime equivalence remains unverified.
The subsequent mkFlake wrapper and subflake delivery is described above.

## Package aggregation refactor: implemented and validated

The owner requested implementation of the reviewed package aggregation plan and
continuous GAW maintenance. See `memory/package-groups.md` for the adopted
contract, implementation and validation evidence. mkOverlays now supports groups
and directory-selected exports using one lazy description tree, including TeX
selection; public mkLegacyPackages is removed. Full flake checks and treefmt passed
on x86_64-linux against a source-only snapshot including untracked fixtures; all
128 snapshot files were compared with the current worktree and matched. Other
systems and downstream builds were not tested. The owner committed all 15 changed
files as `feat(lib): unify package aggregation with overlay groups`, with a
breaking-change footer for old API removal. All 128 committed file blobs and modes
match the reviewed, validated source snapshot exactly, and the project worktree
is clean. This checkpoint associates that inspected project commit. Validation
ran before commit against identical content; no checks were rerun solely for
provenance. No lockfile or consumer change was made. Await the next objective.

## Project purpose

This repository is a personal nixpkgs: a shared foundation for flake-based
projects to consume as an input where needed. Its adopted description is
`Personal nixpkgs`. Shared functions and a flake-parts/treefmt-nix mkFlake wrapper
are implemented; package overlay assembly, concrete Lisp packages and their
formatter integration are committed as described above.

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

`lib.packages` exposes `mkOverlays`, `mkNixosModule` and
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

The committed constructor implementation has 217 named cases on x86_64-linux:
43 merge, 62 packages (including six real package-set evaluations), 51 generic
overlays and 61 tests API cases. The committed checks-only baseline had 184.
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
The constructor implementation passed scoped nix fmt and
`timeout 120s nix flake check --no-write-lock-file --show-trace` after source
migration and the final fixture correction on x86_64-linux. All reports, three
real checks and treefmt passed; other systems were skipped. The merge report
and three real check drvPaths are unchanged, while overlay/package/API reports
reflect additional assertions. No lockfile or downstream repository changed.
See `memory/parameterized-overlays.md` for constructor implementation evidence and
`memory/overlay-tests-design.md` for the committed tests-side API history.
The owner committed it as `feat(lib): add parameterized overlay constructors`.
All 117 committed file blobs and modes match the reviewed index snapshot exactly;
the project worktree was clean on inspection. Validation ran before commit
against the same content, with no post-commit test rerun. This checkpoint
associates the inspected constructor commit. That constructor delivery is complete;
the subsequent package refactor is described above. Broader package-set/runtime
work remains deferred.

## Package-side design boundary

The owner considered moving overlay application into mkLegacyPackages,
passing external overlay inputs, retaining discovery metadata and exporting
an entire extended pkgs as legacyPackages. That proposal was initially deferred.
The owner later adopted the bounded groups/export design in
`memory/package-groups.md`, now committed and validated. Export only
directory-selected packages from final, not an entire extended package set;
keep mkOverlays public and remove mkLegacyPackages. No public selector/tree API
or inferred pkgs parameter was introduced.

## Overlay constructors: committed and validated

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
The later groups/export redesign is described in `memory/package-groups.md`.

The owner requested implementation and authorized staging/formatting/checks.
The implementation provides recursive selective injection and unknown-name errors,
public forwarding, 49 mechanical source migrations, 19 new fixture files and
33 new cases. TeX is wrapped at registration; extraction, namespace algorithms
and test scope semantics are unchanged. Runtime validation remains limited to
constructor argument names, with return shapes verified only by tests as chosen.

The first check found strict final destructuring recursing during fixed-point
assembly. That fixture now uses a concrete final value; this is ordinary Nix
strictness, not a restriction or workaround in the aggregator. After correction,
217 cases, three real checks and treefmt passed on x86_64-linux. README records
the source-protocol migration and the fixed-point caveat. All 74 intended paths
were committed by the owner. Complete committed-tree comparison matched the
reviewed 117-file index snapshot, with a clean worktree. This checkpoint
associates that commit; the preceding tests ran before commit against identical
content. No implementation work remains in this scope.

## Built-in aggregation rules: implemented and validated

Read `memory/package-aggregation-rules.md` for the contract and implementation
outcome. Root-child-name defaults now provide Emacs and TeX Live rules, with
explicit overlay precedence and unchanged generic scope,
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
supplies implicit Emacs/TeX rules and a directory-capturing selector. The current
constructor implementation adds mkOverlays.extraArgs; extraction/module algorithms
remain unchanged. Namespace diagnostics use
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

Do not copy the associated project's type/scope into a GAW checkpoint by habit.
For a current-memory maintenance and handoff checkpoint, use a message such as
`chore(memory): record shared foundation handoff`; the checkpoint does not itself
refactor lib.mkFlake. The owner reverted the incorrectly classified checkpoint
and requested recreation with this corrected classification.

Checkpoint consequential findings and completed phases when they have recovery
value. Do not defer a warranted checkpoint merely because the owner did not
separately request one; the normal GAW memory loop is already authorized.
