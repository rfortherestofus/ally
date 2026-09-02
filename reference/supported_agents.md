# Agents that need a link

`ally` stores skills at `.agents/skills/<skill>`, the shared folder that
Codex and a growing number of agents read directly. Agents that only
read their own folder get a copy there (or a link with `link = TRUE`).
This list enumerates those agents. The folder is relative to the scope
root: the project for `scope = "project"`, the home folder for
`scope = "user"`.

## Usage

``` r
supported_agents()
```

## Value

A named list of agent definitions.
