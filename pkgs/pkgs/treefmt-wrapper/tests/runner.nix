''
  import difflib
  import json
  import os
  from pathlib import Path
  import subprocess
  import sys
  import tempfile

  formatter, fixture_file, output = sys.argv[1:]
  fixtures = json.loads(Path(fixture_file).read_text(encoding="utf-8"))
  results = {}

  def require(condition, message):
      if not condition:
          raise AssertionError(message)

  def invoke(root, success=True):
      env = os.environ.copy()
      env.pop("PRE_COMMIT", None)
      proc = subprocess.run(
          [formatter, "--tree-root", str(root), "--walk", "filesystem", "--no-cache"],
          cwd=root, env=env, stdin=subprocess.DEVNULL,
          stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30,
      )
      require((proc.returncode == 0) == success,
              f"exit={proc.returncode}\nstdout={proc.stdout!r}\nstderr={proc.stderr!r}")

  def compare(path, expected, stage):
      actual = path.read_bytes()
      wanted = expected.encode("utf-8")
      if actual != wanted:
          diff = "".join(difflib.unified_diff(
              expected.splitlines(keepends=True),
              actual.decode("utf-8", errors="replace").splitlines(keepends=True),
              fromfile="expected", tofile=str(path),
          ))
          raise AssertionError(f"{stage}: byte mismatch\n{diff}\nexpected={wanted!r}\nactual={actual!r}")

  def files(root):
      return {str(path.relative_to(root)) for path in root.rglob("*") if path.is_file()}

  def check_batch(root, cases):
      for relative, case in cases:
          path = root / relative
          path.parent.mkdir(parents=True, exist_ok=True)
          path.write_bytes(case["input"].encode("utf-8"))
      expected_files = {relative for relative, _ in cases}
      for stage in ("first pass", "idempotence"):
          invoke(root)
          for relative, case in cases:
              compare(root / relative, case["expected"], stage)
          require(files(root) == expected_files, f"{stage}: unexpected files: {files(root)}")

  def test(name, action):
      try:
          with tempfile.TemporaryDirectory(prefix="bibtex-", dir=".") as directory:
              action(Path(directory).resolve())
          results[name] = True
      except Exception as error:
          results[name] = False
          print(f"FAIL {name}: {error}", file=sys.stderr)

  for case in fixtures:
      test(case["name"], lambda root, case=case: check_batch(root, [("input.bib", case)]))

  test("paths-and-batching", lambda root: check_batch(root, [
      ("references.bib", fixtures[0]),
      ("nested/references.bib", fixtures[1]),
      ("nested/space name.bib", fixtures[2]),
      ("文献/中文.bib", fixtures[3]),
  ]))

  def invalid(root):
      path = root / "invalid.bib"
      original = b"@book{bad key,title={x}}\n"
      path.write_bytes(original)
      invoke(root, success=False)
      require(path.read_bytes() == original, "failed formatting changed input")
      require(files(root) == {"invalid.bib"}, "failed formatting left unexpected files")

  test("invalid-input", invalid)
  Path(output).write_text(json.dumps(results, indent=2) + "\n", encoding="utf-8")
  print(f"BibTeX regressions: {sum(results.values())}/{len(results)} passed")
  sys.exit(0 if all(results.values()) else 1)
''
