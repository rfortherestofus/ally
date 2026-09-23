# Agent instructions

## What is an instruction file?

An instruction file is a Markdown file where you tell an AI coding
assistant how you like to work: “use the native pipe”, “write tests with
testthat”, “never touch the `data-raw/` folder”. The assistant reads it
at the start of every conversation, so you don’t have to repeat
yourself.

Each assistant looks for its own file, in two places:

- **In your home folder**, for instructions that apply to every project
  on your computer. This is where personal preferences go.
- **In a project**, for instructions about that project alone: its
  structure, its conventions, the packages it uses. These files can be
  committed to git so collaborators’ assistants follow them too.

The trouble is knowing which file each assistant reads, and where.
{ally} shows you, and opens the one you want to edit.

## See what you have

[`list_agent_instructions()`](https://rfortherestofus.github.io/ally/reference/list_agent_instructions.md)
shows the instruction files for the assistants on your computer, in your
home folder and in the current project:

``` r

library(ally)

list_agent_instructions()
#> ── Agent instructions ─────────────────────────────────────────────────
#>
#> ── User (all projects) ──
#>
#> 1: Claude Code                          ~/.claude/CLAUDE.md           24 lines
#> 2: Posit Assistant                      ~/.posit/assistant/AGENTS.md  not found
#>
#> ── Project (report) ──
#>
#> 3: Codex, Posit Assistant, Claude Code  AGENTS.md                     12 lines
#> 4: Claude Code                          CLAUDE.md                     not found
```

Each row is one file: who reads it, where it is, and how long it is.
Files that don’t exist yet are listed as “not found” so you can see
where they would go.

Only assistants installed on your computer appear in the user section.
{ally} judges that by whether the assistant’s folder in your home folder
(`~/.claude`, `~/.codex`, `~/.posit`) exists. Pass `scope = "user"` or
`scope = "project"` to see just one section.

Listing never creates or changes anything.

## Edit one

[`edit_agent_instructions()`](https://rfortherestofus.github.io/ally/reference/edit_agent_instructions.md)
shows the same numbered list and opens the file you pick, in Positron or
RStudio:

``` r

edit_agent_instructions()
#> Which instructions do you want to edit?
#>
#> ── User (all projects) ──
#>
#> 1: Claude Code                          ~/.claude/CLAUDE.md           24 lines
#> 2: Posit Assistant                      ~/.posit/assistant/AGENTS.md  not found
#>
#> ── Project (report) ──
#>
#> 3: Codex, Posit Assistant, Claude Code  AGENTS.md                     12 lines
#> 4: Claude Code                          CLAUDE.md                     not found
#> Selection (blank to cancel): 1
#> ✔ Opening '~/.claude/CLAUDE.md'
```

To skip the list, name the file by the assistant that reads it:
`"claude"` for Claude Code, `"codex"` for Codex, `"posit"` for Posit
Assistant, or `"agents"` for the project’s shared `AGENTS.md`.

``` r

edit_agent_instructions("posit")
edit_agent_instructions("agents")
edit_agent_instructions("claude", scope = "user")
```

Claude Code has a file for you and one for the project, so
`edit_agent_instructions("claude")` asks which one you mean when both
exist. Add `scope` to go straight to one.

If the file doesn’t exist yet, {ally} asks whether to create it, empty,
and then opens it. Existing files are only ever opened, never changed.

## Which assistant reads which file

| Assistant | Every project | This project |
|----|----|----|
| Claude Code | `~/.claude/CLAUDE.md` | `CLAUDE.md`, or `AGENTS.md` when there is no `CLAUDE.md` |
| Codex | `~/.codex/AGENTS.md` | `AGENTS.md` |
| Posit Assistant | `~/.posit/assistant/AGENTS.md` | `AGENTS.md` |

A few less common files are listed only when they exist:

- `~/.codex/AGENTS.override.md`, which Codex reads instead of
  `~/.codex/AGENTS.md`.
- `.claude/CLAUDE.md`, which Claude Code reads like a `CLAUDE.md` at the
  top of the project.
- `CLAUDE.local.md`, which Claude Code reads for your own notes on a
  project. It is meant to stay out of git.

## One project file for every assistant

`AGENTS.md` is becoming the shared name for project instructions. Codex,
Posit Assistant, Cursor, GitHub Copilot and Gemini CLI all read it, and
so does Claude Code (from version 2.1.277), but only when the project
has no `CLAUDE.md` of its own. A project with just an `AGENTS.md` gives
every assistant the same instructions.

If a project has both, Claude Code reads its `CLAUDE.md` and ignores
`AGENTS.md`, and
[`list_agent_instructions()`](https://rfortherestofus.github.io/ally/reference/list_agent_instructions.md)
points that out:

``` r

#> ! Claude Code reads 'CLAUDE.md' in this project, not 'AGENTS.md'. To share
#>   'AGENTS.md' with it, add the line `@AGENTS.md` to 'CLAUDE.md'.
```

A line reading `@AGENTS.md` in a `CLAUDE.md` pulls the whole `AGENTS.md`
in at that spot, so Claude Code sees both files. Anything only Claude
Code should see can stay in `CLAUDE.md` around that line.

## A walkthrough you can run

Everything below runs against a throwaway project, so it touches nothing
else on your computer. It looks at the project section only, since the
user section would show your own home folder.

``` r

library(ally)

project <- fs::dir_create(fs::path(tempdir(), "report"))

withr::with_dir(project, list_agent_instructions(scope = "project"))
#> 
#> ── Agent instructions ──────────────────────────────────────────────────────────
#> 
#> ── Project (report) ──
#> 
#> 1: Codex, Posit Assistant, Claude Code  AGENTS.md  not found
#> 2: Claude Code                          CLAUDE.md  not found
```

Add an `AGENTS.md` and every assistant reads it, Claude Code included:

``` r

writeLines(
  c("# Report", "", "Use the native pipe `|>`.", "Write tests with testthat."),
  fs::path(project, "AGENTS.md")
)
withr::with_dir(project, list_agent_instructions(scope = "project"))
#> 
#> ── Agent instructions ──────────────────────────────────────────────────────────
#> 
#> ── Project (report) ──
#> 
#> 1: Codex, Posit Assistant, Claude Code  AGENTS.md  4 lines
#> 2: Claude Code                          CLAUDE.md  not found
```

Add a `CLAUDE.md` as well and Claude Code switches to it:

``` r

writeLines("Keep answers short.", fs::path(project, "CLAUDE.md"))
withr::with_dir(project, list_agent_instructions(scope = "project"))
#> 
#> ── Agent instructions ──────────────────────────────────────────────────────────
#> 
#> ── Project (report) ──
#> 
#> 1: Codex, Posit Assistant  AGENTS.md  4 lines
#> 2: Claude Code             CLAUDE.md  1 line
#> 
#> ! Claude Code reads 'CLAUDE.md' in this project, not 'AGENTS.md'. To share 'AGENTS.md' with it, add the line `@AGENTS.md` to 'CLAUDE.md'.
```

[`list_agent_instructions()`](https://rfortherestofus.github.io/ally/reference/list_agent_instructions.md)
also returns the list as a tibble, invisibly, if you want to work with
it in code:

``` r

files <- withr::with_dir(project, list_agent_instructions(scope = "project"))
#> 
#> ── Agent instructions ──────────────────────────────────────────────────────────
#> 
#> ── Project (report) ──
#> 
#> 1: Codex, Posit Assistant  AGENTS.md  4 lines
#> 2: Claude Code             CLAUDE.md  1 line
#> 
#> ! Claude Code reads 'CLAUDE.md' in this project, not 'AGENTS.md'. To share 'AGENTS.md' with it, add the line `@AGENTS.md` to 'CLAUDE.md'.
files[, c("read_by", "exists", "lines")]
#> # A tibble: 2 × 3
#>   read_by                exists lines
#>   <chr>                  <lgl>  <int>
#> 1 Codex, Posit Assistant TRUE       4
#> 2 Claude Code            TRUE       1
```
