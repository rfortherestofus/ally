#' Download a skill folder from a GitHub repository into `dest`
#'
#' Fetches the repository's zip archive from `github.com/<owner>/<repo>/archive/<ref>.zip`,
#' which is a single download that needs no token and is not counted against the GitHub
#' API rate limit, then copies the skill folder out of it. `path` may be `""` for a skill
#' whose `SKILL.md` sits at the top of the repository.
#'
#' @keywords internal
#' @noRd
github_download_dir <- function(owner, repo, path, dest, ref = NA_character_) {
  ref <- if (is.na(ref) || !nzchar(ref)) "HEAD" else ref
  label <- paste0(owner, "/", repo, if (ref != "HEAD") paste0("@", ref) else "")

  archive <- github_download_archive(owner, repo, ref, label)
  extracted <- unzip_archive(archive)
  source_dir <- if (nzchar(path)) fs::path(extracted, path) else extracted

  if (!fs::dir_exists(source_dir)) {
    cli::cli_abort(c(
      "No folder {.path {path}} in {.val {label}}.",
      "i" = "Check the path against the repository on GitHub."
    ))
  }

  fs::dir_create(fs::path_dir(dest), recurse = TRUE)
  fs::dir_copy(source_dir, dest, overwrite = TRUE)
  invisible(dest)
}

#' @keywords internal
#' @noRd
github_download_archive <- function(owner, repo, ref, label) {
  url <- paste0("https://github.com/", owner, "/", repo, "/archive/", ref, ".zip")
  archive <- withr::local_tempfile(fileext = ".zip", .local_envir = parent.frame())

  ok <- tryCatch(
    {
      utils::download.file(url, archive, mode = "wb", quiet = TRUE)
      TRUE
    },
    error = function(e) FALSE,
    warning = function(w) FALSE
  )

  if (!ok || !fs::file_exists(archive) || fs::file_size(archive) == 0) {
    cli::cli_abort(c(
      "Could not download {.val {label}} from GitHub.",
      "i" = "Check that the repository is public and that {.val {ref}} is a branch, tag or commit.",
      "i" = "Tried {.url {url}}."
    ))
  }

  archive
}

#' Unzip a GitHub archive and return its single top-level folder
#'
#' @keywords internal
#' @noRd
unzip_archive <- function(archive) {
  exdir <- withr::local_tempdir(.local_envir = parent.frame())
  utils::unzip(archive, exdir = exdir)

  top <- fs::dir_ls(exdir, type = "directory")
  if (length(top) != 1) {
    cli::cli_abort("Unexpected archive layout: expected one top-level folder, found {length(top)}.")
  }

  top
}

#' The date a skill folder last changed on GitHub
#'
#' Reads the repository's commit feed for the folder,
#' `github.com/<owner>/<repo>/commits/<ref>/<path>.atom`, which needs no token and is
#' not counted against the GitHub API rate limit. Returns `NA` when the feed cannot be
#' read, when offline for instance.
#'
#' @keywords internal
#' @noRd
github_last_changed <- function(owner, repo, path, ref = NA_character_) {
  ref <- if (is.na(ref) || !nzchar(ref)) "HEAD" else ref
  url <- paste0(
    "https://github.com/", owner, "/", repo, "/commits/", ref,
    if (nzchar(path)) paste0("/", utils::URLencode(path)) else "",
    ".atom"
  )
  feed <- withr::local_tempfile(fileext = ".atom")
  withr::local_options(timeout = 10)

  ok <- tryCatch(
    {
      utils::download.file(url, feed, quiet = TRUE)
      TRUE
    },
    error = function(e) FALSE,
    warning = function(w) FALSE
  )
  if (!ok) {
    return(as.Date(NA))
  }
  atom_last_updated(readLines(feed, warn = FALSE, encoding = "UTF-8"))
}

#' The `<updated>` date of the newest entry in a GitHub commit feed
#'
#' @keywords internal
#' @noRd
atom_last_updated <- function(lines) {
  text <- paste(lines, collapse = "\n")
  entry_start <- regexpr("<entry>", text, fixed = TRUE)
  if (entry_start < 0) {
    return(as.Date(NA))
  }
  entry <- substring(text, entry_start)
  updated <- regmatches(entry, regexpr("<updated>[^<]+</updated>", entry))
  if (length(updated) == 0) {
    return(as.Date(NA))
  }
  timestamp_date(gsub("</?updated>", "", updated))
}
