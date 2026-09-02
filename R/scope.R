#' Where skills live for a scope
#'
#' `"project"` skills live under the working directory and travel with the project.
#' `"user"` skills live under the home folder and are available to every project on
#' the computer. Either way the canonical copy is `.agents/skills/<skill>` and each
#' agent that reads its own folder gets a link back to it.
#'
#' @keywords internal
#' @noRd
skills_root <- function(scope = c("project", "user")) {
  scope <- match.arg(scope)
  if (scope == "user") fs::path_home() else fs::path(getwd())
}

#' @keywords internal
#' @noRd
canonical_skills_dir <- function(root = getwd()) {
  fs::path(root, ".agents/skills")
}

#' @keywords internal
#' @noRd
agent_skills_dir <- function(agent, root = getwd()) {
  fs::path(root, agent$skills_dir)
}
