#' Agents that need a symlink
#'
#' `ally` stores skills at `.agents/skills/<skill>`, which Codex auto-discovers
#' natively. Other agents read from their own folders, so they need a symlink
#' pointing back to the canonical copy. This list enumerates those agents.
#'
#' @return A named list of agent definitions.
#' @export
supported_agents <- function() {
  list(
    claude = list(
      id = "claude",
      name = "Claude Code",
      project_skills_dir = ".claude/skills"
    )
  )
}
