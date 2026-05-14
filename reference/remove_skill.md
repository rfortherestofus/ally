# Remove an installed skill

Deletes the canonical copy at `.agents/skills/<skill>/` and removes the
symlink (or copy) at `.claude/skills/<skill>`.

## Usage

``` r
remove_skill(skill)
```

## Arguments

- skill:

  Name of the installed skill.

## Value

Invisibly `TRUE`.
