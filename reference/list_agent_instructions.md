# List agent instruction files

Shows the instruction files your AI coding assistants read: the Markdown
files where you tell an agent how you like to work (`CLAUDE.md` for
Claude Code, `AGENTS.md` for Codex, Posit Assistant and others).
Instructions can apply to every project on the computer (`"user"`, in
your home folder) or to one project (`"project"`, in the working
directory).

## Usage

``` r
list_agent_instructions(scope = c("user", "project"))
```

## Arguments

- scope:

  Where to look: `"user"` (your home folder), `"project"` (the working
  directory), or both, the default.

## Value

Invisibly, a tibble with one row per file, in the order shown, and
columns:

- `scope`: `"user"` or `"project"`.

- `agent`: the name
  [`edit_agent_instructions()`](https://rfortherestofus.github.io/ally/reference/edit_agent_instructions.md)
  takes for the file: `"claude"`, `"codex"`, `"posit"` or `"agents"`.

- `read_by`: the agents that read the file.

- `path`: the full path to the file.

- `exists`: whether the file exists.

- `lines`: how many lines the file has, or `NA` when it does not exist.

## Details

The main file for each agent is always listed, marked "not found" when
it does not exist yet, so you can see where it would go:

- User: `~/.claude/CLAUDE.md` (Claude Code), `~/.codex/AGENTS.md`
  (Codex) and `~/.posit/assistant/AGENTS.md` (Posit Assistant). Only
  agents installed on this computer are listed, judged by whether their
  folder (`~/.claude`, `~/.codex`, `~/.posit`) exists.

- Project: `AGENTS.md`, read by Codex and Posit Assistant, and by Claude
  Code when the project has no `CLAUDE.md`; and `CLAUDE.md`, read by
  Claude Code.

Less common files are listed only when they exist:
`~/.codex/AGENTS.override.md`, `.claude/CLAUDE.md` and
`CLAUDE.local.md`.

If a project has both an `AGENTS.md` and a `CLAUDE.md`, Claude Code
reads only the `CLAUDE.md`, and a note says so. A `CLAUDE.md` that
contains the line `@AGENTS.md` pulls the `AGENTS.md` in, so there is no
note.

Nothing is created or changed. Use
[`edit_agent_instructions()`](https://rfortherestofus.github.io/ally/reference/edit_agent_instructions.md)
to open a file.

## Examples

``` r
if (FALSE) { # \dontrun{
list_agent_instructions()
list_agent_instructions(scope = "user")
} # }
```
