# Current project state

## Objective and decisions

The owner is reviving this repository to provide cross-repository Nix functions
and shared conventions. Its former NUR packaging responsibilities became
obsolete after all packaging moved to `~/nixos.git`, according to the owner.
Use **obsolete**, matching `nur_obsolete`, when describing that retired role.

The new function interfaces, packaging shape and shared conventions have not
been designed or implemented. The next implementation task needs its own scope.

## Evidence and limits

Read `memory/obsolete-nur.md` for the completed review of the old NUR snapshot.
At this baseline, the project worktree is on a new, independent `main` history
containing `.gitignore` and `LICENSE`. An empty untracked `README.org` was
observed and left untouched. These are observations, not instructions to
restore or modify those files.

Only local repository history was examined. The migration destination was not
read, remote refs were not refreshed, and no Nix evaluation, build or test was
run. Migration completeness and historical buildability remain unverified.

## Memory organization

`memory/current.md` holds the current objective, adopted decisions, limits and
next action. `memory/obsolete-nur.md` holds the old NUR review and its rationale.
Project entry skills describe how to read this memory, without summarizing its
contents, and must be committed in separate checkpoints from memory changes.

## Next action

Clarify the intended cross-repository API and conventions when the owner starts
that implementation task. Consult the old implementation only where relevant;
its preservation does not adopt its design for the revived repository.
