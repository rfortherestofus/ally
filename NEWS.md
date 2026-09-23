# ally 0.1.0

* New `list_agent_instructions()` shows the instruction files your AI coding
  assistants read (`CLAUDE.md`, `AGENTS.md` and friends), for Claude Code,
  Codex and Posit Assistant, in your home folder and the current project. It
  notes when a project's `CLAUDE.md` keeps Claude Code from reading its
  `AGENTS.md`.

* New `edit_agent_instructions()` opens one of those files in Positron or
  RStudio, from a numbered list or by naming the agent. It offers to create a
  file that doesn't exist yet and never changes existing ones.

* `installed_skills()` now lists every skill an agent can load, not just the
  ones in `.agents/skills/`. It also looks in `.claude/skills/`,
  `.codex/skills/` and `.cursor/skills/`, in the project and your home folder
  (both by default), and finds skills that are links to other folders.

* `installed_skills()` now returns a tibble with one row per skill: its name,
  the start of its description, what installed it (`"ally"` or
  `"skills CLI"`), where from, when, and when it last changed on GitHub.
  **Breaking:** it used to return a character vector of names. Use
  `installed_skills()$name` for the old result.

* `install_skill()` now records a fingerprint of each skill's files. If a copy
  has been edited since, or was not installed by ally, `install_skill()` and
  `update_skill()` stop rather than overwrite it, and `link_skills()` skips it
  with a warning. Pass `force = TRUE` to overwrite. `installed_skills()` has a
  new `edited` column showing which skills have changed.

* `installed_skills()` looks up GitHub update times with each repository's
  public commit feed, which needs no token and does not count against the
  GitHub API rate limit. Pass `check_github = FALSE` to skip the lookup.
