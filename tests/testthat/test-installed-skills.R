write_skill <- function(dir, name, header = c("---", paste("name:", name), "description: Does a thing.", "---")) {
  skill <- fs::path(dir, name)
  fs::dir_create(skill)
  writeLines(c(header, "", "# Body"), fs::path(skill, "SKILL.md"))
  skill
}

# A fresh project and home folder, so the real ~/.claude/skills never leaks in.
local_skill_dirs <- function(env = parent.frame()) {
  home <- withr::local_tempdir(.local_envir = env)
  withr::local_envvar(HOME = home, USERPROFILE = home, .local_envir = env)
  proj <- withr::local_tempdir(.local_envir = env)
  withr::local_dir(proj, .local_envir = env)
  list(home = home, proj = proj)
}

test_that("installed_skills lists an ally skill once, with its description and source", {
  local_skill_dirs()
  src <- withr::local_tempdir()
  skill <- write_skill(src, "alpha")

  install_skill(skill)
  res <- installed_skills()

  expect_s3_class(res, "tbl_df")
  expect_named(res, c("name", "description", "source", "installed_by", "scope", "found_in", "path"))
  expect_equal(res$name, "alpha")
  expect_equal(res$description, "Does a thing.")
  expect_equal(res$source, as.character(skill))
  expect_equal(res$installed_by, "ally")
  expect_equal(res$scope, "project")
  expect_equal(res$found_in, ".agents, .claude")
  expect_match(res$path, ".agents/skills/alpha$")
})

test_that("installed_skills finds skills that only live in an agent's own folder", {
  dirs <- local_skill_dirs()
  write_skill(fs::path(dirs$home, ".claude/skills"), "hand-made")
  write_skill(fs::path(dirs$home, ".cursor/skills"), "cursor-only")

  res <- installed_skills(scope = "user")

  expect_equal(res$name, c("cursor-only", "hand-made"))
  expect_equal(res$found_in, c(".cursor", ".claude"))
  expect_equal(res$source, c(NA_character_, NA_character_))
  expect_equal(res$installed_by, c(NA_character_, NA_character_))
})

test_that("installed_skills lists both scopes by default and can pick one", {
  dirs <- local_skill_dirs()
  write_skill(fs::path(dirs$home, ".agents/skills"), "mine")
  write_skill(fs::path(dirs$proj, ".agents/skills"), "ours")

  expect_equal(installed_skills()$name, c("ours", "mine"))
  expect_equal(installed_skills()$scope, c("project", "user"))
  expect_equal(installed_skills(scope = "user")$name, "mine")
  expect_equal(installed_skills(scope = "project")$name, "ours")
})

test_that("installed_skills does not list skills twice when working in the home folder", {
  dirs <- local_skill_dirs()
  write_skill(fs::path(dirs$home, ".agents/skills"), "mine")
  withr::local_dir(dirs$home)

  res <- installed_skills()

  expect_equal(res$name, "mine")
  expect_equal(res$scope, "user")
})

test_that("installed_skills follows links, including a canonical skill that is a link", {
  dirs <- local_skill_dirs()
  elsewhere <- withr::local_tempdir()
  target <- write_skill(elsewhere, "linked")
  fs::dir_create(fs::path(dirs$proj, ".agents/skills"))
  fs::link_create(target, fs::path(dirs$proj, ".agents/skills/linked"))

  res <- installed_skills(scope = "project")

  expect_equal(res$name, "linked")
  expect_equal(res$source, pretty_path(fs::path_real(target)))
})

test_that("installed_skills ignores hidden folders and folders without a SKILL.md", {
  dirs <- local_skill_dirs()
  claude <- fs::path(dirs$proj, ".claude/skills")
  write_skill(claude, ".system")
  fs::dir_create(fs::path(claude, "not-a-skill"))
  write_skill(claude, "real")

  expect_equal(installed_skills(scope = "project")$name, "real")
})

test_that("installed_skills reads sources from the skills CLI lockfile", {
  dirs <- local_skill_dirs()
  write_skill(fs::path(dirs$home, ".agents/skills"), "find-skills")
  write_skill(fs::path(dirs$home, ".agents/skills"), "top-level")
  jsonlite::write_json(
    list(version = 3, skills = list(
      "find-skills" = list(
        source = "vercel-labs/skills",
        sourceType = "github",
        skillPath = "skills/find-skills/SKILL.md"
      ),
      "top-level" = list(source = "owner/top-level", sourceType = "github", skillPath = "SKILL.md")
    )),
    fs::path(dirs$home, ".agents/.skill-lock.json"),
    auto_unbox = TRUE
  )

  res <- installed_skills(scope = "user")

  expect_equal(res$source, c("vercel-labs/skills/skills/find-skills", "owner/top-level"))
  expect_equal(res$installed_by, c("skills CLI", "skills CLI"))
})

test_that("installed_skills returns an empty tibble when nothing is installed", {
  local_skill_dirs()

  res <- installed_skills()

  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 0)
  expect_named(res, c("name", "description", "source", "installed_by", "scope", "found_in", "path"))
})

test_that("skill_description handles block scalars, quotes, bad YAML and no header", {
  dir <- withr::local_tempdir()

  folded <- write_skill(dir, "folded", c("---", "description: >", "  Two lines", "  folded.", "---"))
  quoted <- write_skill(dir, "quoted", c("---", "description: \"Quoted: fine.\"", "---"))
  bad <- write_skill(dir, "bad", c("---", "description: Use when: YAML breaks", "tags: [unclosed", "---"))
  bare <- write_skill(dir, "bare", "# No header")
  missing <- write_skill(dir, "missing", c("---", "name: missing", "---"))

  expect_equal(skill_description(fs::path(folded, "SKILL.md")), "Two lines folded.")
  expect_equal(skill_description(fs::path(quoted, "SKILL.md")), "Quoted: fine.")
  expect_equal(skill_description(fs::path(bad, "SKILL.md")), "Use when: YAML breaks")
  expect_equal(skill_description(fs::path(bare, "SKILL.md")), NA_character_)
  expect_equal(skill_description(fs::path(missing, "SKILL.md")), NA_character_)
})
