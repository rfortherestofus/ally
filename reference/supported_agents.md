# Agents that need a symlink

`ally` stores skills at `.agents/skills/<skill>`, which Codex
auto-discovers natively. Other agents read from their own folders, so
they need a symlink pointing back to the canonical copy. This list
enumerates those agents.

## Usage

``` r
supported_agents()
```

## Value

A named list of agent definitions.
