# List installed skills

Finds every skill on the computer that an agent can load, not just the
ones ally installed. It looks in the shared `.agents/skills/` folder and
in each agent's own folder (`.claude/skills/`, `.codex/skills/`,
`.cursor/skills/`), for the project, your home folder, or both. A folder
counts as a skill when it holds a `SKILL.md`, whether it is a real
folder or a link to one.

## Usage

``` r
installed_skills(scope = c("project", "user"))
```

## Arguments

- scope:

  Where to look: `"project"` (the working directory), `"user"` (your
  home folder), or both, the default.

## Value

A tibble with one row per skill and columns:

- `name`: the skill's folder name.

- `description`: the `description` from the `SKILL.md` header, which
  agents read to decide when to use the skill.

- `source`: where the skill came from, such as
  `"posit-dev/skills/r-lib/r-cli-app"`, or `NA` if nothing recorded it.

- `installed_by`: `"ally"`, `"skills CLI"`, or `NA`.

- `scope`: `"project"` or `"user"`.

- `found_in`: the folders that hold the skill, such as
  `".agents, .claude"`.

- `path`: the skill's folder, preferring the `.agents/skills/` copy.

## Details

A skill that sits in several folders (the `.agents/skills/` copy and the
Claude Code copy ally makes, for instance) is listed once, with every
folder it was found in.

The source comes from the first of these that has one: the
`.ally-source.json` that
[`install_skill()`](https://rfortherestofus.github.io/ally/reference/install_skill.md)
writes, the lockfile the `skills` command-line tool (`npx skills`) keeps
at `.agents/.skill-lock.json`, or the target of a link that points
somewhere else. Skills copied in by hand have no recorded source.

Skills that come from Claude Code plugins live elsewhere and are not
listed.

## Examples

``` r
if (FALSE) { # \dontrun{
installed_skills()
installed_skills(scope = "user")
} # }
```
