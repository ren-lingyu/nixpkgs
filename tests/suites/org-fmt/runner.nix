''
  import json
  import os
  from pathlib import Path
  import stat
  import subprocess
  import sys
  import tempfile

  command, faulty, emacs, semantics, document_list, output = sys.argv[1:]
  results = {}

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
      proc = subprocess.run([faulty if fault else command, *args], cwd=root,
                            env=env, capture_output=True, timeout=15)
      require(proc.returncode == expected,
              f"exit {proc.returncode}, expected {expected}: {proc.stderr!r}")
      if diagnostic:
          require(diagnostic.encode() in proc.stderr,
                  f"missing diagnostic {diagnostic!r}: {proc.stderr!r}")
      return proc

  def semantic_equal(root, before, after):
      proc = subprocess.run([emacs, "--batch", "-Q", "--script", semantics,
                             str(before), str(after)], cwd=root,
                            capture_output=True, timeout=15)
      require(proc.returncode == 0,
              f"semantic comparison failed: {proc.stdout!r}\n{proc.stderr!r}")

  def fixture(root, data, expected=None):
      path = root / "input.org"
      path.write_bytes(data)
      original = root / "original.org"
      original.write_bytes(data)
      invoke(root, ["input.org"], 0)
      actual = path.read_bytes()
      if expected is not None:
          require(actual == expected, f"actual {actual!r}, expected {expected!r}")
      semantic_equal(root, original, path)
      formatted = snapshot(path)
      invoke(root, ["input.org"], 0)
      require(snapshot(path) == formatted, "second format rewrote file or changed bytes")
      invoke(root, ["--check", "input.org"], 0)
      require(snapshot(path) == formatted, "formatted --check modified file")
      path.write_bytes(data)
      before = snapshot(path)
      invoke(root, ["--check", "input.org"], 0 if data == actual else 1)
      require(snapshot(path) == before, "--check modified unformatted file")
      require(set(p.name for p in root.iterdir()) == {"original.org", "input.org"},
              "temporary file leaked")

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
      try:
          with tempfile.TemporaryDirectory(prefix="org-fmt-test-") as directory:
              test(Path(directory))
          results[name] = True
      except Exception as error:
          results[name] = str(error)
          print(f"FAIL {name}: {error}", flush=True)

  for name, data, expected in golden:
      record(name, lambda root, data=data, expected=expected: fixture(root, data, expected))
  for name, text in complex_cases.items():
      record(name, lambda root, text=text: fixture(root, text.encode()))
  for name, source in json.loads(Path(document_list).read_text()).items():
      record("document-" + name,
             lambda root, source=source: fixture(root, Path(source).read_bytes()))

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
  print(f"org-fmt: {len(results) - len(failed)}/{len(results)} passed", flush=True)
  if failed:
      raise SystemExit("failed: " + ", ".join(failed))
  Path(output).mkdir()
  (Path(output) / "results.json").write_text(json.dumps(results, indent=2) + "\n")
''
