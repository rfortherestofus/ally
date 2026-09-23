# Open an agent instruction file

Opens one of the files
[`list_agent_instructions()`](https://rfortherestofus.github.io/ally/reference/list_agent_instructions.md)
shows, in Positron or RStudio when you are working in one, or in R's own
editor otherwise.

## Usage

``` r
edit_agent_instructions(agent = NULL, scope = c("user", "project"))
```

## Arguments

- agent:

  `NULL`, the default, to pick from every listed file, or one of
  `"claude"`, `"codex"`, `"posit"` or `"agents"`.

- scope:

  Where to look: `"user"` (your home folder), `"project"` (the working
  directory), or both, the default.

## Value

Invisibly, the path of the file opened, or `NULL` when nothing was.

## Details

Run it with no arguments to pick from a numbered list. Or name the file
by the agent that reads it: `"claude"` for Claude Code, `"codex"` for
Codex, `"posit"` for Posit Assistant, or `"agents"` for the project's
shared `AGENTS.md`. When that still matches more than one file (Claude
Code has one for you and one for the project, for instance), you pick
from a short list, or narrow it with `scope`.

If the file does not exist yet, you are asked whether to create it,
empty. Existing files are only opened, never changed.

## Examples

``` r
if (FALSE) { # \dontrun{
# Pick from a numbered list
edit_agent_instructions()

# Claude Code's instructions for every project
edit_agent_instructions("claude", scope = "user")

# The project's AGENTS.md
edit_agent_instructions("agents")
} # }
```
