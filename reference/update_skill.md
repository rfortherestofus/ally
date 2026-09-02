# Update an installed skill from its original source

Re-fetches the skill from whatever source it was installed from
(recorded in `.ally-source.json`) and refreshes the Claude Code copy.

## Usage

``` r
update_skill(skill, scope = c("project", "user"), link = FALSE)
```

## Arguments

- skill:

  Name of the installed skill (matches the directory name in
  `.agents/skills/`).

- scope:

  `"project"` installs into the current working directory, `"user"` into
  your home folder.

- link:

  If `TRUE`, put a relative symbolic link in each agent folder pointing
  at the `.agents/skills` copy instead of a second copy, so there is a
  single set of files to edit. Falls back to copying where links can't
  be created (typically Windows without developer mode). The default,
  `FALSE`, copies.

## Value

Invisibly, the result of
[`install_skill()`](https://rfortherestofus.github.io/ally/reference/install_skill.md).
