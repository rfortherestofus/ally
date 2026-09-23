#' List installed skills
#'
#' Finds every skill on the computer that an agent can load, not just the ones
#' ally installed. It looks in the shared `.agents/skills/` folder and in each
#' agent's own folder (`.claude/skills/`, `.codex/skills/`, `.cursor/skills/`),
#' for the project, your home folder, or both. A folder counts as a skill when it
#' holds a `SKILL.md`, whether it is a real folder or a link to one.
#'
#' A skill that sits in several folders (the `.agents/skills/` copy and the
#' Claude Code copy ally makes, for instance) is listed once, with every folder
#' it was found in.
#'
#' The source comes from the first of these that has one: the
#' `.ally-source.json` that [install_skill()] writes, the lockfile the `skills`
#' command-line tool (`npx skills`) keeps at `.agents/.skill-lock.json`, or the
#' target of a link that points somewhere else. Skills copied in by hand have no
#' recorded source.
#'
#' Skills that come from Claude Code plugins live elsewhere and are not listed.
#'
#' @param scope Where to look: `"project"` (the working directory), `"user"`
#'   (your home folder), or both, the default.
#'
#' @return A tibble with one row per skill and columns:
#'   * `name`: the skill's folder name.
#'   * `description`: the `description` from the `SKILL.md` header, which agents
#'     read to decide when to use the skill.
#'   * `source`: where the skill came from, such as
#'     `"posit-dev/skills/r-lib/r-cli-app"`, or `NA` if nothing recorded it.
#'   * `installed_by`: `"ally"`, `"skills CLI"`, or `NA`.
#'   * `scope`: `"project"` or `"user"`.
#'   * `found_in`: the folders that hold the skill, such as `".agents, .claude"`.
#'   * `path`: the skill's folder, preferring the `.agents/skills/` copy.
#' @export
#' @examples
#' \dontrun{
#' installed_skills()
#' installed_skills(scope = "user")
#' }
installed_skills <- function(scope = c("project", "user")) {
  scope <- match.arg(scope, several.ok = TRUE)

  roots <- list(project = skills_root("project"), user = skills_root("user"))[scope]
  # Working in the home folder makes the project and user folders the same place.
  if (length(roots) == 2 && same_path(roots$project, roots$user)) {
    roots$project <- NULL
  }

  rows <- lapply(names(roots), function(s) scan_skills(roots[[s]], scope = s))
  skills <- do.call(rbind, c(list(empty_skills()), rows))
  skills <- skills[order(match(skills$scope, c("project", "user")), skills$name), ]
  tibble::as_tibble(skills)
}

#' Every skill under one scope root, one row per skill
#'
#' @keywords internal
#' @noRd
scan_skills <- function(root, scope) {
  found <- lapply(skill_locations(), function(location) {
    folders <- skill_folders(fs::path(root, location))
    if (length(folders) == 0) {
      return(NULL)
    }
    data.frame(
      name = names(folders),
      found_in = fs::path_dir(location),
      path = unname(folders),
      is_link = unname(fs::is_link(folders)),
      stringsAsFactors = FALSE
    )
  })
  found <- do.call(rbind, found)
  if (is.null(found)) {
    return(empty_skills())
  }

  lock <- read_skills_lock(root)

  # skill_locations() puts .agents/skills first, so the first row of each group
  # is the canonical copy whenever there is one.
  rows <- lapply(split(found, factor(found$name, unique(found$name))), function(copies) {
    main <- copies[1, ]
    origin <- skill_origin(main$path, main$is_link, lock[[main$name]])
    data.frame(
      name = main$name,
      description = skill_description(fs::path(main$path, "SKILL.md")),
      source = origin$source,
      installed_by = origin$installed_by,
      scope = scope,
      found_in = paste(unique(copies$found_in), collapse = ", "),
      path = main$path,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

#' Folders scanned for skills, relative to a scope root
#'
#' The shared folder comes first, then each agent's own folder.
#'
#' @keywords internal
#' @noRd
skill_locations <- function() {
  agent_dirs <- vapply(supported_agents(), function(agent) agent$skills_dir, character(1))
  unique(c(".agents/skills", unname(agent_dirs), ".codex/skills", ".cursor/skills"))
}

#' Skill folders (or links to them) directly inside `dir`, named by skill
#'
#' @keywords internal
#' @noRd
skill_folders <- function(dir) {
  if (!fs::dir_exists(dir)) {
    return(character())
  }
  entries <- fs::dir_ls(dir, type = c("directory", "symlink"))
  entries <- entries[!startsWith(fs::path_file(entries), ".")]
  entries <- entries[fs::file_exists(fs::path(entries, "SKILL.md"))]
  stats::setNames(as.character(entries), fs::path_file(entries))
}

#' Where a skill came from and what installed it
#'
#' @keywords internal
#' @noRd
skill_origin <- function(path, is_link, lock_entry) {
  metadata <- read_source_metadata(path)
  if (!is.null(metadata$source)) {
    return(list(source = metadata$source, installed_by = "ally"))
  }
  if (!is.null(lock_entry$source)) {
    return(list(source = lock_source(lock_entry), installed_by = "skills CLI"))
  }
  if (is_link) {
    return(list(source = pretty_path(fs::path_real(path)), installed_by = NA_character_))
  }
  list(source = NA_character_, installed_by = NA_character_)
}

#' Skills recorded by the `skills` command-line tool, keyed by skill name
#'
#' @keywords internal
#' @noRd
read_skills_lock <- function(root) {
  path <- fs::path(root, ".agents/.skill-lock.json")
  if (!fs::file_exists(path)) {
    return(list())
  }
  lock <- tryCatch(jsonlite::read_json(path), error = function(e) NULL)
  lock$skills %||% list()
}

#' A lockfile entry as `install_skill()` shorthand, such as `owner/repo/path/to/skill`
#'
#' @keywords internal
#' @noRd
lock_source <- function(entry) {
  if (identical(entry$sourceType, "github") && !is.null(entry$skillPath)) {
    skill_dir <- fs::path_dir(entry$skillPath)
    if (skill_dir != ".") {
      return(paste(entry$source, skill_dir, sep = "/"))
    }
  }
  entry$source
}

#' The `description` field from a SKILL.md header
#'
#' Falls back to reading the line directly when the header is not valid YAML,
#' which agents tolerate (an unquoted colon in the description, for instance).
#'
#' @keywords internal
#' @noRd
skill_description <- function(skill_md) {
  lines <- tryCatch(
    readLines(skill_md, warn = FALSE, encoding = "UTF-8"),
    error = function(e) character()
  )
  if (length(lines) < 2 || trimws(lines[1]) != "---") {
    return(NA_character_)
  }
  close <- which(trimws(lines[-1]) == "---")[1] + 1
  if (is.na(close) || close == 2) {
    return(NA_character_)
  }
  header <- lines[2:(close - 1)]

  parsed <- tryCatch(yaml::yaml.load(paste(header, collapse = "\n")), error = function(e) NULL)
  if (is.list(parsed)) {
    description <- parsed$description
  } else {
    line <- grep("^description:", header, value = TRUE)[1]
    description <- if (is.na(line)) NULL else sub("^description:\\s*", "", line)
    description <- gsub("^[\"']|[\"']$", "", description)
  }

  if (!is.character(description) || length(description) != 1 || !nzchar(description)) {
    return(NA_character_)
  }
  trimws(gsub("\\s+", " ", description))
}

#' @keywords internal
#' @noRd
empty_skills <- function() {
  data.frame(
    name = character(),
    description = character(),
    source = character(),
    installed_by = character(),
    scope = character(),
    found_in = character(),
    path = character(),
    stringsAsFactors = FALSE
  )
}

#' @keywords internal
#' @noRd
same_path <- function(a, b) {
  identical(as.character(fs::path_real(a)), as.character(fs::path_real(b)))
}
