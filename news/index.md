# Changelog

## ally 0.1.0

- [`installed_skills()`](https://rfortherestofus.github.io/ally/reference/installed_skills.md)
  now lists every skill an agent can load, not just the ones in
  `.agents/skills/`. It also looks in `.claude/skills/`,
  `.codex/skills/` and `.cursor/skills/`, in the project and your home
  folder (both by default), and finds skills that are links to other
  folders.

- [`installed_skills()`](https://rfortherestofus.github.io/ally/reference/installed_skills.md)
  now returns a tibble with one row per skill: its name, the start of
  its description, what installed it (`"ally"` or `"skills CLI"`), where
  from, when, and when it last changed on GitHub. **Breaking:** it used
  to return a character vector of names. Use `installed_skills()$name`
  for the old result.

- [`install_skill()`](https://rfortherestofus.github.io/ally/reference/install_skill.md)
  now records a fingerprint of each skill’s files. If a copy has been
  edited since, or was not installed by ally,
  [`install_skill()`](https://rfortherestofus.github.io/ally/reference/install_skill.md)
  and
  [`update_skill()`](https://rfortherestofus.github.io/ally/reference/update_skill.md)
  stop rather than overwrite it, and
  [`link_skills()`](https://rfortherestofus.github.io/ally/reference/link_skills.md)
  skips it with a warning. Pass `force = TRUE` to overwrite.
  [`installed_skills()`](https://rfortherestofus.github.io/ally/reference/installed_skills.md)
  has a new `edited` column showing which skills have changed.

- [`installed_skills()`](https://rfortherestofus.github.io/ally/reference/installed_skills.md)
  looks up GitHub update times with each repository’s public commit
  feed, which needs no token and does not count against the GitHub API
  rate limit. Pass `check_github = FALSE` to skip the lookup.
