#' @keywords internal
#' @noRd
canonical_skills_dir <- function(root = getwd()) {
  fs::path(root, ".agents/skills")
}

#' @keywords internal
#' @noRd
agent_skills_dir <- function(agent, root = getwd()) {
  fs::path(root, agent$project_skills_dir)
}

#' @keywords internal
#' @noRd
parse_source <- function(source) {
  source <- trimws(source)

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
  if (length(parts) < 3 || any(nchar(parts) == 0)) {
    cli::cli_abort(c(
      "Invalid source {.val {source}}.",
      "i" = "Expected GitHub shorthand {.val owner/repo/skill-name} or a local path."
    ))
  }

  list(
    type = "github",
    owner = parts[1],
    repo = parts[2],
    path = paste(parts[-(1:2)], collapse = "/"),
    ref = ref,
    skill_name = parts[length(parts)]
  )
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
