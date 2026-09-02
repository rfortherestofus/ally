#' Agents that need a link
#'
#' `ally` stores skills at `.agents/skills/<skill>`, the shared folder that Codex and a
#' growing number of agents read directly. Agents that only read their own folder get a
#' link there pointing back to the canonical copy. This list enumerates those agents.
#' The folder is relative to the scope root: the project for `scope = "project"`, the
#' home folder for `scope = "user"`.
#'
#' @return A named list of agent definitions.
#' @export
supported_agents <- function() {
  list(
    claude = list(
      id = "claude",
      name = "Claude Code",
      skills_dir = ".claude/skills"
    )
  )
}
