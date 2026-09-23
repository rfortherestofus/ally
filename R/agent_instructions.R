#' List agent instruction files
#'
#' Shows the instruction files your AI coding assistants read: the Markdown
#' files where you tell an agent how you like to work (`CLAUDE.md` for Claude
#' Code, `AGENTS.md` for Codex, Posit Assistant and others). Instructions can
#' apply to every project on the computer (`"user"`, in your home folder) or to
#' one project (`"project"`, in the working directory).
#'
#' The main file for each agent is always listed, marked "not found" when it
#' does not exist yet, so you can see where it would go:
#'
#' * User: `~/.claude/CLAUDE.md` (Claude Code), `~/.codex/AGENTS.md` (Codex)
#'   and `~/.posit/assistant/AGENTS.md` (Posit Assistant). Only agents
#'   installed on this computer are listed, judged by whether their folder
#'   (`~/.claude`, `~/.codex`, `~/.posit`) exists.
#' * Project: `AGENTS.md`, read by Codex and Posit Assistant, and by Claude
#'   Code when the project has no `CLAUDE.md`; and `CLAUDE.md`, read by Claude
#'   Code.
#'
#' Less common files are listed only when they exist: `~/.codex/AGENTS.override.md`,
#' `.claude/CLAUDE.md` and `CLAUDE.local.md`.
#'
#' If a project has both an `AGENTS.md` and a `CLAUDE.md`, Claude Code reads only
#' the `CLAUDE.md`, and a note says so. A `CLAUDE.md` that contains the line
#' `@AGENTS.md` pulls the `AGENTS.md` in, so there is no note.
#'
#' Nothing is created or changed. Use [edit_agent_instructions()] to open a file.
#'
#' @param scope Where to look: `"user"` (your home folder), `"project"` (the
#'   working directory), or both, the default.
#'
#' @return Invisibly, a tibble with one row per file, in the order shown, and
#'   columns:
#'   * `scope`: `"user"` or `"project"`.
#'   * `agent`: the name [edit_agent_instructions()] takes for the file:
#'     `"claude"`, `"codex"`, `"posit"` or `"agents"`.
#'   * `read_by`: the agents that read the file.
#'   * `path`: the full path to the file.
#'   * `exists`: whether the file exists.
#'   * `lines`: how many lines the file has, or `NA` when it does not exist.
#' @export
#' @examples
#' \dontrun{
#' list_agent_instructions()
#' list_agent_instructions(scope = "user")
#' }
list_agent_instructions <- function(scope = c("user", "project")) {
  scope <- match.arg(scope, several.ok = TRUE)
  found <- scan_instructions(scope)

  cli::cli_h1("Agent instructions")
  show_instructions(found$files)
  show_instruction_notes(found$notes)

  files <- found$files
  files$main <- NULL
  invisible(tibble::as_tibble(files))
}

#' Open an agent instruction file
#'
#' Opens one of the files [list_agent_instructions()] shows, in Positron or
#' RStudio when you are working in one, or in R's own editor otherwise.
#'
#' Run it with no arguments to pick from a numbered list. Or name the file by the
#' agent that reads it: `"claude"` for Claude Code, `"codex"` for Codex, `"posit"`
#' for Posit Assistant, or `"agents"` for the project's shared `AGENTS.md`. When
#' that still matches more than one file (Claude Code has one for you and one for
#' the project, for instance), you pick from a short list, or narrow it with
#' `scope`.
#'
#' If the file does not exist yet, you are asked whether to create it, empty.
#' Existing files are only opened, never changed.
#'
#' @param agent `NULL`, the default, to pick from every listed file, or one of
#'   `"claude"`, `"codex"`, `"posit"` or `"agents"`.
#' @inheritParams list_agent_instructions
#'
#' @return Invisibly, the path of the file opened, or `NULL` when nothing was.
#' @export
#' @examples
#' \dontrun{
#' # Pick from a numbered list
#' edit_agent_instructions()
#'
#' # Claude Code's instructions for every project
#' edit_agent_instructions("claude", scope = "user")
#'
#' # The project's AGENTS.md
#' edit_agent_instructions("agents")
#' }
edit_agent_instructions <- function(agent = NULL, scope = c("user", "project")) {
  scope <- match.arg(scope, several.ok = TRUE)

  if (is.null(agent)) {
    files <- scan_instructions(scope)$files
    path <- choose_instruction_file(files, "Pass {.arg agent} to name a file.")
  } else {
    agent <- match.arg(agent, c("claude", "codex", "posit", "agents"))
    files <- scan_instructions(scope, installed_only = FALSE)$files
    files <- files[files$agent == agent, ]
    if (nrow(files) == 0) {
      cli::cli_abort(c(
        "{.val {agent}} has no {scope} instructions file.",
        "i" = "Codex and Posit Assistant read the project's {.file AGENTS.md}: use {.code agent = \"agents\"}."
      ))
    }
    # Existing files first; the main ones only when none exist yet.
    if (any(files$exists)) {
      files <- files[files$exists, ]
    } else {
      files <- files[files$main, ]
    }
    path <- if (nrow(files) == 1) {
      files$path
    } else {
      choose_instruction_file(files, "Pass {.arg scope} to pick one.")
    }
  }

  if (is.null(path)) {
    cli::cli_alert_info("Nothing opened.")
    return(invisible(NULL))
  }

  if (!fs::file_exists(path)) {
    if (!is_interactive()) {
      cli::cli_abort(c(
        "{.path {pretty_path(path)}} does not exist.",
        "i" = "Run {.fn edit_agent_instructions} in an interactive session to create it."
      ))
    }
    if (!ask_yes_no(paste0(pretty_path(path), " does not exist yet. Create it?"))) {
      cli::cli_alert_info("Nothing created.")
      return(invisible(NULL))
    }
    fs::dir_create(fs::path_dir(path), recurse = TRUE)
    fs::file_create(path)
    cli::cli_alert_success("Created {.path {pretty_path(path)}}")
  }

  cli::cli_alert_success("Opening {.path {pretty_path(path)}}")
  open_file(path)
  invisible(path)
}

#' Every instruction file ally knows about
#'
#' `main` files are always listed; the others only when they exist. `agent_dir`
#' is the folder whose existence means the agent is installed (user scope only).
#'
#' @keywords internal
#' @noRd
instruction_locations <- function() {
  data.frame(
    scope = c("user", "user", "user", "user", "project", "project", "project", "project"),
    agent = c("claude", "codex", "codex", "posit", "agents", "claude", "claude", "claude"),
    file = c(
      ".claude/CLAUDE.md", ".codex/AGENTS.md", ".codex/AGENTS.override.md",
      ".posit/assistant/AGENTS.md", "AGENTS.md", "CLAUDE.md", ".claude/CLAUDE.md",
      "CLAUDE.local.md"
    ),
    read_by = c(
      "Claude Code", "Codex", "Codex (overrides AGENTS.md)", "Posit Assistant",
      "Codex, Posit Assistant", "Claude Code", "Claude Code", "Claude Code (just you)"
    ),
    main = c(TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, FALSE, FALSE),
    agent_dir = c(".claude", ".codex", ".codex", ".posit", NA, NA, NA, NA),
    stringsAsFactors = FALSE
  )
}

#' Find the instruction files for the given scopes
#'
#' @return A list with `files`, a data frame of the rows to show, and `notes`, a
#'   character vector of things worth pointing out.
#' @keywords internal
#' @noRd
scan_instructions <- function(scope = c("user", "project"), installed_only = TRUE) {
  locations <- instruction_locations()
  locations <- locations[locations$scope %in% scope, ]
  locations <- locations[order(match(locations$scope, c("user", "project"))), ]

  root <- ifelse(locations$scope == "user", fs::path_home(), getwd())
  path <- as.character(fs::path(root, locations$file))
  exists <- fs::file_exists(path)
  installed <- vapply(seq_along(path), function(i) {
    is.na(locations$agent_dir[i]) || fs::dir_exists(fs::path(root[i], locations$agent_dir[i]))
  }, logical(1))

  keep <- (locations$main | exists) & (installed | !installed_only)
  files <- data.frame(
    scope = locations$scope,
    agent = locations$agent,
    read_by = locations$read_by,
    path = path,
    exists = unname(exists),
    lines = vapply(path, count_lines, integer(1), USE.NAMES = FALSE),
    main = locations$main,
    stringsAsFactors = FALSE
  )[keep, ]
  rownames(files) <- NULL

  notes <- character()
  if ("project" %in% scope) {
    # Claude Code falls back to AGENTS.md only when none of its own project
    # files exist.
    claude_files <- path[locations$scope == "project" & locations$agent == "claude"]
    claude_files <- claude_files[fs::file_exists(claude_files)]
    agents_md <- files$scope == "project" & files$agent == "agents"
    if (length(claude_files) == 0) {
      files$read_by[agents_md] <- paste0(files$read_by[agents_md], ", Claude Code")
    } else if (any(files$exists[agents_md]) && !any(vapply(claude_files, imports_agents_md, logical(1)))) {
      claude_md <- as.character(fs::path_rel(claude_files[1], getwd()))
      notes <- c(
        notes,
        paste0(
          "Claude Code reads {.file ", claude_md, "} in this project, not {.file AGENTS.md}. ",
          "To share {.file AGENTS.md} with it, add the line {.code @AGENTS.md} to {.file ", claude_md, "}."
        )
      )
    }
  }

  list(files = files, notes = notes)
}

#' Does a CLAUDE.md pull in the project's AGENTS.md with an `@` import?
#'
#' @keywords internal
#' @noRd
imports_agents_md <- function(path) {
  lines <- readLines(path, warn = FALSE)
  any(grepl("^\\s*@(\\./)?AGENTS\\.md\\s*$", lines))
}

#' @keywords internal
#' @noRd
count_lines <- function(path) {
  if (!fs::file_exists(path)) {
    return(NA_integer_)
  }
  length(readLines(path, warn = FALSE))
}

#' Print the files as a numbered list, grouped by scope
#'
#' @keywords internal
#' @noRd
show_instructions <- function(files) {
  if (nrow(files) == 0) {
    cli::cli_alert_info("No agent instruction files to show.")
    return(invisible())
  }

  number <- paste0(seq_len(nrow(files)), ":")
  number <- formatC(number, width = max(nchar(number)))
  read_by <- cli::ansi_align(files$read_by, width = max(cli::ansi_nchar(files$read_by)))
  shown_path <- ifelse(
    files$scope == "project",
    as.character(fs::path_rel(files$path, getwd())),
    pretty_path(files$path)
  )
  shown_path <- cli::ansi_align(shown_path, width = max(cli::ansi_nchar(shown_path)))
  status <- ifelse(
    files$exists,
    paste(files$lines, ifelse(files$lines == 1, "line", "lines")),
    cli::col_grey("not found")
  )
  rows <- paste(number, paste(read_by, shown_path, status, sep = "  "))

  for (s in unique(files$scope)) {
    heading <- if (s == "user") {
      "User (all projects)"
    } else {
      paste0("Project (", basename(getwd()), ")")
    }
    cli::cli_h2(heading)
    cli::cli_verbatim(rows[files$scope == s])
  }
  invisible()
}

#' @keywords internal
#' @noRd
show_instruction_notes <- function(notes) {
  if (length(notes) > 0) {
    cli::cli_text("")
  }
  for (note in notes) {
    cli::cli_alert_warning(note)
  }
}

#' Show a numbered list of files and ask for one
#'
#' @return The chosen path, or `NULL` when the user picks nothing.
#' @keywords internal
#' @noRd
choose_instruction_file <- function(files, hint) {
  if (!is_interactive()) {
    cli::cli_abort(c("Can't ask which file to open outside an interactive session.", "i" = hint))
  }
  cli::cli_text("Which instructions do you want to edit?")
  show_instructions(files)
  choice <- ask_number(nrow(files))
  if (is.na(choice)) {
    return(NULL)
  }
  files$path[choice]
}

# Thin wrappers around the interactive bits, so tests can stand in for them.

#' @keywords internal
#' @noRd
is_interactive <- function() {
  interactive()
}

#' Read a number from 1 to `n`; blank or 0 means none
#'
#' @keywords internal
#' @noRd
ask_number <- function(n) {
  answer <- trimws(readline("Selection (blank to cancel): "))
  if (answer %in% c("", "0")) {
    return(NA_integer_)
  }
  choice <- suppressWarnings(as.integer(answer))
  if (is.na(choice) || choice < 1 || choice > n) {
    cli::cli_abort("Pick a number from 1 to {n}.")
  }
  choice
}

#' @keywords internal
#' @noRd
ask_yes_no <- function(question) {
  utils::menu(c("Yes", "No"), title = question) == 1
}

#' Open a file in Positron or RStudio if running in one, else R's editor
#'
#' @keywords internal
#' @noRd
open_file <- function(path) {
  if (requireNamespace("rstudioapi", quietly = TRUE) &&
    rstudioapi::isAvailable() &&
    rstudioapi::hasFun("navigateToFile")) {
    rstudioapi::navigateToFile(path)
  } else {
    utils::file.edit(path)
  }
  invisible(path)
}
