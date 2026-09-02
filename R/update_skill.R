#' Update an installed skill from its original source
#'
#' Re-fetches the skill from whatever source it was installed from (recorded
#' in `.ally-source.json`) and refreshes the Claude Code link.
#'
#' @param skill Name of the installed skill (matches the directory name in
#'   `.agents/skills/`).
#' @inheritParams install_skill
#'
#' @return Invisibly, the result of [install_skill()].
#' @export
update_skill <- function(skill, scope = c("project", "user"), copy = FALSE) {
  scope <- match.arg(scope)
  canonical_root <- canonical_skills_dir(skills_root(scope))
  skill_dir <- fs::path(canonical_root, skill)

  if (!fs::dir_exists(skill_dir)) {
    cli::cli_abort(c(
      "Skill {.val {skill}} is not installed at {.path {pretty_path(canonical_root)}}.",
      "i" = "Run {.code ally::installed_skills()} to see what is installed."
    ))
  }

  metadata <- read_source_metadata(skill_dir)
  if (is.null(metadata) || is.null(metadata$source)) {
    cli::cli_abort(c(
      "No source metadata found for {.val {skill}}.",
      "i" = "Reinstall it manually with {.code ally::install_skill(...)}."
    ))
  }

  cli::cli_alert_info(
    "Updating {.val {skill}} from {.val {metadata$source}}"
  )

  install_skill(source = metadata$source, scope = scope, copy = copy)
}
