#' Remove an installed skill
#'
#' Deletes the canonical copy at `.agents/skills/<skill>/` and removes the
#' copy (or link) at `.claude/skills/<skill>`.
#'
#' @param skill Name of the installed skill.
#' @inheritParams install_skill
#'
#' @return Invisibly `TRUE`.
#' @export
remove_skill <- function(skill, scope = c("project", "user")) {
  scope <- match.arg(scope)
  root <- skills_root(scope)
  canonical_root <- canonical_skills_dir(root)
  skill_dir <- fs::path(canonical_root, skill)

  if (!fs::dir_exists(skill_dir)) {
    cli::cli_abort(
      "Skill {.val {skill}} is not installed at {.path {pretty_path(canonical_root)}}."
    )
  }

  for (agent in supported_agents()) {
    agent_dir <- agent_skills_dir(agent, root = root)
    link_path <- fs::path(agent_dir, skill)

    if (fs::link_exists(link_path)) {
      fs::link_delete(link_path)
      cli::cli_alert_success(
        "Removed link at {.path {pretty_path(link_path)}}"
      )
    } else if (fs::dir_exists(link_path)) {
      fs::dir_delete(link_path)
      cli::cli_alert_success(
        "Removed copy at {.path {pretty_path(link_path)}}"
      )
    }
  }

  fs::dir_delete(skill_dir)
  cli::cli_alert_success(
    "Removed canonical copy at {.path {pretty_path(skill_dir)}}"
  )

  invisible(TRUE)
}
