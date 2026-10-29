''
  import itertools
  import json
  import os
  from pathlib import Path
  import stat
  import subprocess
  import sys
  import tempfile

  command, faulty, output = sys.argv[1:]
  header = b"*\n*/\n"
  results = {}

  def require(condition, message):
      if not condition:
          raise AssertionError(message)

  def invoke(root, args, expected, diagnostic=None, fault=None):
      scratch = root / "tmp"
      scratch.mkdir(exist_ok=True)
      env = os.environ.copy()
      env["TMPDIR"] = str(scratch)
      env.pop("GITIGNORE_FMT_FAIL", None)
      if fault:
          env["GITIGNORE_FMT_FAIL"] = fault
      proc = subprocess.run(
          [faulty if fault else command, *args], cwd=root, env=env,
          stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10,
      )
      require(proc.returncode == expected,
              f"exit {proc.returncode}, expected {expected}: {proc.stderr!r}")
      if diagnostic:
          require(diagnostic.encode() in proc.stderr,
                  f"missing diagnostic {diagnostic!r}: {proc.stderr!r}")
      require(not list(scratch.iterdir()), "workspace not cleaned up")
      require(not list(root.glob("*.gitignore-fmt.*")), "replacement not cleaned up")
      return proc

  def snapshot(path):
      info = path.stat()
      return (path.read_bytes(), info.st_mode, info.st_mtime_ns, info.st_ino)

  def golden(root, data, expected):
      path = root / "input"
      path.write_bytes(data)
      before = snapshot(path)
      invoke(root, ["--check", "input"], 0 if data == expected else 1)
      require(snapshot(path) == before, "check mode modified input")
      invoke(root, ["input"], 0)
      require(path.read_bytes() == expected,
              f"actual {path.read_bytes()!r}, expected {expected!r}")
      formatted = snapshot(path)
      invoke(root, ["input"], 0)
      require(snapshot(path) == formatted, "second format was not a no-op")
      invoke(root, ["--check", "input"], 0)
      require(snapshot(path) == formatted, "formatted check changed input")

  # Expected bytes are specified independently of the implementation.
  cases = [
      ("empty", b"", header),
      ("only-blank-lines", b"\n\n\n", header),
      ("complete-header", header, header),
      ("star-only", b"*\n", header),
      ("directory-only", b"*/\n", header),
      ("reversed-header", b"*/\n*\n", header),
      ("missing-header", b"!foo\n", header + b"\n!/foo\n"),
      ("already-anchored", b"!/foo\n", header + b"\n!/foo\n"),
      ("three-sections", b"*/\n*\n!z\n!a\nz\na\n",
       header + b"\n!/a\n!/z\n\na\nz\n"),
      ("directory-groups", b"!z/child\n!a/nested/file\n!root\n!a/\n!z/\n",
       header + b"\n!/root\n\n!/a/\n!/a/nested/file\n\n!/z/\n!/z/child\n"),
      ("glob-directory", b"!src/\n!**/*.nix\n!root\n!**/\n",
       header + b"\n!/root\n\n!/**/\n!/**/*.nix\n\n!/src/\n"),
      ("attached-comment", b"# z\n!z\n# a\n!a\n",
       header + b"\n# a\n!/a\n# z\n!/z\n"),
      ("multiple-comments", b"# one\n# two\n!foo\n",
       header + b"\n# one\n# two\n!/foo\n"),
      ("detached-comment", b"!z\n# barrier\n\n!a\n",
       header + b"\n!/z\n\n# barrier\n\n!/a\n"),
      ("eof-comment", b"!foo\n# tail", header + b"\n!/foo\n\n# tail\n"),
      ("comments-only", b"# one\n# two\n", header + b"\n# one\n# two\n"),
      ("header-comment", b"# header\n*\n*/\n!a\n",
       header + b"\n# header\n\n!/a\n"),
      ("blank-lines", b"\n*\n\n*/\n\n\n!a\n\n!b\n\n",
       header + b"\n!/a\n!/b\n"),
      ("missing-final-lf", b"!foo", header + b"\n!/foo\n"),
      ("crlf", b"*\r\n*/\r\n!foo\r\n# end\r\n",
       header + b"\n!/foo\n\n# end\n"),
      ("escaped-markers", b"\\!foo\n\\#foo\n",
       header + b"\n\\!foo\n\\#foo\n"),
      ("wildcards", b"!*.nix\n!file[ab]?\n!src/**/\n*.tmp\n",
       header + b"\n!/*.nix\n!/file[ab]?\n\n!/src/**/\n\n*.tmp\n"),
      ("spaces", b"!file\\ name\n!trail\\ \n  literal  \n",
       header + b"\n!/file\\ name\n!/trail\\ \n\n  literal  \n"),
      ("tabs", b"!file\tname\n", header + b"\n!/file\tname\n"),
      ("duplicate-rules", b"# first\n!a\n# second\n!a\nfoo\nfoo\n",
       header + b"\n# first\n!/a\n# second\n!/a\n\nfoo\nfoo\n"),
      ("non-ascii", "!é\n!a\n".encode(), header + "\n!/a\n!/é\n".encode()),
  ]

  def run_test(name, fn):
      try:
          with tempfile.TemporaryDirectory(prefix="case-", dir=".") as directory:
              fn(Path(directory).resolve())
          results[name] = True
      except Exception as error:
          results[name] = False
          print(f"FAIL {name}: {error}", file=sys.stderr)

  for name, data, expected in cases:
      run_test(name, lambda root, data=data, expected=expected: golden(root, data, expected))

  invalid = [
      ("duplicate-star", b"*\n*\n", "duplicate * header"),
      ("duplicate-directory", b"*/\n*/\n", "duplicate */ header"),
      ("negation-after-ignore", b"foo\n!bar\n", "invalid section order"),
      ("header-after-negation", b"!foo\n*\n", "invalid section order"),
      ("header-after-ignore", b"foo\n*/\n", "invalid section order"),
      ("empty-negation", b"!\n", "empty negation"),
      ("empty-negation-path", b"!/\n", "empty negation path"),
      ("record-separator", b"!a\x1fb\n", "unsupported control character"),
      ("comment-separator", b"# a\x1fb\n", "unsupported control character"),
      ("nul", b"!a\x00b\n", "unsupported NUL byte"),
  ]

  def invalid_case(root, data, diagnostic):
      path = root / "input"
      path.write_bytes(data)
      before = snapshot(path)
      for args in (["input"], ["--check", "input"]):
          invoke(root, args, 2, diagnostic)
          require(snapshot(path) == before, "invalid input changed")

  for name, data, diagnostic in invalid:
      run_test(name, lambda root, data=data, diagnostic=diagnostic:
               invalid_case(root, data, diagnostic))

  def permutations(root):
      for ordering in itertools.permutations([b"!z/", b"!root", b"!a/"]):
          golden(root, b"\n".join(ordering) + b"\n",
                 header + b"\n!/root\n\n!/a/\n\n!/z/\n")

  run_test("input-permutations", permutations)

  def file_paths(root):
      for name, args in [
          ("space name", ["space name"]),
          ("-name", ["--", "-name"]),
          ("--check", ["--", "--check"]),
      ]:
          path = root / name
          path.write_bytes(b"!a\n")
          invoke(root, args, 0)
          require(path.read_bytes() == header + b"\n!/a\n", "path not formatted")

  run_test("file-paths", file_paths)

  def cli_errors(root):
      for args in ([], ["--check"], ["--"], ["--unknown"]):
          invoke(root, args, 2, "Usage:")
      invoke(root, ["absent"], 2, "not a regular file")
      (root / "directory").mkdir()
      invoke(root, ["directory"], 2, "not a regular file")

  run_test("cli-errors", cli_errors)

  def symlinks(root):
      target = root / "target"
      target.write_bytes(b"!a\n")
      link = root / "link"
      link.symlink_to(target)
      before = snapshot(target)
      invoke(root, ["link"], 2, "symbolic links")
      require(link.is_symlink() and snapshot(target) == before, "symlink target changed")

  run_test("symlink-rejection", symlinks)

  def mode_preserved(root):
      path = root / "input"
      path.write_bytes(b"!a\n")
      path.chmod(0o640)
      invoke(root, ["input"], 0)
      require(stat.S_IMODE(path.stat().st_mode) == 0o640, "permissions changed")

  run_test("mode-preserved", mode_preserved)

  def multiple(root):
      a, b, bad = (root / name for name in ("a", "b", "bad"))
      a.write_bytes(b"!z\n")
      b.write_bytes(b"!a\n")
      bad.write_bytes(b"!\n")
      invoke(root, ["a", "bad", "b"], 2, "empty negation")
      require(a.read_bytes() == header + b"\n!/z\n", "first file skipped")
      require(b.read_bytes() == header + b"\n!/a\n", "later file skipped")
      require(bad.read_bytes() == b"!\n", "invalid file changed")
      invoke(root, ["a", "b"], 0)
      a.write_bytes(b"!z\n")
      before = {p: snapshot(p) for p in (a, b, bad)}
      invoke(root, ["--check", "a", "b"], 1)
      invoke(root, ["--check", "a", "bad", "b"], 2, "empty negation")
      invoke(root, ["--check", "bad", "a"], 2, "empty negation")
      require(all(snapshot(p) == state for p, state in before.items()), "multi-check wrote files")

  run_test("multiple-files-and-statuses", multiple)

  def injected_failure(root, fault):
      path = root / "input"
      path.write_bytes(b"!z\n!a\n")
      before = snapshot(path)
      # Writeback commands must not be reached at all in check mode.
      check_status = 1 if fault in ("cat", "cp-preserve", "mv", "mktemp-replacement") else 2
      invoke(root, ["--check", "input"], check_status, fault=fault)
      require(snapshot(path) == before, "failed check changed the original")
      invoke(root, ["input"], 2, fault.split("-")[0], fault=fault)
      require(snapshot(path) == before, "operation failure damaged the original")

  for fault in ("sort", "cmp", "cat", "cp", "cp-preserve", "mv", "mktemp", "mktemp-replacement", "mkdir"):
      run_test("failure-" + fault, lambda root, fault=fault: injected_failure(root, fault))

  Path(output).write_text(json.dumps(results, indent=2) + "\n")
  print(f"gitignore-fmt: {sum(results.values())}/{len(results)} tests passed")
  if not all(results.values()):
      sys.exit(1)
''
