#' Install an AI coding assistant skill
#'
#' Downloads (or copies) a skill into `.agents/skills/<skill-name>/` in the
#' current working directory and creates a symlink at
#' `.claude/skills/<skill-name>` so Claude Code picks it up. Codex
#' auto-discovers skills from `.agents/skills/` natively, so no symlink is
#' needed for Codex.
#'
#' @param source One of:
#'   * GitHub shorthand `owner/repo/path/to/skill` (optionally `@ref` for a
#'     branch/tag/sha)
#'   * A full GitHub URL, e.g.
#'     `https://github.com/owner/repo/tree/main/path/to/skill` (URLs ending
#'     in `/SKILL.md` are accepted; the parent directory is used). Refs
#'     containing `/` (e.g. `release/v1`) cannot be disambiguated from a
#'     URL — use the shorthand `owner/repo/path@release/v1` instead.
#'   * A local filesystem path to a skill directory
#' @param copy   If `TRUE`, copy the skill into agent folders instead of
#'   symlinking. Symlinks are tried first when `FALSE`; this only forces the
#'   fallback up front (useful on Windows without dev mode).
#'
#' @return Invisibly, a list describing the install.
#' @export
#'
#' @examples
#' \dontrun{
#' # GitHub shorthand
#' install_skill("ab604/claude-code-r-skills/.claude/skills/r-style-guide")
#'
#' # Full GitHub URL (also works with the SKILL.md link)
#' install_skill(
#'   "https://github.com/posit-dev/skills/tree/main/posit-dev/critical-code-reviewer"
#' )
#'
#' # Local path
#' install_skill("~/my-skills/r-style-guide")
#' }
install_skill <- function(source, copy = FALSE) {
  parsed <- parse_source(source)
  skill_name <- parsed$skill_name

  root <- getwd()
  canonical_root <- canonical_skills_dir(root)
  skill_dir <- fs::path(canonical_root, skill_name)
  fs::dir_create(canonical_root, recurse = TRUE)

  if (fs::dir_exists(skill_dir)) {
    fs::dir_delete(skill_dir)
  }

  fetch_skill(parsed, skill_dir)
  write_source_metadata(skill_dir, parsed)

  cli::cli_alert_success(
    "Installed {.val {skill_name}} to {.path {pretty_path(skill_dir)}}"
  )
  cli::cli_alert_info(
    "Codex auto-discovers skills from {.path .agents/skills/} — no symlink needed."
  )

  links <- link_skill_to_agents(
    skill_dir = skill_dir,
    skill_name = skill_name,
    root = root,
    copy = copy
  )

  invisible(list(
    skill = skill_name,
    skill_dir = skill_dir,
    links = links
  ))
}

#' @keywords internal
#' @noRd
fetch_skill <- function(parsed, dest) {
  if (parsed$type == "github") {
    github_download_dir(
      owner = parsed$owner,
      repo = parsed$repo,
      path = parsed$path,
      dest = dest,
      ref = parsed$ref
    )
  } else {
    if (!fs::dir_exists(parsed$path)) {
      cli::cli_abort("Local source {.path {parsed$path}} does not exist.")
    }
    fs::dir_create(fs::path_dir(dest), recurse = TRUE)
    fs::dir_copy(parsed$path, dest, overwrite = TRUE)
  }
}

#' @keywords internal
#' @noRd
link_skill_to_agents <- function(skill_dir,
                                 skill_name,
                                 root = getwd(),
                                 copy = FALSE) {
  results <- list()

  for (agent in supported_agents()) {
    agent_dir <- agent_skills_dir(agent, root = root)
    link_path <- fs::path(agent_dir, skill_name)

    res <- link_or_copy(skill_dir, link_path, force_copy = copy)

    cli::cli_alert_success(
      "Linked to {.val {agent$name}} ({.path {pretty_path(agent_dir)}})"
    )
    results[[agent$id]] <- c(list(agent = agent$id), res)
  }

  results
}
