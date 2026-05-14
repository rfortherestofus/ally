#' @keywords internal
#' @noRd
github_api_request <- function(url, query = list()) {
  req <- httr2::request(url) |>
    httr2::req_headers(
      Accept = "application/vnd.github+json",
      "X-GitHub-Api-Version" = "2022-11-28",
      "User-Agent" = "ally-r-package"
    )

  pat <- github_pat()
  if (!is.null(pat)) {
    req <- httr2::req_auth_bearer_token(req, pat)
  }

  if (length(query)) {
    req <- httr2::req_url_query(req, !!!query)
  }

  resp <- tryCatch(
    httr2::req_perform(req),
    httr2_http_403 = function(cnd) handle_rate_limit(cnd),
    httr2_http_404 = function(cnd) {
      cli::cli_abort("GitHub returned 404 for {.url {url}}.", parent = cnd)
    }
  )

  resp
}

#' @keywords internal
#' @noRd
github_pat <- function() {
  for (var in c("GITHUB_PAT", "GITHUB_TOKEN")) {
    val <- Sys.getenv(var, unset = "")
    if (nzchar(val)) {
      return(val)
    }
  }
  NULL
}

#' @keywords internal
#' @noRd
handle_rate_limit <- function(cnd) {
  cli::cli_abort(c(
    "GitHub API rate limit hit (or access denied).",
    "i" = if (is.null(github_pat())) {
      "Set {.envvar GITHUB_PAT} in your {.file .Renviron} to raise the limit."
    } else {
      "Your {.envvar GITHUB_PAT} may not have access to this repository."
    }
  ), parent = cnd)
}

#' @keywords internal
#' @noRd
github_contents_url <- function(owner, repo, path) {
  paste0(
    "https://api.github.com/repos/",
    owner, "/", repo, "/contents/",
    utils::URLencode(path)
  )
}

#' Download a directory from GitHub into `dest`
#'
#' Recursively walks the directory at `path` in the given repo and writes
#' every file under `dest`, preserving structure.
#'
#' @keywords internal
#' @noRd
github_download_dir <- function(owner, repo, path, dest, ref = NA_character_) {
  fs::dir_create(dest, recurse = TRUE)
  url <- github_contents_url(owner, repo, path)
  query <- if (!is.na(ref)) list(ref = ref) else list()
  resp <- github_api_request(url, query = query)
  entries <- httr2::resp_body_json(resp)

  if (is.null(entries) || (length(entries) > 0 && !is.null(entries$type) && length(entries$type) == 1)) {
    cli::cli_abort(c(
      "{.val {path}} is a file, not a directory.",
      "i" = "Point at a skill directory (one containing a {.file SKILL.md})."
    ))
  }

  for (entry in entries) {
    rel <- sub(paste0("^", path, "/?"), "", entry$path)
    target <- fs::path(dest, rel)

    if (identical(entry$type, "dir")) {
      fs::dir_create(target, recurse = TRUE)
      github_download_dir(owner, repo, entry$path, dest, ref = ref)
    } else if (identical(entry$type, "file")) {
      download_url <- entry$download_url
      if (is.null(download_url)) {
        cli::cli_abort("No download URL for {.val {entry$path}}.")
      }
      fs::dir_create(fs::path_dir(target), recurse = TRUE)
      download_file(download_url, target)
    }
  }

  invisible(dest)
}

#' @keywords internal
#' @noRd
download_file <- function(url, dest) {
  req <- httr2::request(url) |>
    httr2::req_headers("User-Agent" = "ally-r-package")
  pat <- github_pat()
  if (!is.null(pat) && grepl("api\\.github\\.com|raw\\.githubusercontent\\.com", url)) {
    req <- httr2::req_auth_bearer_token(req, pat)
  }
  resp <- httr2::req_perform(req)
  writeBin(httr2::resp_body_raw(resp), dest)
  invisible(dest)
}
