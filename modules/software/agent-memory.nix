# Global agent instructions for Claude Code and opencode: keep project memory inside the project
# (`.agent-memory/`), in one fixed layout, instead of ~/.claude/projects/... or opencode's data dir.
# One text, written to both tools' user-level instruction files.
{ vars, ... }: let
  text = ''
    # Project memory (applies to every project)

    Keep persistent memory **inside the project you are working in**, so it syncs with the project.
    This replaces any built-in or default memory location (`~/.claude/projects/*/memory`,
    `~/.local/share/opencode`, ...). Do not write project memory there.

    Location: `<project root>/.agent-memory/`. The project root is the git root, or the working
    directory if there is no git repo. Create the folder on first use.

    Fixed layout:

    - `.agent-memory/MEMORY.md`: index only. One line per memory: `- [Title](file.md) — one-line hook`.
    - `.agent-memory/<kebab-case-slug>.md`: one fact per file.

    Memory file format:

    ```markdown
    ---
    name: <slug, same as the filename without .md>
    description: <one-line summary used to decide relevance>
    type: user | feedback | project | reference
    ---

    <the fact. For feedback and project, add **Why:** and **How to apply:** lines.>
    ```

    Rules:

    1. At the start of a task, read `.agent-memory/MEMORY.md` if it exists, then open only the memories that look relevant.
    2. Before writing, check for an existing memory on the topic and update it instead of duplicating.
    3. After adding, changing or deleting a memory, update `MEMORY.md` in the same step.
    4. Use absolute dates (YYYY-MM-DD), never "today" or "last week".
    5. Save only what the code and git history don't show: preferences, decisions and their reasons, pending TODOs, external references.
    6. Never store secrets, tokens or passwords.
    7. Personal facts about the user that apply across projects (`type: user`) go in the same folder; do not copy them into outward-facing text.
  '';
in {
  home-manager.users.${vars.username} = {
    home.file.".claude/CLAUDE.md".text = text;
    xdg.configFile."opencode/AGENTS.md".text = text;
  };
}
