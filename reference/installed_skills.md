# List installed skills

List installed skills

## Usage

``` r
installed_skills(scope = c("project", "user"))
```

## Arguments

- scope:

  `"project"` installs into the current working directory, `"user"` into
  your home folder.

## Value

Character vector of skill names found in `.agents/skills/` for the
scope.
