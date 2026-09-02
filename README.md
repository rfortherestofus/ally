# ally

<!-- badges: start -->
<!-- badges: end -->

{ally} helps R users get the most out of AI coding tools. It is the companion
package to [Ally](https://rfortherestofus.com/ally), a subscription product
from R for the Rest of Us aimed at advanced R users navigating the AI
transition.

The first feature is **skill installation**: a simple, R-native way to
install AI coding assistant skills without requiring `npm` or any non-R
tooling.

## Installation

```r
# install.packages("pak")
pak::pak("rfortherestofus/ally")
```

## Quick start

Paste the link to a skill's `SKILL.md` straight from GitHub:

```r
ally::install_skill(
  "https://github.com/posit-dev/skills/blob/main/r-lib/r-cli-app/SKILL.md"
)
#> ✔ Installed "r-cli-app" to .agents/skills/r-cli-app
#> ℹ Codex and other agents read .agents/skills/ directly.
#> ✔ Linked to "Claude Code" (.claude/skills)
```

The skill lives in a single canonical location, `.agents/skills/<skill>`,
which Codex and a growing number of agents read directly. Claude Code looks
in `.claude/skills/`, so {ally} creates a relative symlink there pointing
back to the canonical copy.

## This project or every project

By default a skill is installed into the current working directory, so it
travels with the project. Pass `scope = "user"` to install it into your home
folder instead, where every project on the computer can use it:

```r
ally::install_skill("posit-dev/skills/r-lib/r-cli-app", scope = "user")
#> ✔ Installed "r-cli-app" to ~/.agents/skills/r-cli-app
#> ℹ Every project on this computer can use skills in ~/.agents/skills/.
#> ✔ Linked to "Claude Code" (~/.claude/skills)
```

## How it works

| Path | What it is |
|---|---|
| `.agents/skills/<skill>/` | Real directory, the canonical copy. Codex reads it directly. |
| `.claude/skills/<skill>` | Relative symlink to `../../.agents/skills/<skill>`, so Claude Code sees the same content. |

With `scope = "user"` the same two folders sit in your home directory.

If symlinks aren't supported (typically Windows without developer mode),
{ally} falls back to copying and tells you it did so. You can also force
copying with `copy = TRUE`.

Skills are fetched from the repository's zip archive on GitHub: a single
download that needs no token and never counts against the GitHub API rate
limit, so a room full of people on one network can install at once. Public
repositories only.

## Sources

```r
# Full GitHub URL, pasted straight from the browser
install_skill(
  "https://github.com/posit-dev/skills/tree/main/posit-dev/critical-code-reviewer"
)
# URLs ending in /SKILL.md also work (the parent dir is used)
install_skill(
  "https://github.com/posit-dev/skills/blob/main/posit-dev/critical-code-reviewer/SKILL.md"
)
# A repository whose SKILL.md sits at the top level is named after the repository
install_skill("https://github.com/statzhero/tidy-r-skill")

# GitHub shorthand: owner/repo/path/to/skill[@ref]
install_skill("ab604/claude-code-r-skills/.claude/skills/r-style-guide")
install_skill("owner/repo/skills/my-skill@dev")

# Local path, handy for skill development
install_skill("~/my-skills/r-style-guide")
```

## Other functions

```r
installed_skills()                # list everything in .agents/skills/
update_skill("r-style-guide")     # re-fetch from the original source
link_skills()                     # re-create the Claude symlinks
remove_skill("r-style-guide")     # delete canonical copy + Claude symlink
supported_agents()                # introspect agents that need a symlink
```

Every one of these takes the same `scope` argument as `install_skill()`.

## Code of Conduct

Please note that the {ally} project is released with a
[Contributor Code of Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
