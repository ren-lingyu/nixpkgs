---
name: nixpkgs-memory
description: Locate and read this repository's GAW memory when resuming work or consulting recorded decisions and evidence.
---

# Read project memory

Use the external `git-agent-workflow` skill and `git gaw status` to locate the
formal GAW worktree. Paths below are relative to that worktree root, not the
project checkout or an installed copy of this skill.

1. Read `memory/current.md` first.
2. Follow its references to the memory files relevant to the task.
3. When a reference requires historical evidence, locate the relevant checkpoint
   through first-parent GAW history and inspect its actual parent list and trees.
   Interpret earlier snapshots using their own paths and conventions.

The referenced memory is GAW workspace data, not a bundled skill resource.
