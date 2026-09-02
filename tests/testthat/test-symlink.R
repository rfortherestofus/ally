test_that("link_or_copy creates a symlink when possible", {
  tmp <- withr::local_tempdir()
  target <- fs::path(tmp, "target")
  fs::dir_create(target)
  writeLines("hi", fs::path(target, "x.md"))

  link <- fs::path(tmp, "link")
  res <- link_or_copy(target, link)

  expect_true(res$mode %in% c("symlink", "copy"))
  expect_true(fs::file_exists(fs::path(link, "x.md")))
})

test_that("links are relative, so a moved project keeps working", {
  tmp <- withr::local_tempdir()
  target <- fs::path(tmp, ".agents/skills/demo")
  fs::dir_create(target)
  writeLines("hi", fs::path(target, "SKILL.md"))

  link <- fs::path(tmp, ".claude/skills/demo")
  res <- link_or_copy(target, link)
  skip_if_not(res$mode == "symlink", "symlinks unavailable here")

  expect_equal(as.character(fs::link_path(link)), "../../.agents/skills/demo")

  moved <- fs::path(withr::local_tempdir(), "elsewhere")
  fs::dir_copy(tmp, moved)
  expect_true(fs::file_exists(fs::path(moved, ".claude/skills/demo/SKILL.md")))
})

test_that("link_or_copy with force_copy = TRUE always copies", {
  tmp <- withr::local_tempdir()
  target <- fs::path(tmp, "target")
  fs::dir_create(target)
  writeLines("hi", fs::path(target, "x.md"))

  link <- fs::path(tmp, "link")
  res <- link_or_copy(target, link, force_copy = TRUE)

  expect_equal(res$mode, "copy")
  expect_false(fs::link_exists(link))
  expect_true(fs::dir_exists(link))
})

test_that("link_or_copy replaces an existing link/dir", {
  tmp <- withr::local_tempdir()
  target <- fs::path(tmp, "target")
  fs::dir_create(target)
  writeLines("v2", fs::path(target, "x.md"))

  link <- fs::path(tmp, "link")
  fs::dir_create(link)
  writeLines("stale", fs::path(link, "x.md"))

  link_or_copy(target, link, force_copy = TRUE)
  expect_equal(readLines(fs::path(link, "x.md")), "v2")
})
