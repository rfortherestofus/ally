#' Install an AI coding assistant skill
#'
#' Downloads (or copies) a skill into `.agents/skills/<skill-name>/`, the shared folder
#' that Codex and other agents read directly, and into `.claude/skills/<skill-name>/`
#' for Claude Code. With `scope = "project"` (the default) both folders sit in the
#' current working directory and the skill travels with the project. With
#' `scope = "user"` they sit in your home folder and every project on the computer can
#' use the skill.
#'
#' GitHub skills are fetched from the repository's zip archive: one download, no token,
#' no API rate limit. Public repositories only.
#'
#' @param source One of:
#'   * A full GitHub URL, pasted straight from the browser, e.g.
#'     `https://github.com/owner/repo/tree/main/path/to/skill`. A link to the
#'     `SKILL.md` itself also works, and so does a repository whose `SKILL.md`
#'     sits at the top level (the skill is then named after the repository).
#'     Refs containing `/` (e.g. `release/v1`) cannot be disambiguated from a
#'     URL; use the shorthand `owner/repo/path@release/v1` instead.
#'   * GitHub shorthand `owner/repo/path/to/skill` (optionally `@ref` for a
#'     branch, tag or commit), or just `owner/repo` for a top-level skill.
#'   * A local filesystem path to a skill directory.
#' @param scope `"project"` installs into the current working directory,
#'   `"user"` into your home folder.
#' @param link   If `TRUE`, put a relative symbolic link in each agent folder
#'   pointing at the `.agents/skills` copy instead of a second copy, so there is a
#'   single set of files to edit. Falls back to copying where links can't be
#'   created (typically Windows without developer mode). The default, `FALSE`,
#'   copies.
#'
#' @return Invisibly, a list describing the install.
#' @export
#'
#' @examples
#' \dontrun{
#' # Paste the SKILL.md link from GitHub
#' install_skill(
#'   "https://github.com/posit-dev/skills/blob/main/r-lib/r-cli-app/SKILL.md"
#' )
#'
#' # Make it available to every project on this computer
#' install_skill("posit-dev/skills/r-lib/r-cli-app", scope = "user")
#'
#' # Local path
#' install_skill("~/my-skills/r-style-guide")
#' }
install_skill <- function(source, scope = c("project", "user"), link = FALSE) {
  scope <- match.arg(scope)
  parsed <- parse_source(source)
  skill_name <- parsed$skill_name

  root <- skills_root(scope)
  canonical_root <- canonical_skills_dir(root)
  skill_dir <- fs::path(canonical_root, skill_name)

  staging <- withr::local_tempfile()
  fetch_skill(parsed, staging)

  if (!fs::file_exists(fs::path(staging, "SKILL.md"))) {
    cli::cli_abort(c(
      "{.val {source}} does not contain a {.file SKILL.md}.",
      "i" = "Point at the folder that holds the skill's {.file SKILL.md}."
    ))
  }

  fs::dir_create(canonical_root, recurse = TRUE)
  if (fs::dir_exists(skill_dir)) {
    fs::dir_delete(skill_dir)
  }
  fs::dir_copy(staging, skill_dir)
  write_source_metadata(skill_dir, parsed)

  cli::cli_alert_success(
    "Installed {.val {skill_name}} to {.path {pretty_path(skill_dir)}}"
  )
  if (scope == "project") {
    cli::cli_alert_info(
      "Codex and other agents read {.path .agents/skills/} directly."
    )
  } else {
    cli::cli_alert_info(
      "Every project on this computer can use skills in {.path ~/.agents/skills/}."
    )
  }

  links <- link_skill_to_agents(
    skill_dir = skill_dir,
    skill_name = skill_name,
    root = root,
    link = link
  )

  invisible(list(
    skill = skill_name,
    skill_dir = skill_dir,
    scope = scope,
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
                                 link = FALSE) {
  results <- list()

  for (agent in supported_agents()) {
    agent_dir <- agent_skills_dir(agent, root = root)
    link_path <- fs::path(agent_dir, skill_name)

    res <- link_or_copy(skill_dir, link_path, force_copy = !link)

    cli::cli_alert_success(
      "{if (res$mode == 'symlink') 'Linked' else 'Copied'} to {.val {agent$name}} ({.path {pretty_path(agent_dir)}})"
    )
    results[[agent$id]] <- c(list(agent = agent$id), res)
  }

  results
}
