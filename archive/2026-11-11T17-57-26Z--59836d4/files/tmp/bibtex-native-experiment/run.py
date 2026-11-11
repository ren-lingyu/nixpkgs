import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

texmacs, formatter, probe, complex_fixture, destination = sys.argv[1:]
out = Path(destination)
work = Path("work").resolve()
work.mkdir()
original = work / "original"
formatted = work / "formatted"
controls = work / "controls"
for directory in (original, formatted, controls):
    directory.mkdir()

basic = '@book{Basic2026,title={An example},author={Doe, Jane},year={2026},publisher={Example Press}}\n'
fixtures = {
    "basic": (basic, ["Basic2026"]),
    "unicode": ('@book{Unicode2026,title={中文 café — naïve},author={García, José},year={2026}}\n', ["Unicode2026"]),
    "math": (r'@book{Math2026,title={Study of $\alpha_i$ and $\frac{a}{b}$ with {NASA}},author={Example, Ada},year={2026}}' + "\n", ["Math2026"]),
    "strings": ('@string{JournalName="Journal"}\n@article{Macros2026,title={Macros},author={Example, Ada},journal=JournalName # { Supplement},year=2026,month=jan}\n', ["Macros2026"]),
    "multiline": ('@misc{Multiline2026,title={First\n second},note={Paragraph one.\n\nParagraph two.},year={2026}}\n', ["Multiline2026"]),
    "duplicate-fields": ('@misc{Duplicate2026,title={Duplicates},note={A},note={B},howpublished={},year={2026}}\n', ["Duplicate2026"]),
    "crossref": ('@book{Parent2026,title={Collection},editor={Example, Ada},publisher={Example Press},year={2026}}\n@incollection{Child2026,title={Child},author={Doe, Jane},crossref={Parent2026},year={2026}}\n', ["Parent2026", "Child2026"]),
    "complex": (Path(complex_fixture).read_text(encoding="utf-8"), ["Basic2026", "Unicode2026", "Math2026", "Macros2026", "Multiline2026", "Duplicate2026", "Parent2026", "Child2026", "Verbatim2026"]),
}
for name, (text, _) in fixtures.items():
    (original / f"{name}.bib").write_text(text, encoding="utf-8")
    (formatted / f"{name}.bib").write_text(text, encoding="utf-8")

second = '@book{Second2026,title={Second},author={Other, Alex},year={2026}}\n'
damaged = {
    "empty": ("", ["Basic2026"], "no bibliography remains"),
    "plain-text": ("This is not a bibliography.\n", ["Basic2026"], "no bibliography syntax"),
    "missing-braces": ('@book{Basic2026,title={Unclosed', ["Basic2026"], "unclosed value and entry"),
    "missing-equals": ('@book{Basic2026,title {Broken},year={2026}}\n', ["Basic2026"], "invalid field assignment"),
    "removed-entry": (basic, ["Basic2026", "Second2026"], "one expected entry removed"),
    "renamed-key": (basic.replace("Basic2026", "Changed2026"), ["Basic2026"], "citation key changed"),
    "duplicate-key": (basic + basic, ["Basic2026"], "citation key became ambiguous"),
    "empty-title": ('@book{Basic2026,title={},author={Doe, Jane},year={2026}}\n', ["Basic2026"], "content change; not necessarily rejected"),
    "valid-two-entries": (basic + second, ["Basic2026", "Second2026"], "positive control for entry removal"),
}
for name, (text, _, _) in damaged.items():
    (controls / f"{name}.bib").write_text(text, encoding="utf-8")

def native(phase, directory, cases):
    result_dir = out / phase
    result_dir.mkdir()
    manifest = work / f"{phase}-manifest.scm"
    manifest.write_text("(" + " ".join(json.dumps(name) for name in cases) + ")\n")
    home = work / f"{phase}-home"
    home.mkdir()
    env = os.environ.copy()
    env.update(HOME=str(home), TEXMACS_HOME_PATH=str(home / "texmacs"),
               QT_QPA_PLATFORM="offscreen", PROBE_ROOT=str(directory),
               PROBE_OUT=str(result_dir), PROBE_MANIFEST=str(manifest))
    command = [texmacs, "-H", "-s", "-x", f"(load {json.dumps(probe)})"]
    completed = subprocess.run(command, env=env, cwd=work, stdin=subprocess.DEVNULL,
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               text=True, timeout=45)
    (result_dir / "native.log").write_text(completed.stdout)
    if completed.returncode or not (result_dir / "COMPLETE").exists():
        print(completed.stdout, flush=True)
        raise RuntimeError(f"{phase}: native probe did not complete ({completed.returncode})")
    observations = {}
    for line in (result_dir / "observations.tsv").read_text().splitlines():
        name, operation, status, shape, values = line.split("\t")
        observations.setdefault(name, {})[operation] = {
            "status": status, "shape_or_count": shape,
            "keys_or_labels": values.split(",") if values else [],
        }
    return observations

before = native("original", original, fixtures)
format_command = [formatter, "--tree-root", str(formatted), "--walk", "filesystem", "--no-cache"]
subprocess.run(format_command, stdin=subprocess.DEVNULL, check=True)
after = native("formatted", formatted, fixtures)
negative = native("controls", controls, damaged)

def acceptance(observation, expected):
    parsed = observation.get("parse", {})
    parse_ok = parsed.get("status") == "no-exception" and parsed.get("shape_or_count") == "document"
    key_ok = sorted(parsed.get("keys_or_labels", [])) == sorted(expected)
    styles = {}
    for style in ("plain", "alpha", "abbrv"):
        result = observation.get(style, {})
        styles[style] = (result.get("status") == "no-exception"
                         and result.get("shape_or_count") == str(len(expected))
                         and sorted(result.get("keys_or_labels", [])) == sorted("probe-" + key for key in expected))
    return {"parse_returns_document": parse_ok, "expected_keys_match": key_ok,
            "styles_and_labels": styles, "strong_oracle": parse_ok and key_ok and all(styles.values())}

summary = {"positive": {}, "controls": {}}
for name, (_, expected) in fixtures.items():
    summary["positive"][name] = {"before": acceptance(before[name], expected), "after": acceptance(after[name], expected)}
for name, (_, expected, reason) in damaged.items():
    summary["controls"][name] = {"mutation": reason, "observed": acceptance(negative[name], expected)}

once = {path.name: path.read_bytes() for path in formatted.glob("*.bib")}
subprocess.run(format_command, stdin=subprocess.DEVNULL, check=True)
summary["formatter_idempotent"] = once == {path.name: path.read_bytes() for path in formatted.glob("*.bib")}
shutil.copytree(original, out / "original-bib")
shutil.copytree(formatted, out / "formatted-bib")
(out / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n")
print(json.dumps(summary, ensure_ascii=False, indent=2), flush=True)
# This experiment records observations; malformed controls are not required to fail.
print("EXPERIMENT COMPLETE: inspect results before defining any formal acceptance test", flush=True)
