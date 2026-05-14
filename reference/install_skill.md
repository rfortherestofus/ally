# Install an AI coding assistant skill

Downloads (or copies) a skill into `.agents/skills/<skill-name>/` in the
current working directory and creates a symlink at
`.claude/skills/<skill-name>` so Claude Code picks it up. Codex
auto-discovers skills from `.agents/skills/` natively, so no symlink is
needed for Codex.

## Usage

``` r
install_skill(source, copy = FALSE)
```

## Arguments

- source:

  One of:

  - GitHub shorthand `owner/repo/path/to/skill` (optionally `@ref` for a
    branch/tag/sha)

  - A full GitHub URL, e.g.
    `https://github.com/owner/repo/tree/main/path/to/skill` (URLs ending
    in `/SKILL.md` are accepted; the parent directory is used). Refs
    containing `/` (e.g. `release/v1`) cannot be disambiguated from a
    URL — use the shorthand `owner/repo/path@release/v1` instead.

  - A local filesystem path to a skill directory

- copy:

  If `TRUE`, copy the skill into agent folders instead of symlinking.
  Symlinks are tried first when `FALSE`; this only forces the fallback
  up front (useful on Windows without dev mode).

## Value

Invisibly, a list describing the install.

## Examples

``` r
if (FALSE) { # \dontrun{
# GitHub shorthand
install_skill("ab604/claude-code-r-skills/.claude/skills/r-style-guide")

# Full GitHub URL (also works with the SKILL.md link)
install_skill(
  "https://github.com/posit-dev/skills/tree/main/posit-dev/critical-code-reviewer"
)

# Local path
install_skill("~/my-skills/r-style-guide")
} # }
```
