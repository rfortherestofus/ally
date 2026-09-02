#' Refresh the Claude Code copies of installed skills
#'
#' Walks every skill in `.agents/skills/` and (re)creates the
#' `.claude/skills/<skill>` copy, or link with `link = TRUE`, for each.
#' Useful after editing a skill by hand or deleting a copy. Codex reads
#' `.agents/skills/` directly, so no work is needed for it.
#'
#' @inheritParams install_skill
#'
#' @return Invisibly, a list with one entry per skill describing the links
#'   created or refreshed.
#' @export
link_skills <- function(scope = c("project", "user"), link = FALSE) {
  scope <- match.arg(scope)
  root <- skills_root(scope)
  canonical_root <- canonical_skills_dir(root)
  if (!fs::dir_exists(canonical_root)) {
    cli::cli_alert_info(
      "No skills found at {.path {pretty_path(canonical_root)}}."
    )
    return(invisible(list()))
  }

  skills <- installed_skills(scope = scope)
  if (length(skills) == 0) {
    cli::cli_alert_info("No skills installed.")
    return(invisible(list()))
  }

  results <- list()
  for (skill in skills) {
    skill_dir <- fs::path(canonical_root, skill)
    results[[skill]] <- link_skill_to_agents(
      skill_dir = skill_dir,
      skill_name = skill,
      root = root,
      link = link
    )
  }
  invisible(results)
}

#' List installed skills
#'
#' @inheritParams install_skill
#'
#' @return Character vector of skill names found in `.agents/skills/` for the scope.
#' @export
installed_skills <- function(scope = c("project", "user")) {
  scope <- match.arg(scope)
  canonical_root <- canonical_skills_dir(skills_root(scope))
  if (!fs::dir_exists(canonical_root)) {
    return(character())
  }
  entries <- fs::dir_ls(canonical_root, type = "directory")
  fs::path_file(entries)
}
