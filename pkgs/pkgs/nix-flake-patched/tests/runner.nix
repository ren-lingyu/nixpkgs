''
  import collections
  import json
  import os
  from pathlib import Path
  import subprocess
  import sys
  import tarfile

  fixture_spec = json.loads(Path(sys.argv[1]).read_text())
  binaries = dict(zip(["baseline", "circular", "nested", "combined"], sys.argv[2:6]))
  variants = sys.argv[7:] or list(binaries)
  output = Path(sys.argv[6])
  work = Path.cwd() / "cases"
  work.mkdir()
  results = []

  class Case:
      def __init__(self, name):
          self.root = work / name
          self.root.mkdir()
          self.env = os.environ.copy()
          for key, value in {
              "NIX_REMOTE": "local",
              "NIX_STORE_DIR": str(self.root / "store"),
              "NIX_STATE_DIR": str(self.root / "state"),
              "NIX_LOG_DIR": str(self.root / "log"),
              "NIX_CONF_DIR": str(self.root / "conf"),
              "NIX_USER_CONF_FILES": "/dev/null",
              "NIX_CONFIG": "",
              "NIX_PATH": "",
              "XDG_CACHE_HOME": str(self.root / "cache"),
              "XDG_CONFIG_HOME": str(self.root / "user-config"),
          }.items():
              self.env[key] = value
          self.sources = self.root / "sources"
          self.sources.mkdir()
          self.commands = 0

      def run(self, variant, *args, failure=None):
          command = [
              binaries[variant], "--extra-experimental-features", "nix-command flakes",
              "--option", "build-users-group", "", "--option", "substituters", "",
              "--option", "flake-registry", "", "--option", "accept-flake-config", "false",
              "--option", "eval-cache", "false",
              *map(str, args),
          ]
          proc = subprocess.run(command, env=self.env, text=True, capture_output=True, timeout=120)
          self.commands += 1
          log = self.root / f"command-{self.commands}.log"
          log.write_text(json.dumps(command) + "\n" + proc.stdout + proc.stderr)
          if failure is None:
              assert proc.returncode == 0, f"{command}\n{proc.stdout}\n{proc.stderr}"
          else:
              assert proc.returncode != 0, f"expected {failure}, succeeded: {command}"
              if failure == "cycle":
                  assert "found circular import" in proc.stderr, proc.stderr
              elif failure == "source":
                  assert "subflake" in proc.stderr and "flake.nix" in proc.stderr, proc.stderr
                  assert "does not exist" in proc.stderr or "No such file" in proc.stderr, proc.stderr
              else:
                  assert "found circular import" in proc.stderr or (
                      "pkgs/flake.nix" in proc.stderr and "does not exist" in proc.stderr
                  ), proc.stderr
          results.append({"case": self.root.name, "variant": variant,
                          "operation": list(map(str, args[:2])), "expected": failure or "success",
                          "exitCode": proc.returncode})
          return proc.stdout

      def archive(self, source, name):
          path = self.root / (name.replace("/", "-") + ".tar.gz")
          with tarfile.open(path, "w:gz") as archive:
              archive.add(source, arcname="source")
          return path.as_uri()

      def archive_url(self, name):
          return (self.root / (name.replace("/", "-") + ".tar.gz")).as_uri()

      def lock(self, variant, root, *inputs, failure=None):
          verbose = ["-v", "-L"] if inputs == ("local-nixpkgs",) else []
          result = self.run(variant, "flake", "update", *inputs, *verbose,
                            "--flake", f"path:{root}", failure=failure)
          results[-1]["inputUpdates"] = list(inputs)
          return result

      def evaluate(self, variant, root, expected, fresh=False):
          lock = root / "flake.lock"
          saved = lock.read_bytes() if fresh and lock.exists() else None
          if saved is not None:
              lock.unlink()
          try:
              actual = json.loads(self.run(variant, "eval", "--json", "--no-write-lock-file",
                                           f"path:{root}#tree"))
              assert actual == expected, (actual, expected)
          finally:
              if saved is not None:
                  lock.write_bytes(saved)

  def flake(path, owner, inputs=None, follows=None, overrides=None):
      path.mkdir(parents=True, exist_ok=True)
      inputs = inputs or {}
      lines = ["{"]
      for name, url in inputs.items():
          lines.append(f"inputs.{name}.url = {json.dumps(url)};")
      for name, target in (follows or {}).items():
          lines.append(f"inputs.{name}.inputs.nixpkgs.follows = {json.dumps(target)};")
      for name, url in (overrides or {}).items():
          lines.append(f"inputs.{name}.url = {json.dumps(url)};")
      children = " ".join(f"{name} = inputs.{name}.tree;" for name in inputs)
      lines.append("outputs = inputs: { tree = { owner = " + json.dumps(owner)
                   + "; inputs = { " + children + " }; }; }; }")
      (path / "flake.nix").write_text("\n".join(lines) + "\n")

  def tree(owner, **inputs):
      return {"owner": owner, "inputs": inputs}

  def verify_lock(root, expected, relative_owners):
      lock = json.loads((root / "flake.lock").read_text())
      nodes = lock["nodes"]

      def resolve(link):
          if isinstance(link, str):
              return link
          node = lock["root"]
          for name in link:
              node = resolve(nodes[node]["inputs"][name])
          return node

      def visit(node_name, value, prefix):
          node = nodes[node_name]
          assert set(node.get("inputs", {})) == set(value["inputs"]), (node, value)
          for name, child in value["inputs"].items():
              link = node["inputs"][name]
              child_name = resolve(link)
              child_node = nodes[child_name]
              if child["owner"] in relative_owners:
                  path = relative_owners[child["owner"]]
                  assert child_node["original"] == {"type": "path", "path": path}, child_node
                  assert child_node["locked"] == {"type": "path", "path": path}, child_node
                  assert child_node["parent"] == prefix, (child_node, prefix)
              visit(child_name, child, prefix + [name])

      visit(lock["root"], expected, [])

  def lock_sources(root):
      # Compare source identities by input path, never generated node names.
      lock = json.loads((root / "flake.lock").read_text())
      nodes = lock["nodes"]

      def resolve(link):
          if isinstance(link, str):
              return link
          node = lock["root"]
          for name in link:
              node = resolve(nodes[node]["inputs"][name])
          return node

      sources = {}

      def visit(node_name, prefix):
          node = nodes[node_name]
          for name, link in node.get("inputs", {}).items():
              child_name = resolve(link)
              child = nodes[child_name]
              path = prefix + [name]
              sources["/".join(path)] = {
                  key: child[key] for key in ("locked", "original", "parent") if key in child
              }
              visit(child_name, path)

      visit(lock["root"], [])
      return sources

  # Prove that the child process really uses its private store before treating
  # any command failure as a regression baseline.
  for variant in variants:
      case = Case("isolation-" + variant)
      store = case.run(variant, "eval", "--raw", "--expr", "builtins.storeDir")
      assert store == str(case.root / "store"), store
      root = case.sources / "empty"
      flake(root, "empty")
      case.lock(variant, root)
      case.evaluate(variant, root, tree("empty"))

  # #4811: repeated relative input strings in a single source tree.
  for variant in variants:
      case = Case("repeated-" + variant)
      root = case.sources / "root"
      flake(root, "root", {"child": "path:./pkgs"})
      flake(root / "pkgs", "child", {"child": "path:./pkgs"})
      flake(root / "pkgs/pkgs", "leaf")
      expected = tree("root", child=tree("child", child=tree("leaf")))
      fixed = variant in ("circular", "combined")
      case.lock(variant, root, failure=None if fixed else "cycle")
      if fixed:
          verify_lock(root, expected, {"child": "./pkgs", "leaf": "./pkgs"})
          case.evaluate(variant, root, expected, fresh=True)
          if variant == "combined":
              case.lock(variant, root)
              case.evaluate(variant, root, expected)

  # The same relative path in distinct source accessors is also non-cyclic.
  for variant in variants:
      case = Case("cross-source-" + variant)
      root = case.sources / "root"
      library = case.sources / "library"
      flake(library, "library", {"child": "path:./pkgs"})
      flake(library / "pkgs", "library-child")
      url = case.archive(library, "library")
      flake(root, "root", {"child": "path:./pkgs"})
      flake(root / "pkgs", "root-child", {"library": url})
      expected = tree("root", child=tree("root-child", library=tree(
          "library", child=tree("library-child"))))
      fixed = variant in ("circular", "combined")
      case.lock(variant, root, failure=None if fixed else "cycle")
      if fixed:
          verify_lock(root, expected, {"root-child": "./pkgs", "library-child": "./pkgs"})
          case.evaluate(variant, root, expected, fresh=True)

  # Cycles must terminate with the cycle diagnostic, never by a timeout.
  for variant in variants:
      for name, refs in {
          "self": ["path:."],
          "two-node": ["path:./a", "path:.."],
          "alias": ["path:./a", "path:../a/.."],
      }.items():
          case = Case(f"cycle-{name}-{variant}")
          root = case.sources / "root"
          flake(root, "root", {"child": refs[0]})
          if len(refs) == 2:
              flake(root / "a", "child", {"child": refs[1]})
          case.lock(variant, root, failure="cycle")

      case = Case("cycle-absolute-" + variant)
      root = case.sources / "root"
      flake(root, "root", {"child": f"path:{root}"})
      case.lock(variant, root, failure="cycle")

  # Siblings may legitimately share a relative target; the stack is not a
  # global visited set. A plain three-layer initial lock also works unpatched.
  for variant in variants:
      case = Case("shared-" + variant)
      root = case.sources / "root"
      flake(root, "root", {"left": "path:./shared", "right": "path:./shared"})
      flake(root / "shared", "shared")
      expected = tree("root", left=tree("shared"), right=tree("shared"))
      case.lock(variant, root)
      verify_lock(root, expected, {"shared": "./shared"})
      case.evaluate(variant, root, expected)

  # #14762: top -> middle -> library -> relative subflake. middle carries
  # a baseline-generated lock, so library must enter the kept-node branch.
  for seeded in (False, True):
      for variant in variants:
          case = Case(f"nested-{'seeded' if seeded else 'fresh'}-{variant}")
          library = case.sources / "library"
          middle = case.sources / "middle"
          top = case.sources / "top"
          flake(library / "subflake", "subflake-v1")
          flake(library, "library-v1", {"subflake": "path:./subflake"})
          library_url = case.archive(library, "library-v1")
          flake(middle, "middle", {"library": library_url})
          if seeded:
              case.lock("baseline", middle)
          middle_url = case.archive(middle, "middle")
          unrelated = case.sources / "unrelated"
          flake(unrelated, "unrelated")
          unrelated_url = case.archive(unrelated, "unrelated")
          top_inputs = {"middle": middle_url, "unrelated": unrelated_url}
          flake(top, "top", top_inputs)
          expected = tree("top", middle=tree("middle", library=tree(
              "library-v1", subflake=tree("subflake-v1"))), unrelated=tree("unrelated"))
          fixed = not seeded or variant in ("nested", "combined")
          case.lock(variant, top, failure=None if fixed else "source")
          if not fixed:
              continue
          verify_lock(top, expected, {"subflake-v1": "./subflake"})
          case.evaluate(variant, top, expected, fresh=not seeded)
          if variant not in ("nested", "combined"):
              continue
          # Root lock reuse, selected nested updates and root-only recreation.
          case.lock(variant, top, "middle/library")
          case.evaluate(variant, top, expected)
          (top / "flake.lock").unlink()
          case.lock(variant, top)
          case.evaluate(variant, top, expected)
          # Update a nested dependency to genuinely different source contents.
          flake(library / "subflake", "subflake-v2")
          flake(library, "library-v2", {"subflake": "path:./subflake"})
          new_url = case.archive(library, "library-v2")
          unchanged = lock_sources(top)["unrelated"]
          flake(top, "top", top_inputs,
                overrides={"middle.inputs.library": new_url})
          case.lock(variant, top, "middle/library")
          updated = tree("top", middle=tree("middle", library=tree(
              "library-v2", subflake=tree("subflake-v2"))), unrelated=tree("unrelated"))
          verify_lock(top, updated, {"subflake-v2": "./subflake"})
          case.evaluate(variant, top, updated)
          assert lock_sources(top)["unrelated"] == unchanged

  # Synthetic version of the five repositories' dependency topology. It uses
  # no real project code, Git history, system configuration or remote source.
  for variant in ("baseline", "combined"):
      if variant not in variants:
          continue
      case = Case("topology-" + variant)
      graph = fixture_spec["topology"]
      for owner, spec in graph.items():
          refs = {}
          for name, target in spec["inputs"].items():
              refs[name] = "path:./pkgs" if name in spec.get("relative", []) else case.archive_url(target)
          follows = {key.rsplit(".", 1)[0]: value for key, value in spec.get("follows", {}).items()}
          flake(case.sources / owner, owner, refs, follows=follows)
      for owner in graph:
          if "/" not in owner:
              case.archive(case.sources / owner, owner)
      # These shallow locks can be made by the baseline, before the consumer
      # introduces the deep kept-node traversal. Repack before first fetching.
      for owner in ("personal", "org-texmacs"):
          case.lock("baseline", case.sources / owner)
          case.archive(case.sources / owner, owner)

      def expand(owner):
          return tree(owner, **{name: expand(target) for name, target in graph[owner]["inputs"].items()})

      root = case.sources / "nixos"
      expected = expand("nixos")
      case.lock(variant, root, failure="either" if variant == "baseline" else None)
      if variant == "baseline":
          continue
      relatives = {"personal/pkgs": "./pkgs", "nixos/pkgs": "./pkgs"}
      for inputs in ((), ("local-nixpkgs",), ("local-nixpkgs/emarccs/org-texmacs",)):
          before = lock_sources(root)
          case.lock(variant, root, *inputs)
          verify_lock(root, expected, relatives)
          case.evaluate(variant, root, expected)
          after = lock_sources(root)
          # These inputs have immutable local sources: updating one must not
          # change source ownership or unrelated locks anywhere in the graph.
          assert before == after, (before, after)
      (root / "flake.lock").unlink()
      case.lock(variant, root)
      verify_lock(root, expected, relatives)
      case.evaluate(variant, root, expected)

  output.mkdir()
  (output / "results.json").write_text(json.dumps(results, indent=2) + "\n")
  counts = collections.Counter(result["variant"] for result in results)
  print(f"Passed {len(results)} isolated operations: {dict(counts)}", flush=True)
''
