# List installed skills

Finds every skill on the computer that an agent can load, not just the
ones ally installed. It looks in the shared `.agents/skills/` folder and
in each agent's own folder (`.claude/skills/`, `.codex/skills/`,
`.cursor/skills/`), for the project, your home folder, or both. A folder
counts as a skill when it holds a `SKILL.md`, whether it is a real
folder or a link to one.

## Usage

``` r
installed_skills(scope = c("project", "user"), check_github = TRUE)
```

## Arguments

- scope:

  Where to look: `"project"` (the working directory), `"user"` (your
  home folder), or both, the default.

- check_github:

  If `TRUE`, the default, look up when each GitHub skill last changed.
  Set to `FALSE` to skip the lookup, when offline for instance.

## Value

A tibble with one row per skill and columns:

- `name`: the skill's folder name.

- `description`: the start of the `description` from the `SKILL.md`
  header, which agents read to decide when to use the skill. The full
  text is in the `SKILL.md` at `path`.

- `installed_by`: `"ally"`, `"skills CLI"`, or `NA` when nothing
  recorded it.

- `installed_from`: the GitHub repository and folder, local path or link
  target the skill was installed from, such as
  `"posit-dev/skills/r-lib/r-cli-app"`, or `NA` when nothing recorded
  it.

- `installed`: the date this copy was installed or last updated.

- `updated_on_github`: the date the skill's folder last changed on
  GitHub, or `NA` for skills that did not come from GitHub.

- `scope`: `"project"` or `"user"`.

- `found_in`: the folders that hold the skill, such as
  `".agents, .claude"`.

- `path`: the skill's folder, preferring the `.agents/skills/` copy.

## Details

A skill that sits in several folders (the `.agents/skills/` copy and the
Claude Code copy ally makes, for instance) is listed once, with every
folder it was found in.

What installed a skill, where from, and when come from the first of
these that records it: the `.ally-source.json` that
[`install_skill()`](https://rfortherestofus.github.io/ally/reference/install_skill.md)
writes, or the lockfile the `skills` command-line tool (`npx skills`)
keeps at `.agents/.skill-lock.json`. A skill that is a link to a folder
elsewhere shows that folder as where it came from. Skills copied in by
hand have none of this, so their install date is the date their folder
was created.

For skills installed from GitHub, `installed_skills()` also looks up
when the skill's folder last changed there, using the repository's
public commit feed. That needs no token and does not count against the
GitHub API rate limit. If the date is newer than `installed`,
[`update_skill()`](https://rfortherestofus.github.io/ally/reference/update_skill.md)
will fetch a newer version.

Skills that come from Claude Code plugins live elsewhere and are not
listed.

## Examples

``` r
if (FALSE) { # \dontrun{
installed_skills()
installed_skills(scope = "user", check_github = FALSE)
} # }
```
