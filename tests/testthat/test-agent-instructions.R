# A fresh project and home folder, so the real ~/.claude/CLAUDE.md never leaks in.
local_instruction_dirs <- function(env = parent.frame()) {
  # Real paths, since getwd() resolves macOS's /var -> /private/var link.
  home <- fs::path_real(withr::local_tempdir(.local_envir = env))
  withr::local_envvar(HOME = home, USERPROFILE = home, .local_envir = env)
  proj <- fs::path_real(withr::local_tempdir(.local_envir = env))
  withr::local_dir(proj, .local_envir = env)
  list(home = home, proj = proj)
}

write_lines_to <- function(path, lines) {
  fs::dir_create(fs::path_dir(path))
  writeLines(lines, path)
  path
}

test_that("list_agent_instructions lists main files, only for installed agents", {
  dirs <- local_instruction_dirs()
  fs::dir_create(fs::path(dirs$home, c(".claude", ".posit")))
  write_lines_to(fs::path(dirs$home, ".claude/CLAUDE.md"), c("# Me", "Be brief."))

  res <- list_agent_instructions()

  expect_s3_class(res, "tbl_df")
  expect_named(res, c("scope", "agent", "read_by", "path", "exists", "lines"))
  expect_equal(res$scope, c("user", "user", "project", "project"))
  expect_equal(res$agent, c("claude", "posit", "agents", "claude"))
  expect_equal(res$exists, c(TRUE, FALSE, FALSE, FALSE))
  expect_equal(res$lines, c(2L, NA, NA, NA))
  expect_match(res$path[2], ".posit/assistant/AGENTS.md$")
})

test_that("list_agent_instructions shows less common files only when they exist", {
  dirs <- local_instruction_dirs()
  fs::dir_create(fs::path(dirs$home, ".codex"))

  res <- list_agent_instructions()
  expect_false(any(grepl("AGENTS.override.md|CLAUDE.local.md|\\.claude/CLAUDE.md", res$path)))

  write_lines_to(fs::path(dirs$home, ".codex/AGENTS.override.md"), "x")
  write_lines_to(fs::path(dirs$proj, "CLAUDE.local.md"), "x")
  write_lines_to(fs::path(dirs$proj, ".claude/CLAUDE.md"), "x")

  res <- list_agent_instructions()
  expect_true(all(c(
    fs::path(dirs$home, ".codex/AGENTS.override.md"),
    fs::path(dirs$proj, "CLAUDE.local.md"),
    fs::path(dirs$proj, ".claude/CLAUDE.md")
  ) %in% res$path))
})

test_that("list_agent_instructions can look at one scope", {
  local_instruction_dirs()
  expect_equal(unique(list_agent_instructions(scope = "project")$scope), "project")
  expect_equal(nrow(list_agent_instructions(scope = "user")), 0)
})

test_that("Claude Code reads the project AGENTS.md only without a CLAUDE.md", {
  dirs <- local_instruction_dirs()
  write_lines_to(fs::path(dirs$proj, "AGENTS.md"), "Use the native pipe.")

  res <- list_agent_instructions(scope = "project")
  expect_equal(res$read_by[res$agent == "agents"], "Codex, Posit Assistant, Claude Code")

  write_lines_to(fs::path(dirs$proj, "CLAUDE.md"), "Be brief.")
  expect_message(
    res <- list_agent_instructions(scope = "project"),
    "Claude Code reads .*CLAUDE.md.* in this project"
  )
  expect_equal(res$read_by[res$agent == "agents"], "Codex, Posit Assistant")
})

test_that("a CLAUDE.md that imports AGENTS.md gets no note", {
  dirs <- local_instruction_dirs()
  write_lines_to(fs::path(dirs$proj, "AGENTS.md"), "Use the native pipe.")
  write_lines_to(fs::path(dirs$proj, "CLAUDE.md"), c("# Claude", "@AGENTS.md"))

  messages <- character()
  withCallingHandlers(
    list_agent_instructions(scope = "project"),
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_false(any(grepl("Claude Code reads", messages)))
})

test_that("list_agent_instructions never creates or changes files", {
  dirs <- local_instruction_dirs()
  fs::dir_create(fs::path(dirs$home, c(".claude", ".codex", ".posit")))
  before <- fs::dir_ls(c(dirs$home, dirs$proj), recurse = TRUE, all = TRUE)

  list_agent_instructions()

  expect_equal(fs::dir_ls(c(dirs$home, dirs$proj), recurse = TRUE, all = TRUE), before)
})

test_that("edit_agent_instructions opens the one file an agent has", {
  dirs <- local_instruction_dirs()
  claude_md <- write_lines_to(fs::path(dirs$home, ".claude/CLAUDE.md"), "Be brief.")
  opened <- NULL
  local_mocked_bindings(open_file = function(path) opened <<- path)

  res <- edit_agent_instructions("claude")

  expect_equal(opened, as.character(claude_md))
  expect_equal(res, as.character(claude_md))
  expect_equal(readLines(claude_md), "Be brief.")
})

test_that("edit_agent_instructions asks which file when an agent has several", {
  dirs <- local_instruction_dirs()
  write_lines_to(fs::path(dirs$home, ".claude/CLAUDE.md"), "Mine.")
  project_md <- write_lines_to(fs::path(dirs$proj, "CLAUDE.md"), "Project.")
  opened <- NULL
  local_mocked_bindings(
    open_file = function(path) opened <<- path,
    is_interactive = function() TRUE,
    ask_number = function(n) 2L
  )

  edit_agent_instructions("claude")
  expect_equal(opened, as.character(project_md))
})

test_that("edit_agent_instructions with no agent picks from every file", {
  dirs <- local_instruction_dirs()
  fs::dir_create(fs::path(dirs$home, ".codex"))
  opened <- NULL
  local_mocked_bindings(
    open_file = function(path) opened <<- path,
    is_interactive = function() TRUE,
    ask_number = function(n) 1L,
    ask_yes_no = function(question) TRUE
  )

  edit_agent_instructions()
  expect_equal(opened, as.character(fs::path(dirs$home, ".codex/AGENTS.md")))
})

test_that("a blank answer opens nothing", {
  local_instruction_dirs()
  local_mocked_bindings(
    open_file = function(path) stop("should not open"),
    is_interactive = function() TRUE,
    ask_number = function(n) NA_integer_
  )

  expect_null(edit_agent_instructions())
})

test_that("edit_agent_instructions creates a missing file, with its folder, only on yes", {
  dirs <- local_instruction_dirs()
  posit_md <- fs::path(dirs$home, ".posit/assistant/AGENTS.md")
  local_mocked_bindings(
    open_file = function(path) invisible(path),
    is_interactive = function() TRUE,
    ask_yes_no = function(question) FALSE
  )

  expect_null(edit_agent_instructions("posit"))
  expect_false(fs::file_exists(posit_md))

  local_mocked_bindings(ask_yes_no = function(question) TRUE)
  expect_equal(edit_agent_instructions("posit"), as.character(posit_md))
  expect_true(fs::file_exists(posit_md))
  expect_equal(length(readLines(posit_md)), 0)
})

test_that("edit_agent_instructions won't ask outside an interactive session", {
  dirs <- local_instruction_dirs()
  write_lines_to(fs::path(dirs$home, ".claude/CLAUDE.md"), "Mine.")
  write_lines_to(fs::path(dirs$proj, "CLAUDE.md"), "Project.")
  local_mocked_bindings(is_interactive = function() FALSE)

  expect_error(edit_agent_instructions(), "interactive")
  expect_error(edit_agent_instructions("claude"), "scope")
  expect_error(edit_agent_instructions("agents"), "does not exist")
})

test_that("edit_agent_instructions explains agents with no file in a scope", {
  local_instruction_dirs()
  expect_error(edit_agent_instructions("codex", scope = "project"), "agents")
  expect_error(edit_agent_instructions("nope"))
})
