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
#' What installed a skill, where from, and when come from the first of these
#' that records it: the `.ally-source.json` that [install_skill()] writes, or the
#' lockfile the `skills` command-line tool (`npx skills`) keeps at
#' `.agents/.skill-lock.json`. A skill that is a link to a folder elsewhere shows
#' that folder as where it came from. Skills copied in by hand have none of this,
#' so their install date is the date their folder was created.
#'
#' For skills installed from GitHub, `installed_skills()` also looks up when the
#' skill's folder last changed there, using the repository's public commit feed.
#' That needs no token and does not count against the GitHub API rate limit. If
#' the date is newer than `installed`, [update_skill()] will fetch a newer
#' version.
#'
#' Skills that come from Claude Code plugins live elsewhere and are not listed.
#'
#' @param scope Where to look: `"project"` (the working directory), `"user"`
#'   (your home folder), or both, the default.
#' @param check_github If `TRUE`, the default, look up when each GitHub skill
#'   last changed. Set to `FALSE` to skip the lookup, when offline for instance.
#'
#' @return A tibble with one row per skill and columns:
#'   * `name`: the skill's folder name.
#'   * `description`: the start of the `description` from the `SKILL.md`
#'     header, which agents read to decide when to use the skill. The full text
#'     is in the `SKILL.md` at `path`.
#'   * `installed_by`: `"ally"`, `"skills CLI"`, or `NA` when nothing recorded it.
#'   * `installed_from`: the GitHub repository and folder, local path or link
#'     target the skill was installed from, such as
#'     `"posit-dev/skills/r-lib/r-cli-app"`, or `NA` when nothing recorded it.
#'   * `installed`: the date this copy was installed or last updated.
#'   * `updated_on_github`: the date the skill's folder last changed on GitHub,
#'     or `NA` for skills that did not come from GitHub.
#'   * `scope`: `"project"` or `"user"`.
#'   * `found_in`: the folders that hold the skill, such as `".agents, .claude"`.
#'   * `path`: the skill's folder, preferring the `.agents/skills/` copy.
#' @export
#' @examples
#' \dontrun{
#' installed_skills()
#' installed_skills(scope = "user", check_github = FALSE)
#' }
installed_skills <- function(scope = c("project", "user"), check_github = TRUE) {
  scope <- match.arg(scope, several.ok = TRUE)

  roots <- list(project = skills_root("project"), user = skills_root("user"))[scope]
  # Working in the home folder makes the project and user folders the same place.
  if (length(roots) == 2 && same_path(roots$project, roots$user)) {
    roots$project <- NULL
  }

  rows <- lapply(names(roots), function(s) {
    scan_skills(roots[[s]], scope = s, check_github = check_github)
  })
  skills <- do.call(rbind, c(list(empty_skills()), rows))
  skills <- skills[order(match(skills$scope, c("project", "user")), skills$name), ]
  tibble::as_tibble(skills)
}

#' Every skill under one scope root, one row per skill
#'
#' @keywords internal
#' @noRd
scan_skills <- function(root, scope, check_github = TRUE) {
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
    github <- origin$github
    data.frame(
      name = main$name,
      description = shorten(skill_description(fs::path(main$path, "SKILL.md"))),
      installed_by = origin$installed_by,
      installed_from = origin$installed_from,
      installed = timestamp_date(origin$installed_at) %|NA|% folder_date(main$path),
      updated_on_github = if (check_github && !is.null(github)) {
        github_last_changed(github$owner, github$repo, github$path, github$ref)
      } else {
        as.Date(NA)
      },
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

#' What installed a skill, where from, when, and its GitHub location if any
#'
#' @keywords internal
#' @noRd
skill_origin <- function(path, is_link, lock_entry) {
  metadata <- read_source_metadata(path)
  if (!is.null(metadata$source)) {
    github <- if (identical(metadata$type, "github")) {
      tryCatch(parse_source(metadata$source), error = function(e) NULL)
    }
    return(list(
      installed_by = "ally",
      installed_from = metadata$source,
      installed_at = metadata$installed_at %||% NA_character_,
      github = github
    ))
  }
  if (!is.null(lock_entry$source)) {
    return(list(
      installed_by = "skills CLI",
      installed_from = lock_source(lock_entry),
      installed_at = lock_entry$updatedAt %||% lock_entry$installedAt %||% NA_character_,
      github = lock_github(lock_entry)
    ))
  }
  list(
    installed_by = NA_character_,
    installed_from = if (is_link) pretty_path(fs::path_real(path)) else NA_character_,
    installed_at = NA_character_,
    github = NULL
  )
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

#' Where a `skills` CLI lockfile entry lives on GitHub, or `NULL`
#'
#' @keywords internal
#' @noRd
lock_github <- function(entry) {
  parts <- strsplit(entry$source, "/", fixed = TRUE)[[1]]
  if (!identical(entry$sourceType, "github") || length(parts) != 2) {
    return(NULL)
  }
  skill_dir <- if (is.null(entry$skillPath)) "." else fs::path_dir(entry$skillPath)
  list(
    owner = parts[1],
    repo = parts[2],
    path = if (skill_dir == ".") "" else as.character(skill_dir),
    ref = NA_character_
  )
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

#' Cut text to `width` characters, ending in an ellipsis when shortened
#'
#' @keywords internal
#' @noRd
shorten <- function(x, width = 50) {
  long <- !is.na(x) & nchar(x) > width
  x[long] <- paste0(trimws(substr(x[long], 1, width - 1)), "\u2026")
  x
}

#' The date part of an ISO 8601 timestamp such as `2026-05-14T11:22:37-0700`
#'
#' @keywords internal
#' @noRd
timestamp_date <- function(x) {
  if (is.null(x) || is.na(x) || !grepl("^\\d{4}-\\d{2}-\\d{2}", x)) {
    return(as.Date(NA))
  }
  as.Date(substr(x, 1, 10))
}

#' The date a skill folder was created, or last modified where creation times
#' are not recorded
#'
#' @keywords internal
#' @noRd
folder_date <- function(path) {
  info <- fs::file_info(fs::path_real(path))
  time <- info$birth_time
  if (is.na(time)) {
    time <- info$modification_time
  }
  as.Date(time, tz = Sys.timezone())
}

`%|NA|%` <- function(x, y) if (is.na(x)) y else x

#' @keywords internal
#' @noRd
empty_skills <- function() {
  data.frame(
    name = character(),
    description = character(),
    installed_by = character(),
    installed_from = character(),
    installed = as.Date(character()),
    updated_on_github = as.Date(character()),
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
