#' A fingerprint of a skill folder's contents
#'
#' The MD5 hash of every file's path and contents, so any edit, added file or
#' removed file changes it. Line endings are ignored, so a skill checked out with
#' git on Windows matches the same skill on macOS. `.ally-source.json` and
#' `.DS_Store` are left out.
#'
#' @keywords internal
#' @noRd
skill_hash <- function(dir) {
  files <- fs::dir_ls(dir, recurse = TRUE, type = "file", all = TRUE)
  relative <- as.character(fs::path_rel(files, dir))
  keep <- !fs::path_file(relative) %in% c(".ally-source.json", ".DS_Store")
  files <- files[keep]
  relative <- relative[keep]

  sorted <- order(relative, method = "radix")
  sums <- vapply(files[sorted], function(file) {
    bytes <- readBin(file, "raw", n = as.numeric(fs::file_size(file)))
    cli::hash_raw_md5(bytes[bytes != as.raw(13)])
  }, character(1))
  cli::hash_md5(paste(relative[sorted], sums, collapse = "\n"))
}

#' Whether a copy of a skill holds changes that overwriting it would lose
#'
#' Returns `"ok"` when the copy matches what was installed, or matches
#' `canonical_hash` (the `.agents/skills` copy it is refreshed from); `"edited"`
#' when it matches neither; `"unknown"` when ally installed it before it recorded
#' fingerprints; and `"foreign"` when ally did not install it.
#'
#' @keywords internal
#' @noRd
copy_status <- function(dir, canonical_hash = NULL) {
  metadata <- read_source_metadata(dir)
  if (is.null(metadata)) {
    return("foreign")
  }
  if (is.null(metadata$files_hash)) {
    return("unknown")
  }
  hash <- skill_hash(dir)
  if (identical(hash, metadata$files_hash) || identical(hash, canonical_hash)) "ok" else "edited"
}

#' Copies of a skill that reinstalling or relinking it would overwrite with loss
#'
#' Checks the `.agents/skills` copy when `canonical` is `TRUE`, and each agent's
#' copy (links are only replaced, never followed, so they are skipped). Returns a
#' named character vector: the problem for each affected path.
#'
#' @keywords internal
#' @noRd
local_changes <- function(skill_name, root, canonical = TRUE) {
  skill_dir <- fs::path(canonical_skills_dir(root), skill_name)
  has_canonical <- fs::dir_exists(skill_dir)
  canonical_hash <- if (has_canonical) skill_hash(skill_dir)

  paths <- character()
  statuses <- character()
  if (canonical && has_canonical) {
    paths <- c(paths, skill_dir)
    statuses <- c(statuses, copy_status(skill_dir))
  }
  for (agent in supported_agents()) {
    copy <- fs::path(agent_skills_dir(agent, root = root), skill_name)
    if (fs::dir_exists(copy) && !fs::is_link(copy)) {
      paths <- c(paths, copy)
      statuses <- c(statuses, copy_status(copy, canonical_hash))
    }
  }

  problems <- c(
    edited = "has been edited since it was installed.",
    foreign = "was not installed by ally, so it may hold work of its own."
  )
  flagged <- statuses %in% names(problems)
  stats::setNames(unname(problems[statuses[flagged]]), paths[flagged])
}

#' Bullets describing local changes, for an error or warning
#'
#' @keywords internal
#' @noRd
change_bullets <- function(changes) {
  bullets <- vapply(names(changes), function(path) {
    text <- paste(cli::format_inline("{.path {pretty_path(path)}}"), changes[[path]])
    gsub("}", "}}", gsub("{", "{{", text, fixed = TRUE), fixed = TRUE)
  }, character(1))
  stats::setNames(unname(bullets), rep("x", length(bullets)))
}

#' @keywords internal
#' @noRd
abort_local_changes <- function(skill_name, changes, call = parent.frame()) {
  cli::cli_abort(
    c(
      "Not overwriting {.val {skill_name}}, which has local changes.",
      change_bullets(changes),
      "i" = "Copy anything you want to keep, then run again with {.code force = TRUE} to overwrite it."
    ),
    call = call
  )
}
