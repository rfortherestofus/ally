# Install an AI coding assistant skill

Downloads (or copies) a skill into `.agents/skills/<skill-name>/`, the
shared folder that Codex and other agents read directly, and into
`.claude/skills/<skill-name>/` for Claude Code. With `scope = "project"`
(the default) both folders sit in the current working directory and the
skill travels with the project. With `scope = "user"` they sit in your
home folder and every project on the computer can use the skill.

## Usage

``` r
install_skill(source, scope = c("project", "user"), link = FALSE)
```

## Arguments

- source:

  One of:

  - A full GitHub URL, pasted straight from the browser, e.g.
    `https://github.com/owner/repo/tree/main/path/to/skill`. A link to
    the `SKILL.md` itself also works, and so does a repository whose
    `SKILL.md` sits at the top level (the skill is then named after the
    repository). Refs containing `/` (e.g. `release/v1`) cannot be
    disambiguated from a URL; use the shorthand
    `owner/repo/path@release/v1` instead.

  - GitHub shorthand `owner/repo/path/to/skill` (optionally `@ref` for a
    branch, tag or commit), or just `owner/repo` for a top-level skill.

  - A local filesystem path to a skill directory.

- scope:

  `"project"` installs into the current working directory, `"user"` into
  your home folder.

- link:

  If `TRUE`, put a relative symbolic link in each agent folder pointing
  at the `.agents/skills` copy instead of a second copy, so there is a
  single set of files to edit. Falls back to copying where links can't
  be created (typically Windows without developer mode). The default,
  `FALSE`, copies.

## Value

Invisibly, a list describing the install.

## Details

GitHub skills are fetched from the repository's zip archive: one
download, no token, no API rate limit. Public repositories only.

## Examples

``` r
if (FALSE) { # \dontrun{
# Paste the SKILL.md link from GitHub
install_skill(
  "https://github.com/posit-dev/skills/blob/main/r-lib/r-cli-app/SKILL.md"
)

# Make it available to every project on this computer
install_skill("posit-dev/skills/r-lib/r-cli-app", scope = "user")

# Local path
install_skill("~/my-skills/r-style-guide")
} # }
```
