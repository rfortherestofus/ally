# Remove an installed skill

Deletes the canonical copy at `.agents/skills/<skill>/` and removes the
copy (or link) at `.claude/skills/<skill>`.

## Usage

``` r
remove_skill(skill, scope = c("project", "user"))
```

## Arguments

- skill:

  Name of the installed skill.

- scope:

  `"project"` installs into the current working directory, `"user"` into
  your home folder.

## Value

Invisibly `TRUE`.
