# Fixed UTF-8 input/output pairs verified with TeXmacs 2.1.5 in the isolated
# native experiment. This is output regression coverage, not a compatibility proof.
# Do not regenerate expected values during tests or refresh them without review.
[
  {
    name = "basic";
    input = "@book{Basic2026,title={An example},author={Doe, Jane},year={2026},publisher={Example Press}}\n";
    expected = "@book{Basic2026,\n  title         = {An example},\n  author        = {Doe, Jane},\n  year          = {2026},\n  publisher     = {Example Press}\n}\n";
  }
  {
    name = "unicode";
    input = "@book{Unicode2026,title={中文 café — naïve},author={García, José},year={2026}}\n";
    expected = "@book{Unicode2026,\n  title         = {中文 café — naïve},\n  author        = {García, José},\n  year          = {2026}\n}\n";
  }
  {
    name = "math";
    input = "@book{Math2026,title={Study of $\\alpha_i$ and $\\frac{a}{b}$ with {NASA}},author={Example, Ada},year={2026}}\n";
    expected = "@book{Math2026,\n  title         = {Study of $\\alpha_i$ and $\\frac{a}{b}$ with {NASA}},\n  author        = {Example, Ada},\n  year          = {2026}\n}\n";
  }
  {
    name = "strings";
    input = "@string{JournalName=\"Journal\"}\n@article{Macros2026,title={Macros},author={Example, Ada},journal=JournalName # { Supplement},year=2026,month=jan}\n";
    expected = "@string{JournalName=\"Journal\"}\n\n@article{Macros2026,\n  title         = {Macros},\n  author        = {Example, Ada},\n  journal       = JournalName # { Supplement},\n  year          = 2026,\n  month         = jan\n}\n";
  }
  {
    name = "multiline";
    input = "@misc{Multiline2026,title={First\n second},note={Paragraph one.\n\nParagraph two.},year={2026}}\n";
    expected = "@misc{Multiline2026,\n  title         = {First second},\n  note          = {\n    Paragraph one.\n\n    Paragraph two.\n  },\n  year          = {2026}\n}\n";
  }
  {
    name = "duplicate-fields";
    input = "@misc{Duplicate2026,title={Duplicates},note={A},note={B},howpublished={},year={2026}}\n";
    expected = "@misc{Duplicate2026,\n  title         = {Duplicates},\n  note          = {A},\n  note          = {B},\n  howpublished  = {},\n  year          = {2026}\n}\n";
  }
  {
    name = "crossref";
    input = "@book{Parent2026,title={Collection},editor={Example, Ada},publisher={Example Press},year={2026}}\n@incollection{Child2026,title={Child},author={Doe, Jane},crossref={Parent2026},year={2026}}\n";
    expected = "@book{Parent2026,\n  title         = {Collection},\n  editor        = {Example, Ada},\n  publisher     = {Example Press},\n  year          = {2026}\n}\n\n@incollection{Child2026,\n  title         = {Child},\n  author        = {Doe, Jane},\n  crossref      = {Parent2026},\n  year          = {2026}\n}\n";
  }
  {
    name = "complex";
    input = "% UTF-8 compatibility fixture. These citation keys are intentionally ASCII.\n@string{CompatJournal = \"Journal of Compatibility\"}\n@preamble{\"\\newcommand{\\CompatMacro}{A}\"}\n@comment{Formatter compatibility fixture}\n\n@ARTICLE(Basic2026,\nTitle=\"A quoted title with {NASA}\",\nAuthor={Doe, Jane and Example, Ada},\nyear=\"2026\",\njournal={Example Journal},\npages={12 - 14},\n)\n\n@article{Unicode2026,\nauthor={García, José and 王, 小明},\ntitle={中文标题与 UTF-8 café — naïve},\nyear={2026},\njournal={Unicode Journal}\n}\n\n@book{Math2026,\nauthor={Example, Ada},\ntitle={Study of $\\alpha_i$ and $\\frac{a}{b}$ with {NASA}},\nyear={2026},\npublisher={Example Press}\n}\n\n@article{Macros2026,\nauthor={Example, Ada},\ntitle={A macro-based entry},\njournal=CompatJournal # { Supplement},\nyear=2026,\nmonth=jan\n}\n\n@misc{Multiline2026,\ntitle={A multiline\n  title with protected {API}},\nnote={First paragraph.\n\n  Second paragraph.},\nyear={2026}\n}\n\n@misc{Duplicate2026,\ntitle={Repeated and empty fields},\nnote={First note},\nnote={Second note},\nhowpublished={},\nyear={2026}\n}\n\n@book{Parent2026,\neditor={Example, Ada},\ntitle={Collected Examples},\npublisher={Example Press},\nyear={2026}\n}\n\n@incollection{Child2026,\nauthor={Doe, Jane},\ntitle={A child entry},\nbooktitle={Collected Examples},\ncrossref={Parent2026},\npages={20--30},\nyear={2026}\n}\n\n@misc{Verbatim2026,\ntitle={Paths, URLs, and escaped text},\nurl={https://example.invalid/paper?id=1&part=a_b},\ndoi={10.0000/example_test},\nfile={papers/example_file.pdf},\nnote={An escaped \\& and protected {Title}},\nyear={2026}\n}\n";
    expected = "% UTF-8 compatibility fixture. These citation keys are intentionally ASCII.\n@string{CompatJournal = \"Journal of Compatibility\"}\n\n@preamble{\"\\newcommand{\\CompatMacro}{A}\"}\n\n@comment{Formatter compatibility fixture}\n@ARTICLE{Basic2026,\n  Title         = \"A quoted title with {NASA}\",\n  Author        = {Doe, Jane and Example, Ada},\n  year          = \"2026\",\n  journal       = {Example Journal},\n  pages         = {12--14}\n}\n\n@article{Unicode2026,\n  author        = {García, José and 王, 小明},\n  title         = {中文标题与 UTF-8 café — naïve},\n  year          = {2026},\n  journal       = {Unicode Journal}\n}\n\n@book{Math2026,\n  author        = {Example, Ada},\n  title         = {Study of $\\alpha_i$ and $\\frac{a}{b}$ with {NASA}},\n  year          = {2026},\n  publisher     = {Example Press}\n}\n\n@article{Macros2026,\n  author        = {Example, Ada},\n  title         = {A macro-based entry},\n  journal       = CompatJournal # { Supplement},\n  year          = 2026,\n  month         = jan\n}\n\n@misc{Multiline2026,\n  title         = {A multiline title with protected {API}},\n  note          = {\n    First paragraph.\n\n    Second paragraph.\n  },\n  year          = {2026}\n}\n\n@misc{Duplicate2026,\n  title         = {Repeated and empty fields},\n  note          = {First note},\n  note          = {Second note},\n  howpublished  = {},\n  year          = {2026}\n}\n\n@book{Parent2026,\n  editor        = {Example, Ada},\n  title         = {Collected Examples},\n  publisher     = {Example Press},\n  year          = {2026}\n}\n\n@incollection{Child2026,\n  author        = {Doe, Jane},\n  title         = {A child entry},\n  booktitle     = {Collected Examples},\n  crossref      = {Parent2026},\n  pages         = {20--30},\n  year          = {2026}\n}\n\n@misc{Verbatim2026,\n  title         = {Paths, URLs, and escaped text},\n  url           = {https://example.invalid/paper?id=1&part=a_b},\n  doi           = {10.0000/example_test},\n  file          = {papers/example_file.pdf},\n  note          = {An escaped \\& and protected {Title}},\n  year          = {2026}\n}\n";
  }
]
