# Re-link installed skills to Claude Code

Walks every skill in `.agents/skills/` and (re)creates the
`.claude/skills/<skill>` symlink for each. Useful if a symlink was
deleted manually. Codex reads `.agents/skills/` natively, so no work is
needed for it.

## Usage

``` r
link_skills(copy = FALSE)
```

## Arguments

- copy:

  If `TRUE`, copy the skill into agent folders instead of symlinking.
  Symlinks are tried first when `FALSE`; this only forces the fallback
  up front (useful on Windows without dev mode).

## Value

Invisibly, a list with one entry per skill describing the links created
or refreshed.
