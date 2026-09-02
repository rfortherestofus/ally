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
  expect_error(parse_source("owner//path"), "Invalid source")
  expect_error(parse_source("owner/repo/path@"), "Invalid source")
})

test_that("owner/repo shorthand is a top-level skill named after the repository", {
  parsed <- parse_source("statzhero/tidy-r-skill")
  expect_equal(parsed$path, "")
  expect_equal(parsed$skill_name, "tidy-r-skill")

  parsed_ref <- parse_source("statzhero/tidy-r-skill@v1")
  expect_equal(parsed_ref$ref, "v1")
  expect_equal(parsed_ref$skill_name, "tidy-r-skill")
})

test_that("GitHub shorthand strips a trailing /SKILL.md", {
  parsed <- parse_source("posit-dev/skills/posit-dev/critical-code-reviewer/SKILL.md")
  expect_equal(parsed$path, "posit-dev/critical-code-reviewer")
  expect_equal(parsed$skill_name, "critical-code-reviewer")
})

test_that("shorthand SKILL.md at the repository root is a top-level skill", {
  parsed <- parse_source("owner/repo/SKILL.md")
  expect_equal(parsed$path, "")
  expect_equal(parsed$skill_name, "repo")
})

test_that("full GitHub URLs are parsed (tree form)", {
  parsed <- parse_source(
    "https://github.com/posit-dev/skills/tree/main/posit-dev/critical-code-reviewer"
  )
  expect_equal(parsed$type, "github")
  expect_equal(parsed$owner, "posit-dev")
  expect_equal(parsed$repo, "skills")
  expect_equal(parsed$ref, "main")
  expect_equal(parsed$path, "posit-dev/critical-code-reviewer")
  expect_equal(parsed$skill_name, "critical-code-reviewer")
})

test_that("full GitHub URLs strip a trailing /SKILL.md (blob form)", {
  parsed <- parse_source(
    "https://github.com/posit-dev/skills/blob/main/posit-dev/critical-code-reviewer/SKILL.md"
  )
  expect_equal(parsed$path, "posit-dev/critical-code-reviewer")
  expect_equal(parsed$skill_name, "critical-code-reviewer")
  expect_equal(parsed$ref, "main")
})

test_that("GitHub URLs handle trailing slashes, query, fragment, .git", {
  parsed <- parse_source(
    "https://github.com/posit-dev/skills.git/tree/dev/posit-dev/foo/?plain=1#L1"
  )
  expect_equal(parsed$repo, "skills")
  expect_equal(parsed$ref, "dev")
  expect_equal(parsed$skill_name, "foo")
})

test_that("GitHub URLs to a repository root are top-level skills", {
  parsed <- parse_source("https://github.com/statzhero/tidy-r-skill")
  expect_equal(parsed$path, "")
  expect_true(is.na(parsed$ref))
  expect_equal(parsed$skill_name, "tidy-r-skill")

  parsed_ref <- parse_source("https://github.com/statzhero/tidy-r-skill/tree/main")
  expect_equal(parsed_ref$ref, "main")
  expect_equal(parsed_ref$skill_name, "tidy-r-skill")

  parsed_md <- parse_source("https://github.com/statzhero/tidy-r-skill/blob/main/SKILL.md")
  expect_equal(parsed_md$path, "")
  expect_equal(parsed_md$skill_name, "tidy-r-skill")
})

test_that("invalid GitHub URLs error informatively", {
  expect_error(
    parse_source("https://github.com/posit-dev"),
    "Invalid GitHub URL"
  )
  expect_error(
    parse_source("https://github.com/"),
    "Invalid GitHub URL"
  )
  expect_error(
    parse_source("https://github.com/owner/repo/issues/1"),
    "Invalid GitHub URL"
  )
})

test_that("http:// GitHub URLs are accepted", {
  parsed <- parse_source(
    "http://github.com/posit-dev/skills/tree/main/posit-dev/foo"
  )
  expect_equal(parsed$owner, "posit-dev")
  expect_equal(parsed$skill_name, "foo")
})

test_that("Github.com host is matched case-insensitively", {
  parsed <- parse_source(
    "https://GitHub.com/posit-dev/skills/tree/main/posit-dev/foo"
  )
  expect_equal(parsed$skill_name, "foo")
})

test_that("refs containing a slash are misparsed (documented limitation)", {
  parsed <- parse_source(
    "https://github.com/owner/repo/tree/release/v1/skills/my-skill"
  )
  expect_equal(parsed$ref, "release")
  expect_equal(parsed$path, "v1/skills/my-skill")
})
