#' Refresh the Claude Code copies of installed skills
#'
#' Walks every skill in `.agents/skills/` and (re)creates the
#' `.claude/skills/<skill>` copy, or link with `link = TRUE`, for each.
#' Useful after editing a skill by hand or deleting a copy. Codex reads
#' `.agents/skills/` directly, so no work is needed for it.
#'
#' Edit the `.agents/skills/` copy, not the Claude Code one: the Claude Code copy
#' is what gets replaced. A skill whose Claude Code copy has been edited is
#' skipped with a warning, unless `force = TRUE`.
#'
#' @inheritParams install_skill
#'
#' @return Invisibly, a list with one entry per skill describing the links
#'   created or refreshed.
#' @export
link_skills <- function(scope = c("project", "user"), link = FALSE, force = FALSE) {
  scope <- match.arg(scope)
  root <- skills_root(scope)
  canonical_root <- canonical_skills_dir(root)
  if (!fs::dir_exists(canonical_root)) {
    cli::cli_alert_info(
      "No skills found at {.path {pretty_path(canonical_root)}}."
    )
    return(invisible(list()))
  }

  skills <- names(skill_folders(canonical_root))
  if (length(skills) == 0) {
    cli::cli_alert_info("No skills installed.")
    return(invisible(list()))
  }

  results <- list()
  for (skill in skills) {
    changes <- if (force) character() else local_changes(skill, root, canonical = FALSE)
    if (length(changes) > 0) {
      cli::cli_warn(c(
        "Skipped {.val {skill}}, which has local changes.",
        change_bullets(changes),
        "i" = "Copy anything you want to keep, then use {.code force = TRUE} to overwrite it."
      ))
      next
    }
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
