test_that("GitHub shorthand parses owner/repo/path", {
  parsed <- parse_source("ab604/claude-code-r-skills/r-style-guide")
  expect_equal(parsed$type, "github")
  expect_equal(parsed$owner, "ab604")
  expect_equal(parsed$repo, "claude-code-r-skills")
  expect_equal(parsed$path, "r-style-guide")
  expect_equal(parsed$skill_name, "r-style-guide")
  expect_true(is.na(parsed$ref))
})

test_that("GitHub shorthand supports nested paths and refs", {
  parsed <- parse_source("owner/repo/skills/foo/bar@dev")
  expect_equal(parsed$type, "github")
  expect_equal(parsed$path, "skills/foo/bar")
  expect_equal(parsed$skill_name, "bar")
  expect_equal(parsed$ref, "dev")
})

test_that("local paths are detected", {
  parsed <- parse_source("~/my-skills/r-style-guide")
  expect_equal(parsed$type, "local")
  expect_equal(parsed$skill_name, "r-style-guide")

  parsed2 <- parse_source("./local/thing")
  expect_equal(parsed2$type, "local")
  expect_equal(parsed2$skill_name, "thing")
})

test_that("invalid GitHub shorthand errors", {
  expect_error(parse_source("just-a-name"), "Invalid source")
  expect_error(parse_source("owner/repo"), "Invalid source")
  expect_error(parse_source("owner/repo/path@"), "Invalid source")
})
