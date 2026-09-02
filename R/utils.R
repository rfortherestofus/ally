#' @keywords internal
#' @noRd
parse_source <- function(source) {
  source <- trimws(source)

  if (grepl("^https?://github\\.com/", source, ignore.case = TRUE)) {
    return(parse_github_url(source))
  }

  is_local <- startsWith(source, "/") ||
    startsWith(source, "~") ||
    startsWith(source, ".") ||
    grepl("^[A-Za-z]:[\\/]", source)

  if (is_local) {
    expanded <- fs::path_expand(source)
    return(list(
      type = "local",
      path = expanded,
      skill_name = fs::path_file(expanded)
    ))
  }

  ref <- NA_character_
  if (grepl("@", source, fixed = TRUE)) {
    parts <- strsplit(source, "@", fixed = TRUE)[[1]]
    if (length(parts) != 2 || nchar(parts[2]) == 0) {
      cli::cli_abort("Invalid source {.val {source}}: expected `owner/repo/path[@ref]`.")
    }
    source <- parts[1]
    ref <- parts[2]
  }

  parts <- strsplit(source, "/", fixed = TRUE)[[1]]
  if (length(parts) < 2 || any(nchar(parts) == 0)) {
    cli::cli_abort(c(
      "Invalid source {.val {source}}.",
      "i" = "Expected GitHub shorthand {.val owner/repo/skill-name}, a GitHub URL, or a local path."
    ))
  }

  github_source(owner = parts[1], repo = parts[2], path_parts = parts[-(1:2)], ref = ref)
}

#' A GitHub source, named after the skill folder or, for a top-level skill, the repository
#'
#' @keywords internal
#' @noRd
github_source <- function(owner, repo, path_parts, ref = NA_character_) {
  if (length(path_parts) > 0 && path_parts[length(path_parts)] == "SKILL.md") {
    path_parts <- path_parts[-length(path_parts)]
  }

  list(
    type = "github",
    owner = owner,
    repo = repo,
    path = paste(path_parts, collapse = "/"),
    ref = ref,
    skill_name = if (length(path_parts) > 0) path_parts[length(path_parts)] else repo
  )
}

#' @keywords internal
#' @noRd
parse_github_url <- function(url) {
  url <- trimws(url)
  original <- url
  url <- sub("^https?://github\\.com/", "", url, ignore.case = TRUE)
  url <- sub("\\?.*$", "", url)
  url <- sub("#.*$", "", url)
  url <- sub("/+$", "", url)

  parts <- strsplit(url, "/", fixed = TRUE)[[1]]
  parts <- parts[nzchar(parts)]

  if (length(parts) < 2) {
    cli::cli_abort(c(
      "Invalid GitHub URL {.val {original}}.",
      "i" = "Expected {.val https://github.com/owner/repo/tree/<ref>/path/to/skill}."
    ))
  }

  owner <- parts[1]
  repo <- sub("\\.git$", "", parts[2])

  # https://github.com/owner/repo is a top-level skill at the default branch.
  if (length(parts) == 2) {
    return(github_source(owner, repo, character(), ref = NA_character_))
  }

  if (length(parts) < 4 || !(parts[3] %in% c("blob", "tree"))) {
    cli::cli_abort(c(
      "Invalid GitHub URL {.val {original}}.",
      "i" = "Expected {.val https://github.com/owner/repo/tree/<ref>/path/to/skill}."
    ))
  }

  github_source(owner, repo, parts[-(1:4)], ref = parts[4])
}

#' @keywords internal
#' @noRd
write_source_metadata <- function(skill_dir, parsed) {
  metadata <- list(
    source = if (parsed$type == "github") {
      base <- paste(parsed$owner, parsed$repo, parsed$path, sep = "/")
      if (!is.na(parsed$ref)) paste0(base, "@", parsed$ref) else base
    } else {
      parsed$path
    },
    type = parsed$type,
    skill_name = parsed$skill_name,
    installed_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  )
  jsonlite::write_json(
    metadata,
    fs::path(skill_dir, ".ally-source.json"),
    auto_unbox = TRUE,
    pretty = TRUE
  )
  invisible(metadata)
}

#' @keywords internal
#' @noRd
read_source_metadata <- function(skill_dir) {
  path <- fs::path(skill_dir, ".ally-source.json")
  if (!fs::file_exists(path)) {
    return(NULL)
  }
  jsonlite::read_json(path, simplifyVector = TRUE)
}

#' @keywords internal
#' @noRd
pretty_path <- function(path) {
  home <- fs::path_expand("~")
  sub(paste0("^", home), "~", path)
}

`%||%` <- function(x, y) if (is.null(x)) y else x
