''
  import json
  import os
  from pathlib import Path
  import stat
  import subprocess
  import sys
  import tempfile
  import time

  command, faulty, emacs, semantics, output = sys.argv[1:]
  results = {}
  process_count = 0
  suite_started = time.perf_counter()

  def run_process(args, **kwargs):
      global process_count
      process_count += 1
      return subprocess.run(args, capture_output=True, timeout=15, **kwargs)

  def require(condition, message):
      if not condition:
          raise AssertionError(message)

  def snapshot(path):
      info = path.stat()
      return path.read_bytes(), stat.S_IMODE(info.st_mode), info.st_mtime_ns, info.st_ino

  def invoke(root, args, expected, fault=None, diagnostic=None, home=None):
      env = os.environ.copy()
      env.pop("ORG_FMT_TEST_FAILURE", None)
      if fault:
          env["ORG_FMT_TEST_FAILURE"] = fault
      if home:
          env["HOME"] = str(home)
      proc = run_process([faulty if fault else command, *args], cwd=root, env=env)
      require(proc.returncode == expected,
              f"exit {proc.returncode}, expected {expected}: {proc.stderr!r}")
      if diagnostic:
          require(diagnostic.encode() in proc.stderr,
                  f"missing diagnostic {diagnostic!r}: {proc.stderr!r}")
      return proc

  def phase(name, test):
      started = time.perf_counter()
      print(f"START {name}", flush=True)
      try:
          return test()
      finally:
          print(f"END {name} ({time.perf_counter() - started:.3f}s)", flush=True)

  def fixture_batch(cases):
      errors = {}

      def verify(name, test):
          try:
              test()
          except Exception as error:
              errors.setdefault(name, str(error))

      try:
          with tempfile.TemporaryDirectory(prefix="org-fmt-fixtures-") as directory:
              root = Path(directory)
              rows = []
              for index, (name, data, expected) in enumerate(cases):
                  path = root / f"input-{index}.org"
                  original = root / f"original-{index}.org"
                  path.write_bytes(data)
                  original.write_bytes(data)
                  rows.append((name, data, expected, path, original))
              paths = [str(row[3]) for row in rows]
              original_snapshots = {row[4]: snapshot(row[4]) for row in rows}

              phase("fixtures: format", lambda: invoke(root, ["--", *paths], 0))
              actual = {row[3]: row[3].read_bytes() for row in rows}
              for name, data, expected, path, original in rows:
                  if expected is not None:
                      verify(name, lambda path=path, expected=expected:
                             require(actual[path] == expected,
                                     f"actual {actual[path]!r}, expected {expected!r}"))

              def compare_semantics():
                  # A known mismatch must be reported without hiding later pairs.
                  negative = root / "semantic-negative.org"
                  negative.write_text("* Deliberately different heading\n")
                  pairs = [str(path) for row in rows for path in (row[4], row[3])]
                  proc = run_process([emacs, "--batch", "-Q", "--script", semantics,
                                      str(rows[0][4]), str(negative), *pairs], cwd=root)
                  require(proc.returncode == 0, f"semantic helper failed: {proc.stderr!r}")
                  comparisons = json.loads(proc.stdout)
                  require(set(comparisons) == set(paths) | {str(negative)},
                          "missing/unexpected semantic results")
                  require(isinstance(comparisons[str(negative)], str)
                          and comparisons[str(negative)].startswith("Semantic mismatch"),
                          "semantic helper accepted a changed heading")
                  negative.unlink()
                  for name, data, expected, path, original in rows:
                      verify(name, lambda path=path:
                             require(comparisons[str(path)] is True,
                                     f"{comparisons[str(path)]}"))
              phase("fixtures: semantics", compare_semantics)

              formatted = {path: snapshot(path) for path in map(Path, paths)}
              for label, args in (("idempotence", ["--", *reversed(paths)]),
                                  ("formatted check", ["--check", "--", *paths])):
                  phase("fixtures: " + label, lambda args=args: invoke(root, args, 0))
                  for name, data, expected, path, original in rows:
                      verify(name, lambda path=path, label=label:
                             require(snapshot(path) == formatted[path],
                                     f"{label} modified bytes or metadata"))

              needs_formatting = set()
              for name, data, expected, path, original in rows:
                  path.write_bytes(data)
                  if data != actual[path]:
                      needs_formatting.add(str(path))
              before = {Path(path): snapshot(Path(path)) for path in paths}
              proc = phase("fixtures: original check", lambda: invoke(
                  root, ["--check", "--", *paths], 1 if needs_formatting else 0))
              prefix = "org-fmt: needs formatting: "
              reported = [line.removeprefix(prefix) for line in proc.stderr.decode().splitlines()
                          if line.startswith(prefix)]
              require(set(reported) <= set(paths), "check reported an unknown file")
              for name, data, expected, path, original in rows:
                  def check_original(path=path, original=original):
                      require(reported.count(str(path)) == int(str(path) in needs_formatting),
                              "incorrect per-file check classification")
                      require(snapshot(path) == before[path], "--check modified input")
                      require(snapshot(original) == original_snapshots[original],
                              "original comparison copy modified")
                  verify(name, check_original)
              require(set(root.iterdir()) == {path for row in rows for path in row[3:]},
                      "temporary file leaked")
      except Exception as error:
          for name, data, expected in cases:
              errors.setdefault(name, str(error))

      for name, data, expected in cases:
          results[name] = errors.get(name, True)
          print(f"FAIL {name}: {errors[name]}" if name in errors else f"PASS {name} (batched)",
                flush=True)

  golden = [
      ("adjacent-empty-headlines", b"* A\n\n\n* B\n\n** Child\n\n",
       b"* A\n* B\n** Child\n"),
      ("body-blank-lines", b"* A\n\nFirst.\n\n\nSecond.\n\n\n* B\n",
       b"* A\nFirst.\n\n\nSecond.\n\n\n* B\n"),
      ("leading-drawer", b"* A\n\n:LOGBOOK:\n- Note\n:END:\n\n\nBody.\n",
       b"* A\n:LOGBOOK:\n- Note\n:END:\nBody.\n"),
      ("source-indentation", b"* A\n\n#+begin_src nix\n{ pkgs }:\n  pkgs.hello\n#+end_src\n",
       b"* A\n#+begin_src nix\n  { pkgs }:\n    pkgs.hello\n#+end_src\n"),
  ]
  complex_cases = {
      "empty": "",
      "blank-file": "\n\n",
      "no-final-newline": "* Heading\n\nText",
      "crlf-unicode": "* 标题\r\n\r\n中文 café λ.\r\n",
      "title-todo-tags": "#+TODO: TODO NEXT WAIT | DONE CANCELED\n* NEXT [#A] *Bold* /italic/ [[https://example.org][link]] :tag:other:\n\n** \n\n*** Child\n",
      "planning-properties": "* DONE Task\nCLOSED: [2026-10-29 Thu 12:30] SCHEDULED: <2026-10-30 Fri 09:00 +1w> DEADLINE: <2026-11-02 Mon -2d>\n:PROPERTIES:\n:ID: abc-123\n:CUSTOM_ID: task\n:OWNER: 张三\n:END:\n\n:LOGBOOK:\n- State DONE from TODO\n:END:\n\n:NOTES:\nHeading notes.\n:END:\n\nBody.\n",
      "leading-drawer-gaps": "* A\n\n:ONE:\nFirst.\n:END:\n\n\n:TWO:\nSecond.\n:END:\n\nBody.\n",
      "body-drawer": "* A\nParagraph.\n\n:NOTES:\nBody drawer.\n:END:\n\n\nAfter.\n",
      "nested-lists": "* Lists\n- [X] first\n  continuation\n\n  - nested one\n  - nested two\n- [ ] second\n\n\nAfter list.\n\n1. ordered\n2. [@4] counter\n\nTerm list:\n- key :: value\n",
      "footnotes": "* Notes\nReference [fn:one] and [fn::inline note].\n\n[fn:one] First paragraph.\n\n    Second paragraph.\n\n\nAfter definition.\n",
      "table-affiliations": "* Table\n#+NAME: samples\n#+CAPTION: A *bold* caption\n#+ATTR_HTML: :class sample\n#+ATTR_LATEX: :align lr\n| Name | Value |\n|------+-------|\n| a    |     1 |\n#+TBLFM: $2=1\n",
      "source-languages": "* Code\n#+NAME: python-example\n#+HEADER: :results output\n#+begin_src python :var x=1\ndef f(x):\n    return x + 1\n#+end_src\n\n#+begin_src sh\nprintf '%s\\n' 'hello world'\n#+end_src\n\n#+begin_src unknown-language\n  untouched relative indent\n    deeper\n#+end_src\n",
      "source-preserved-indent": "* Code\n#+begin_src python -i :preserve-indent yes\n   first\n      second\n#+end_src\n\n#+begin_src python :preserve-indent yes\n    a = 1\n        b = 2\n#+end_src\n",
      "source-org-escaping": "* Code\n#+begin_src org\n,* Nested headline\n,#+end_src\n#+end_src\n",
      "export-example-blocks": "* Blocks\n#+begin_export html\n<div>\n  <span>λ</span>\n</div>\n#+end_export\n\n#+begin_example\n  verbatim\n    indentation\n#+end_example\n",
      "unknown-special-block": "* TeXmacs\n#+NAME: equation\n#+begin_texmacs\n<TeXmacs|2.1.4>\n<with|mode|math|<frac|a+b|c>>\n\n<document|a|b>\n#+end_texmacs\n\n#+begin_custom-box\nOrdinary *Org* text.\n\n- a\n- b\n#+end_custom-box\n",
      "metadata-and-preamble": "#+TITLE: Test\n#+AUTHOR: Example\n#+PROPERTY: header-args :eval never\n\nPreamble.\n\n* A\n\nText with \\alpha, =code=, ~verbatim~, and [[file:other.org][a link]].\n",
  }

  def record(name, test):
      started = time.perf_counter()
      print(f"START {name}", flush=True)
      try:
          with tempfile.TemporaryDirectory(prefix="org-fmt-test-") as directory:
              test(Path(directory))
          results[name] = True
          print(f"PASS {name} ({time.perf_counter() - started:.3f}s)", flush=True)
      except Exception as error:
          results[name] = str(error)
          print(f"FAIL {name}: {error}", flush=True)

  cases = list(golden)
  cases.extend((name, text.encode(), None) for name, text in complex_cases.items())
  fixture_batch(cases)

  def cli(root):
      for args in ([], ["--check"], ["--"], ["--unknown"]):
          invoke(root, args, 2, diagnostic="org-fmt:")
      for args in (["--help"], ["-h"]):
          proc = invoke(root, args, 0)
          require(b"Usage:" in proc.stdout, "missing help")
      for name in ("space name.org", "中文.org", "-leading.org"):
          path = root / name
          path.write_text("* A\n\nBody.\n")
          invoke(root, ["--check", "--", name], 1)
          invoke(root, ["--", name], 0)
          invoke(root, ["--check", "--", name], 0)
      path = root / "--unknown"
      path.write_text("* A\n\nBody.\n")
      before = snapshot(path)
      invoke(root, ["--unknown"], 2, diagnostic="org-fmt:")
      require(snapshot(path) == before, "unknown flag treated as a writable filename")
  record("cli-arguments-paths", cli)

  def mixed(root):
      a, b = root / "a.org", root / "b.org"
      for path in (a, b):
          path.write_text("* A\n\nBody.\n")
      before = snapshot(a), snapshot(b)
      invoke(root, ["--check", "a.org", "missing", "b.org"], 2)
      require((snapshot(a), snapshot(b)) == before, "mixed check wrote files")
      invoke(root, ["a.org", "missing", "b.org"], 2)
      require(a.read_bytes() == b.read_bytes() == b"* A\nBody.\n",
              "failed file prevented subsequent processing")
      invoke(root, ["--check", "a.org", "b.org"], 0)
      b.write_text("* B\n\nText.\n")
      invoke(root, ["--check", "a.org", "b.org"], 1)
  record("multi-file-error-precedence", mixed)

  def safety(root):
      path = root / "input.org"
      path.write_text("* A\n\nBody.\n")
      path.chmod(0o640)
      invoke(root, ["input.org"], 0)
      require(stat.S_IMODE(path.stat().st_mode) == 0o640, "permissions changed")
      before = snapshot(path)
      invoke(root, ["input.org"], 0)
      require(snapshot(path) == before, "unchanged file rewritten")
      link = root / "link.org"
      link.symlink_to(path)
      for mode in ([], ["--check"]):
          invoke(root, [*mode, "link.org"], 2, diagnostic="symbolic link")
          require(link.is_symlink() and snapshot(path) == before, "symlink target changed")
          invoke(root, [*mode, "missing"], 2, diagnostic="not a regular file")
          invoke(root, [*mode, "."], 2, diagnostic="not a regular file")
      require(set(p.name for p in root.iterdir()) == {"input.org", "link.org"},
              "temporary file leaked")
  record("permissions-noop-links-file-errors", safety)

  def isolated_configuration(root):
      home = root / "home"
      (home / ".emacs.d").mkdir(parents=True)
      for init in (home / ".emacs", home / ".emacs.d" / "init.el"):
          init.write_text('(error "interactive configuration must not be loaded")\n')
      path = root / "input.org"
      path.write_text("* A\n\nBody.\n")
      invoke(root, ["input.org"], 0, home=home)
      require(path.read_bytes() == b"* A\nBody.\n", "configuration affected output")
  record("isolated-user-configuration", isolated_configuration)

  for operation in ("org-element-interpret-data", "make-nearby-temp-file",
                    "write-region", "set-file-modes", "rename-file"):
      def fault_case(root, operation=operation):
          path = root / "input.org"
          path.write_text("* A\n\nBody.\n")
          path.chmod(0o640)
          before = snapshot(path)
          invoke(root, ["input.org"], 2, fault=operation, diagnostic="injected")
          require(snapshot(path) == before, "failure changed original bytes or metadata")
          require([p.name for p in root.iterdir()] == ["input.org"], "failed temp cleanup")
          if operation != "org-element-interpret-data":
              invoke(root, ["--check", "input.org"], 1, fault=operation)
              require(snapshot(path) == before, "check mode reached writeback")
          invoke(root, ["input.org"], 0, fault="none")
      record("failure-" + operation, fault_case)

  failed = [name for name, result in results.items() if result is not True]
  print(f"org-fmt: {len(results) - len(failed)}/{len(results)} passed; "
        f"{process_count} Emacs processes; {time.perf_counter() - suite_started:.3f}s",
        flush=True)
  if failed:
      raise SystemExit("failed: " + ", ".join(failed))
  Path(output).mkdir()
  (Path(output) / "results.json").write_text(json.dumps(results, indent=2) + "\n")
''
