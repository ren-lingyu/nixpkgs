# Native BibTeX acceptance experiment

Executed on 2026-11-12 with the root project's locked Nixpkgs, TeXmacs 2.1.5,
and the current treefmt-wrapper/BibTeX configuration. No org-texmacs or Emacs
test driver was used. Formal project test wiring was not changed.

## Reproduction

Run from this directory:

```sh
timeout 120s nix build --no-link --no-write-lock-file --print-out-paths -L \
  'path:.#checks.x86_64-linux.default'
```

This independent flake obtains the actual formatter from the project Git flake
input. It writes no lockfile. The Nix build result includes the original and
formatted BibTeX files, native trees, logs, and summary.json. A successful build
means the observation experiment completed; deliberately malformed controls are
not required to fail. See the recorded observations before defining formal tests.

The first run fetched TeXmacs from the binary cache (39.8 MiB download, 97.5 MiB
unpacked). It completed within the 120-second outer timeout. All native probes ran
headlessly in three processes with isolated HOME/TEXMACS_HOME_PATH.

## Observations

Eight positive groups were tested: basic BibTeX, UTF-8, math, string macros,
multiline values, duplicate/empty fields, crossrefs, and the combined nine-key
fixture. All eight passed both before and after formatting:

- Native parse returned a document with exactly the independently expected keys.
- plain, alpha, and abbrv each generated the expected number of bibitem* nodes
  and all expected probe-prefixed citation labels.
- The formatted files were byte-identical after a second formatter pass.

The native probe ran 25 parse calls and 75 style-format calls across positive
groups and controls, without starting a new TeXmacs process for each call.

| Control | parse returned document | Expected keys/items/labels | Meaning |
| --- | --- | --- | --- |
| Empty input | No | Fail | No expected entry remains. |
| Plain text | Yes | Fail | A document result alone can be just a recovered comment. |
| Remove one of two entries | Yes | Fail | Expected-key checks detect entry loss. |
| Rename citation key | Yes | Fail | Expected-key checks detect a broken citation identity. |
| Duplicate citation key | Yes | Fail | Exact multiplicity detects ambiguity, even though TeXmacs itself renders both. |
| Missing closing braces | Yes | Pass | Native recovery accepts the entry and formats its title. |
| Missing field equals sign | Yes | Pass | Native recovery retains an entry with no fields; bibliography contains only its item/label. |
| Empty title | Yes | Pass | Content validity is outside this acceptance predicate. |
| Valid two-entry counterpart | Yes | Pass | Confirms the entry-loss control starts from a working baseline. |

Native logs contain explicit conversion errors for some malformed controls,
despite successful return values. The missing-brace control also demonstrates
why log scanning alone is not a complete syntax validator.

Evidence copied here for review:

- summary.json: all measured predicates.
- original-results/: original parse/style trees and native log.
- control-results/: control parse/style trees and native log.

For example, the missing-equals control produced:

```scheme
(document
  (bib-entry "book" "Basic2026" (document))
  (bib-comment (document "{Broken},year={2026}}")))
```

plain still generated a bibliography item and label for Basic2026.

## Assessment

The native test has concrete but bounded value: it exercises the real consumer
and detects entry loss, changed/ambiguous citation keys, and native style failures
for curated originally accepted fixtures. It does not establish strict BibTeX
syntax validity or preservation of every field's meaning. Recovery is part of
what TeXmacs accepts; a recovered malformed control need not fail the owner's
operational acceptance criterion.

A small permanent compatibility test could retain fixed expected keys, item and
label checks, and at least one native style. The three styles provide additional
style-path coverage, not three independent syntax validators. Parser no-exception
or document-shape checks alone are too weak. No PDF rendering is needed for the
specific parser/bibliography acceptance contract measured here.

There is still no full org-texmacs export verification. The experiment covers its
shared native parser and style core without depending on its implementation.
Keep generic formatter tests separate; decide whether this native regression
coverage justifies the extra TeXmacs dependency before formal integration.
