# Ally R Package — Implementation Brief

## Overview

`ally` is an R package that helps R users get the most out of AI coding tools. It is the companion package to Ally, a subscription product from R for the Rest of Us aimed at advanced R users navigating the AI transition.

The package will grow over time to support a range of workflows. The first feature is skill installation — a simple, R-native way to install AI coding assistant skills without requiring npm or any non-R tooling.

## Core concept (skill installation)

Skills are SKILL.md files that teach AI coding assistants how to approach specific tasks. A skill directory may also contain subdirectories with additional supporting files (examples, templates, reference docs). The package downloads the entire skill directory from GitHub, stores a canonical copy in `.skills/`, and creates symlinks from each detected agent's expected folder to that canonical copy.

## Package structure

Standard R package layout. Organize with room to grow beyond skill installation. Key files for the initial implementation:

- `R/install_skill.R` — main user-facing function
- `R/detect_agents.R` — detects which agents are configured in the project
- `R/symlink.R` — handles symlink creation with copy fallback
- `R/github.R` — GitHub API interactions (listing and downloading skill contents)
- `R/utils.R` — shared helpers (path resolution, downloads, source parsing, etc.)

## Agent folder mapping

Each agent expects skills in a specific folder:

| Agent | Project path |
|---|---|
| Claude Code | `.claude/skills/` |
| Cursor | `.agents/skills/` |
| Codex | `.agents/skills/` |
| Windsurf | `.windsurf/skills/` |
| GitHub Copilot | `.agents/skills/` |

Detect agent presence by checking whether these folders (or their parent config folders) exist in the project root.

## Main function: `install_skill()`

```r
install_skill(
  source,         # GitHub shorthand (owner/repo/skill) or local path
  global = FALSE, # if TRUE, install to ~/.skills/ and agent global paths
                  # defaults to FALSE (project-level install)
  agent = NULL,   # optionally target a specific agent; if NULL, auto-detect
  copy = FALSE    # if TRUE, copy files instead of symlinking (Windows fallback)
)
```

### Source formats

```r
# GitHub shorthand (owner/repo/skill-name) — primary method, supports full directory download
ally::install_skill("ab604/claude-code-r-skills/r-style-guide")

# Local path — for development and testing, copies entire directory
ally::install_skill("~/my-skills/r-style-guide")
```

### Behavior

1. Parse `source` to determine type (GitHub shorthand or local path)
2. Infer skill name from the source (e.g. last path component)
3. Download or copy the entire skill directory to `.skills/<skill-name>/` by default (project-level); use `global = TRUE` to install to `~/.skills/` instead:
   - **GitHub shorthand**: use the GitHub API to recursively list and download all files and subdirectories
   - **Local path**: copy the entire directory tree using `fs::dir_copy()`
4. Detect which agents are present (or use `agent` argument if provided)
5. For each detected agent, create the skills subfolder if needed
6. Create a symlink from the agent folder pointing to the canonical copy
7. If symlink creation fails (e.g. Windows without dev mode), fall back to copying with an informative message
8. Default to Claude Code if no agents are detected, with an informative message
9. Also check all previously installed skills in `.skills/` and create any missing symlinks for newly detected agents (so adding an agent later doesn't leave existing skills unlinked)

### Messages

Use `cli` package for all user-facing output. On success something like:

```
✔ Installed r-style-guide to .skills/
✔ Linked to Claude Code (.claude/skills/)
ℹ No other agents detected. Use `agent = "cursor"` to install for Cursor.
ℹ Added a new agent later? Run `ally::link_skills()` to sync.
```

## GitHub API usage

Use the GitHub API to list and download skill directory contents recursively. No PAT is required for public repositories — unauthenticated requests are supported up to 60/hour, which is sufficient for typical usage.

For private repositories or users hitting rate limits, the function should check for a `GITHUB_PAT` environment variable and include it in API requests if present. This follows the same pattern used by `gh`, `remotes`, and other R packages.

```r
# Users can set this in .Renviron if needed
GITHUB_PAT=your_token_here
```

Include a clear error message if a rate limit is hit, suggesting the user set `GITHUB_PAT`.

## Additional functions

- `update_skill(skill)` — re-fetch a skill from its original source to get the latest version
- `remove_skill(skill)` — remove canonical copy and all symlinks/copies
- `link_skills()` — scan `.skills/`, detect all installed skills and all present agents, and create any missing symlinks. Useful when a user adds a new agent after skills are already installed.

## Dependencies

- `cli` for user-facing messages
- `fs` for all file system operations (`fs::dir_create()`, `fs::link_create()`, `fs::file_copy()`, etc.)
- `httr2` for GitHub API requests and downloading remote files

## File system operations

Use `fs` throughout instead of base R equivalents:

| Task | Use |
|---|---|
| Create directories | `fs::dir_create(path, recurse = TRUE)` |
| Copy directory | `fs::dir_copy(path, new_path)` |
| Create symlink | `fs::link_create(path, new_path)` |
| Copy file | `fs::file_copy(path, new_path)` |
| Check existence | `fs::file_exists()` / `fs::dir_exists()` |
| Delete | `fs::file_delete()` / `fs::link_delete()` |
| Resolve paths | `fs::path()` / `fs::path_expand()` |

## Testing

- Test source parsing for both formats (GitHub shorthand and local path)
- Test recursive directory download from GitHub API
- Test symlink creation and fallback to copy
- Test agent detection logic
- Test with missing/nonexistent skills (should error informatively)
- Test global vs project install paths
- Test unauthenticated and PAT-authenticated GitHub API requests
- Test `link_skills()` correctly syncs existing skills to newly added agents
- Test on Windows if possible (symlink fallback path)

## Notes

- Use `usethis::proj_path()` pattern for detecting the active project root
- `global = FALSE` is the default — skills are installed into the current project unless the user explicitly passes `global = TRUE`
- Windows symlinks require developer mode or admin privileges — always attempt symlink first, catch failure, fall back to copy with a message explaining what happened
- The package should work outside of any project only if `global = TRUE`, otherwise error with a helpful message
- Store source metadata (original GitHub path or local path) alongside the canonical skill so `update_skill()` knows where to re-fetch from — a simple JSON or YAML sidecar file in `.skills/<skill-name>/` would work