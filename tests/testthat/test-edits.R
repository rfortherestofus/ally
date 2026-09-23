new_skill <- function(name = "demo", env = parent.frame()) {
  src <- withr::local_tempdir(.local_envir = env)
  skill <- fs::path(src, name)
  fs::dir_create(skill)
  writeLines(c("---", paste("name:", name), "description: A demo.", "---", "", "Original."), fs::path(skill, "SKILL.md"))
  skill
}

# A fresh project and home folder, with messages silenced.
local_project <- function(env = parent.frame()) {
  home <- withr::local_tempdir(.local_envir = env)
  withr::local_envvar(HOME = home, USERPROFILE = home, .local_envir = env)
  proj <- withr::local_tempdir(.local_envir = env)
  withr::local_dir(proj, .local_envir = env)
  withr::local_options(cli.default_handler = function(...) NULL, .local_envir = env)
  local_mocked_bindings(github_last_changed = function(...) no_time(), .env = env)
  proj
}

edit_file <- function(path) {
  cat("My own addition.\n", file = path, append = TRUE)
}

test_that("install_skill records a fingerprint of the skill's files", {
  local_project()
  install_skill(new_skill())

  metadata <- read_source_metadata(".agents/skills/demo")

  expect_equal(metadata$files_hash, skill_hash(".agents/skills/demo"))
  expect_equal(skill_hash(".claude/skills/demo"), metadata$files_hash)
})

test_that("skill_hash notices edits, new files and removed files, but not line endings", {
  dir <- new_skill()
  original <- skill_hash(dir)

  crlf <- gsub("\n", "\r\n", paste0(paste(readLines(fs::path(dir, "SKILL.md")), collapse = "\n"), "\n"))
  writeBin(charToRaw(crlf), fs::path(dir, "SKILL.md"))
  writeLines("junk", fs::path(dir, ".DS_Store"))
  expect_equal(skill_hash(dir), original)

  edit_file(fs::path(dir, "SKILL.md"))
  edited <- skill_hash(dir)
  expect_false(edited == original)

  writeLines("extra", fs::path(dir, "notes.md"))
  expect_false(skill_hash(dir) == edited)
  fs::file_delete(fs::path(dir, "notes.md"))
  expect_equal(skill_hash(dir), edited)
})

test_that("update_skill will not overwrite an edited skill unless forced", {
  local_project()
  install_skill(new_skill())
  edit_file(".agents/skills/demo/SKILL.md")

  expect_snapshot(update_skill("demo"), error = TRUE, transform = function(x) gsub("'[^']*/\\.agents", "'<project>/.agents", x))
  expect_match(readLines(".agents/skills/demo/SKILL.md"), "My own addition", all = FALSE)

  update_skill("demo", force = TRUE)
  expect_false(any(grepl("My own addition", readLines(".agents/skills/demo/SKILL.md"))))
})

test_that("install_skill will not overwrite an edited Claude Code copy", {
  local_project()
  skill <- new_skill()
  install_skill(skill)
  edit_file(".claude/skills/demo/SKILL.md")

  expect_error(install_skill(skill), "local changes")
  expect_error(install_skill(skill), ".claude/skills/demo")

  install_skill(skill, force = TRUE)
  expect_false(any(grepl("My own addition", readLines(".claude/skills/demo/SKILL.md"))))
})

test_that("install_skill will not overwrite a skill that ally did not install", {
  local_project()
  fs::dir_create(".agents/skills/demo")
  writeLines("Written by hand.", ".agents/skills/demo/SKILL.md")

  expect_error(install_skill(new_skill()), "not installed by ally")
  expect_equal(readLines(".agents/skills/demo/SKILL.md"), "Written by hand.")

  install_skill(new_skill(), force = TRUE)
  expect_match(readLines(".agents/skills/demo/SKILL.md"), "Original", all = FALSE)
})

test_that("skills installed before fingerprints were recorded can still be updated", {
  local_project()
  install_skill(new_skill())
  metadata <- read_source_metadata(".agents/skills/demo")
  metadata$files_hash <- NULL
  jsonlite::write_json(metadata, ".agents/skills/demo/.ally-source.json", auto_unbox = TRUE)
  edit_file(".agents/skills/demo/SKILL.md")

  expect_no_error(update_skill("demo"))
})

test_that("link_skills carries edits from .agents/skills to the Claude Code copy, every time", {
  local_project()
  install_skill(new_skill())
  edit_file(".agents/skills/demo/SKILL.md")

  expect_no_warning(link_skills())
  expect_match(readLines(".claude/skills/demo/SKILL.md"), "My own addition", all = FALSE)
  expect_no_warning(link_skills())
})

test_that("link_skills skips a skill whose Claude Code copy was edited, unless forced", {
  local_project()
  install_skill(new_skill("demo"))
  install_skill(new_skill("other"))
  edit_file(".claude/skills/demo/SKILL.md")

  expect_warning(res <- link_skills(), "Skipped")
  expect_named(res, "other")
  expect_match(readLines(".claude/skills/demo/SKILL.md"), "My own addition", all = FALSE)

  expect_no_warning(link_skills(force = TRUE))
  expect_false(any(grepl("My own addition", readLines(".claude/skills/demo/SKILL.md"))))
})

test_that("installed_skills flags edited skills", {
  local_project()
  install_skill(new_skill("clean"))
  install_skill(new_skill("changed"))
  install_skill(new_skill("claude-changed"))
  edit_file(".agents/skills/changed/SKILL.md")
  edit_file(".claude/skills/claude-changed/SKILL.md")
  fs::dir_create(".claude/skills/by-hand")
  writeLines("By hand.", ".claude/skills/by-hand/SKILL.md")

  res <- installed_skills(scope = "project")

  expect_equal(
    stats::setNames(res$edited, res$name),
    c("by-hand" = NA, changed = TRUE, "claude-changed" = TRUE, clean = FALSE)
  )
})
