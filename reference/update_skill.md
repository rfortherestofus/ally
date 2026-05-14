# Update an installed skill from its original source

Re-fetches the skill from whatever source it was installed from
(recorded in `.ally-source.json`) and refreshes the Claude Code symlink.

## Usage

``` r
update_skill(skill, copy = FALSE)
```

## Arguments

- skill:

  Name of the installed skill (matches the directory name in
  `.agents/skills/`).

- copy:

  If `TRUE`, copy the skill into agent folders instead of symlinking.
  Symlinks are tried first when `FALSE`; this only forces the fallback
  up front (useful on Windows without dev mode).

## Value

Invisibly, the result of
[`install_skill()`](https://rfortherestofus.github.io/ally/reference/install_skill.md).
