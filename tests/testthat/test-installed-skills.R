write_skill <- function(dir, name, header = c("---", paste("name:", name), "description: Does a thing.", "---")) {
  skill <- fs::path(dir, name)
  fs::dir_create(skill)
  writeLines(c(header, "", "# Body"), fs::path(skill, "SKILL.md"))
  skill
}

skill_columns <- c(
  "name", "description", "installed_by", "installed_from", "installed",
  "updated_on_github", "scope", "found_in", "path"
)

# A fresh project and home folder, so the real ~/.claude/skills never leaks in.
local_skill_dirs <- function(env = parent.frame()) {
  home <- withr::local_tempdir(.local_envir = env)
  withr::local_envvar(HOME = home, USERPROFILE = home, .local_envir = env)
  proj <- withr::local_tempdir(.local_envir = env)
  withr::local_dir(proj, .local_envir = env)
  local_mocked_bindings(github_last_changed = function(...) as.Date(NA), .env = env)
  list(home = home, proj = proj)
}

test_that("installed_skills lists an ally skill once, with its description and source", {
  local_skill_dirs()
  src <- withr::local_tempdir()
  skill <- write_skill(src, "alpha")

  install_skill(skill)
  res <- installed_skills()

  expect_s3_class(res, "tbl_df")
  expect_named(res, skill_columns)
  expect_equal(res$name, "alpha")
  expect_equal(res$description, "Does a thing.")
  expect_equal(res$installed_from, as.character(skill))
  expect_equal(res$installed_by, "ally")
  expect_equal(res$installed, Sys.Date())
  expect_equal(res$updated_on_github, as.Date(NA))
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
  expect_equal(res$installed_from, c(NA_character_, NA_character_))
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
  expect_equal(res$installed_from, pretty_path(fs::path_real(target)))
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
        skillPath = "skills/find-skills/SKILL.md",
        installedAt = "2026-03-30T20:18:42.463Z",
        updatedAt = "2026-04-02T09:00:00.000Z"
      ),
      "top-level" = list(source = "owner/top-level", sourceType = "github", skillPath = "SKILL.md")
    )),
    fs::path(dirs$home, ".agents/.skill-lock.json"),
    auto_unbox = TRUE
  )

  res <- installed_skills(scope = "user")

  expect_equal(res$installed_from, c("vercel-labs/skills/skills/find-skills", "owner/top-level"))
  expect_equal(res$installed_by, c("skills CLI", "skills CLI"))
  expect_equal(res$installed[1], as.Date("2026-04-02"))
})

test_that("installed_skills returns an empty tibble when nothing is installed", {
  local_skill_dirs()

  res <- installed_skills()

  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 0)
  expect_named(res, skill_columns)
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

test_that("installed_skills shortens long descriptions", {
  dirs <- local_skill_dirs()
  long <- paste(rep("word", 30), collapse = " ")
  write_skill(fs::path(dirs$proj, ".claude/skills"), "wordy", c("---", paste("description:", long), "---"))

  description <- installed_skills(scope = "project")$description

  expect_equal(nchar(description), 50)
  expect_true(endsWith(description, "\u2026"))
  expect_equal(shorten(c("short", NA)), c("short", NA))
})

test_that("installed_skills looks up GitHub dates for skills from GitHub", {
  dirs <- local_skill_dirs()
  calls <- list()
  local_mocked_bindings(github_last_changed = function(owner, repo, path, ref) {
    calls[[length(calls) + 1]] <<- list(owner = owner, repo = repo, path = path, ref = ref)
    as.Date("2026-07-10")
  })
  skill <- write_skill(fs::path(dirs$proj, ".agents/skills"), "from-github")
  write_source_metadata(skill, parse_source("owner/repo/skills/from-github@dev"))
  write_skill(fs::path(dirs$proj, ".agents/skills"), "local")

  res <- installed_skills(scope = "project")

  expect_equal(res$updated_on_github, as.Date(c("2026-07-10", NA)))
  expect_equal(calls, list(list(owner = "owner", repo = "repo", path = "skills/from-github", ref = "dev")))

  calls <- list()
  res <- installed_skills(scope = "project", check_github = FALSE)
  expect_equal(res$updated_on_github, as.Date(c(NA, NA)))
  expect_length(calls, 0)
})

test_that("atom_last_updated reads the newest entry, not the feed header", {
  feed <- c(
    "<feed>",
    "<updated>2026-09-01T00:00:00Z</updated>",
    "<entry><updated>2026-07-10T20:54:38Z</updated></entry>",
    "<entry><updated>2026-06-23T20:35:09Z</updated></entry>",
    "</feed>"
  )

  expect_equal(atom_last_updated(feed), as.Date("2026-07-10"))
  expect_equal(atom_last_updated(c("<feed>", "<updated>2026-09-01T00:00:00Z</updated>", "</feed>")), as.Date(NA))
})

test_that("timestamp_date reads ally and skills CLI timestamps", {
  expect_equal(timestamp_date("2026-05-14T11:22:37-0700"), as.Date("2026-05-14"))
  expect_equal(timestamp_date("2026-03-30T20:18:42.463Z"), as.Date("2026-03-30"))
  expect_equal(timestamp_date(NA_character_), as.Date(NA))
  expect_equal(timestamp_date("soon"), as.Date(NA))
})
