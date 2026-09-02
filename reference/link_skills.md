# Refresh the Claude Code copies of installed skills

Walks every skill in `.agents/skills/` and (re)creates the
`.claude/skills/<skill>` copy, or link with `link = TRUE`, for each.
Useful after editing a skill by hand or deleting a copy. Codex reads
`.agents/skills/` directly, so no work is needed for it.

## Usage

``` r
link_skills(scope = c("project", "user"), link = FALSE)
```

## Arguments

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

Invisibly, a list with one entry per skill describing the links created
or refreshed.
