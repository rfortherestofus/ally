#' Re-link installed skills to Claude Code
#'
#' Walks every skill in `.agents/skills/` and (re)creates the
#' `.claude/skills/<skill>` symlink for each. Useful if a symlink was
#' deleted manually. Codex reads `.agents/skills/` natively, so no work is
#' needed for it.
#'
#' @inheritParams install_skill
#'
#' @return Invisibly, a list with one entry per skill describing the links
#'   created or refreshed.
#' @export
link_skills <- function(copy = FALSE) {
  root <- getwd()
  canonical_root <- canonical_skills_dir(root)
  if (!fs::dir_exists(canonical_root)) {
    cli::cli_alert_info(
      "No skills found at {.path {pretty_path(canonical_root)}}."
    )
    return(invisible(list()))
  }

  skills <- installed_skills()
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
      copy = copy
    )
  }
  invisible(results)
}

#' List installed skills
#'
#' @return Character vector of skill names found in `.agents/skills/`.
#' @export
installed_skills <- function() {
  canonical_root <- canonical_skills_dir(getwd())
  if (!fs::dir_exists(canonical_root)) {
    return(character())
  }
  entries <- fs::dir_ls(canonical_root, type = "directory")
  fs::path_file(entries)
}
