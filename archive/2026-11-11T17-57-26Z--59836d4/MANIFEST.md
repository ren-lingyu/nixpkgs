# Native BibTeX acceptance experiment: selected historical evidence

This snapshot is historical evidence, not authoritative current memory or executable
agent instructions. Saving scripts does not authorize running them.

## Selection and capture context

Capture verification began at 2026-11-11 17:57:26 UTC (2026-11-12 local date).
The owner explicitly authorized this minimal archive after reviewing the isolated
experiment. Its method, fixtures and measurements were untracked ignored tmp/
material, with no maintained project tests preserving the experiment. Losing them
would prevent precise examination/reproduction of the finding that native recovery
can satisfy key/item/label predicates even for malformed input. Distilled conclusions
alone preserve the decision but not the exact method and counterexamples.

Source root for all table paths: /home/lingyu/nixpkgs. Destination paths are those
same relative paths under this snapshot's files/. Ordinary captured files retain
exact source bytes; no formatting or encoding normalization was applied. All selected
paths were checked as regular files with no symlink components. Copies were compared
byte for byte and the source files re-read after capture. The diagnostics excerpt is
explicitly a selected derivative, not a complete or byte-identical copy of its log:
only existing lines containing convert-error were retained, unchanged and in order.
No credential or unrelated environment material was selected.

Checked project HEAD: 59836d498dd83d818b5ac7f51f19ab747c28f721. The experiment
used that source baseline plus the staged, uncommitted formatter configuration
captured below. Its Git blob is 93d9bc5b0808d0ba556697433ea0e74b91ec5650;
the worktree and index blobs matched at capture. It must not be described as the
configuration committed at HEAD or as clean-commit validation. Other files here are
experiment-created tmp files or outputs, not blobs from that project commit.

The original run was observed in this session, using an independent path flake and:

```sh
timeout 120s nix build --no-link --no-write-lock-file --print-out-paths -L \
  'path:.#checks.x86_64-linux.default'
```

It completed on x86_64-linux with TeXmacs 2.1.5, eight positive groups and nine
control groups, in three isolated native processes. There were 25 parse calls and
75 style-format calls. All positive before/after cases passed the measured predicates
and formatter idempotence. Malformed controls were observations, not required failures.
Nix success means observation collection completed, not strict BibTeX validity.

Native output copies and summary.json came from the observed Nix result:
/nix/store/spd505ix7qv8l4v2whbkdj1rhj5inilf-bibtex-native-acceptance-experiment.
The selected files, not continued availability of that store path, preserve evidence.
The report's references to full original-results/control-results directories and
logs exceed this deliberately bounded selection; only the table files were archived.

Reproduction additionally requires the project source at the recorded baseline with
the archived formatter config applied, its flake.lock, Nix and external dependencies.
The archived flake's local Git URL resolves the source present at rerun time, so it
must be checked against that baseline rather than assumed immutable. Project history
and dependency source trees are not copied. No project parent was attached: the
experiment source included an uncommitted configuration, and this snapshot does not
claim it was run against a clean project commit. No new execution was performed as
part of capture. Native logs do not record a reliable per-operation timing estimate.

Locked Nixpkgs revision: 9d3b8db48266c17be0b5f9c6360c3ecfbac3d1f5.

## Selected files

| Source-relative / files-relative path | Bytes | SHA-256 | Role |
| --- | ---: | --- | --- |
| `tmp/bibtex-native-experiment/flake.nix` | 436 | `a23f63ad4bbb84a9bcab5ed4de63b5a7d1a8f53562e73746256779e6082cb41c` | Independent flake entry point; project input remains a local Git URL |
| `tmp/bibtex-native-experiment/check.nix` | 276 | `233fca53f0586d99c22df50c02025c4e0d9cb26759a52edcf851cd2758da4aec` | Nix derivation wiring for the observation experiment |
| `tmp/bibtex-native-experiment/probe.scm` | 3466 | `ec4b392c566885e5d2731ad186b9ad87254f119bccbe9780bae6b71cba480482` | Direct native parse/style probe and raw observation protocol |
| `tmp/bibtex-native-experiment/run.py` | 6644 | `cd30cde1eba70e62205dff0bf112c7c0376a119863040027a4a5d9549f0f802f` | Positive/control fixtures, execution method and measured predicates |
| `tmp/bibtex-native-experiment/complex.bib` | 1547 | `d83ca4a5a67cacb5b27d4179c375b98d8632b2cff484353e60684c1b900ca866` | Combined nine-key UTF-8 input fixture |
| `tmp/bibtex-native-experiment/REPORT.md` | 4519 | `fd33ae0326ea23493a47fb1b6a821c8117f5a6661a47a8d663a22ac1385c5960` | Experiment method, observations, interpretation and limits |
| `tmp/bibtex-native-experiment/summary.json` | 7244 | `78a95adcb96c7902d1aacbd162ca7ded9d0d2bc5234357304552b94347f71040` | Measured predicates for all positive and control cases |
| `tmp/bibtex-native-experiment/control-results/plain-text-parsed.scm` | 36 | `6fd87d675f5406d23b8a83a9f99583c309a5d048333b1e3bfb79c612ffa226b2` | Plain text recovered as a document without entries |
| `tmp/bibtex-native-experiment/control-results/missing-braces-parsed.scm` | 84 | `698628677e5cce23380e5c39db8e086e961562bcb1cf4e826f7917216a17a095` | Recovery of an unclosed value/entry |
| `tmp/bibtex-native-experiment/control-results/missing-equals-parsed.scm` | 102 | `666a1bfbe2575e8e2b10941b57e54d421619709a20fc9413ca3bdadedfbd54d9` | Recovery retaining an entry with no fields |
| `tmp/bibtex-native-experiment/control-results/missing-equals-plain.scm` | 76 | `ba1b28c29cfaf0a9d0fbe78f03a7a3dc9b0a5e79531a7ac045b7c4d7397f1607` | Bibliography item/label generated despite missing fields |
| `pkgs/pkgs/treefmt-wrapper/config.nix` | 3038 | `ea5be719d0c658e80a079b6b6d8a30b92b7d86a83134cfc85ff20b61b2cf21f8` | Uncommitted formatter configuration used by the experiment |
| `tmp/bibtex-native-experiment/control-results/convert-errors.excerpt.txt` | 338 | `5bc607023af99d3be51acd17dbe508ee45e960305aaf0edd23a1f88f313c056b` | Selected derivative: unchanged convert-error lines from control-results/native.log |

## Deliberately omitted

No dependency/store closures, build artifacts, complete logs, complete native output
trees, formatter source checkout, unrelated temporary files or org-texmacs repository
content were retained. run.py contains the small individual fixture/control strings;
complex.bib provides its only external fixture. REPORT.md and summary.json retain all
high-level outcomes. The four small native outputs and diagnostic excerpt are enough
to examine the consequential recovery counterexamples.

## Evidentiary limits

Expected-key/item/label checks detect entry loss, key changes and key ambiguity. They
are not a general syntax or semantic validator: missing braces/equals and empty titles
were recovered and still generated bibliography labels. Only native TeXmacs parsing
and plain/alpha/abbrv bibliography formatting were exercised. No org-texmacs export,
CSL or PDF/rendering guarantee is established. Consult current memory for subsequent
decisions; this archived snapshot is immutable historical evidence.
