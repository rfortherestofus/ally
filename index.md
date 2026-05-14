# ally [![ally hex sticker](reference/figures/logo.png)](https://rfortherestofus.github.io/ally/)

{ally} helps R users get the most out of AI coding tools. It is the
companion package to [Ally](https://rfortherestofus.com/ally), a
subscription product from R for the Rest of Us aimed at advanced R users
navigating the AI transition.

The first feature is **skill installation**: a simple, R-native way to
install AI coding assistant skills without requiring `npm` or any non-R
tooling.

## Installation

``` r

# install.packages("pak")
pak::pak("rfortherestofus/ally")
```

## Quick start

From the root of any project:

``` r

library(ally)

install_skill("ab604/claude-code-r-skills/.claude/skills/r-style-guide")
#> ✔ Installed "r-style-guide" to .agents/skills/r-style-guide
#> ℹ Codex auto-discovers skills from .agents/skills/ — no symlink needed.
#> ✔ Linked to "Claude Code" (.claude/skills)
```

The skill lives in a single canonical location:
`.agents/skills/<skill>`. Codex discovers skills there natively. Claude
Code looks in `.claude/skills/`, so {ally} creates a symlink there
pointing back to the canonical copy.

## How it works

| Path | What it is |
|----|----|
| `.agents/skills/<skill>/` | Real directory — canonical copy. Codex reads it natively. |
| `.claude/skills/<skill>` | Symlink → `.agents/skills/<skill>`. So Claude Code sees the same content. |

If symlinks aren’t supported (typically Windows without developer mode),
{ally} falls back to copying and tells you it did so. You can also force
copying with `copy = TRUE`.

## Sources

``` r

# GitHub shorthand: owner/repo/path/to/skill[@ref]
install_skill("ab604/claude-code-r-skills/.claude/skills/r-style-guide")
install_skill("owner/repo/skills/my-skill@dev")

# Full GitHub URL — paste it straight from the browser
install_skill(
  "https://github.com/posit-dev/skills/tree/main/posit-dev/critical-code-reviewer"
)
# URLs ending in /SKILL.md also work (the parent dir is used)
install_skill(
  "https://github.com/posit-dev/skills/blob/main/posit-dev/critical-code-reviewer/SKILL.md"
)

# Local path — handy for skill development
install_skill("~/my-skills/r-style-guide")
```

## Other functions

``` r

installed_skills()                # list everything in .agents/skills/
update_skill("r-style-guide")     # re-fetch from the original source
link_skills()                     # re-create the Claude symlinks
remove_skill("r-style-guide")     # delete canonical copy + Claude symlink
supported_agents()                # introspect agents that need a symlink
```

## GitHub authentication

Public-repo downloads use unauthenticated GitHub API requests (60/hour),
which is plenty for most workflows. If you hit a rate limit or need to
install from a private repo, set `GITHUB_PAT` in your `.Renviron`:

    GITHUB_PAT=your_token_here

## Code of Conduct

Please note that the {ally} project is released with a [Contributor Code
of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
