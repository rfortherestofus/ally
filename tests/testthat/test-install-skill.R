make_local_skill <- function(name = "demo-skill") {
  src <- withr::local_tempdir(.local_envir = parent.frame())
  skill <- fs::path(src, name)
  fs::dir_create(skill)
  writeLines("# Demo skill", fs::path(skill, "SKILL.md"))
  fs::dir_create(fs::path(skill, "examples"))
  writeLines("example", fs::path(skill, "examples/one.md"))
  skill
}

test_that("install_skill creates canonical copy and Claude symlink", {
  proj <- withr::local_tempdir()
  withr::local_dir(proj)

  res <- install_skill(make_local_skill("demo-skill"))

  expect_true(fs::dir_exists(".agents/skills/demo-skill"))
  expect_true(fs::file_exists(".agents/skills/demo-skill/SKILL.md"))
  expect_true(fs::file_exists(".agents/skills/demo-skill/examples/one.md"))
  expect_true(fs::file_exists(".agents/skills/demo-skill/.ally-source.json"))

  expect_true(fs::link_exists(".claude/skills/demo-skill") ||
                fs::dir_exists(".claude/skills/demo-skill"))

  expect_equal(res$skill, "demo-skill")
  expect_equal(names(res$links), "claude")
})

test_that(".agents/skills itself is a real directory, not a symlink", {
  # Codex won't load skills if .agents/skills is itself a symlink (openai/codex#11314)
  proj <- withr::local_tempdir()
  withr::local_dir(proj)

  install_skill(make_local_skill("native"))

  expect_false(fs::link_exists(".agents/skills"))
  expect_true(fs::dir_exists(".agents/skills"))
})

test_that("install_skill works in a bare directory (creates folders)", {
  proj <- withr::local_tempdir()
  withr::local_dir(proj)

  install_skill(make_local_skill("solo-skill"))

  expect_true(fs::dir_exists(".agents/skills"))
  expect_true(fs::dir_exists(".claude/skills"))
})

test_that("installed_skills lists skills under .agents/skills/", {
  proj <- withr::local_tempdir()
  withr::local_dir(proj)

  install_skill(make_local_skill("alpha"))
  install_skill(make_local_skill("beta"))

  expect_setequal(installed_skills(), c("alpha", "beta"))
})

test_that("link_skills re-links every installed skill for Claude", {
  proj <- withr::local_tempdir()
  withr::local_dir(proj)

  install_skill(make_local_skill("synced"))
  fs::link_delete(".claude/skills/synced")

  link_skills()

  expect_true(fs::link_exists(".claude/skills/synced") ||
                fs::dir_exists(".claude/skills/synced"))
})

test_that("remove_skill cleans up canonical copy and Claude symlink", {
  proj <- withr::local_tempdir()
  withr::local_dir(proj)

  install_skill(make_local_skill("gone"))
  expect_true(fs::dir_exists(".agents/skills/gone"))

  remove_skill("gone")
  expect_false(fs::dir_exists(".agents/skills/gone"))
  expect_false(fs::link_exists(".claude/skills/gone"))
})

test_that("update_skill re-runs install from recorded source", {
  proj <- withr::local_tempdir()
  withr::local_dir(proj)

  src <- make_local_skill("updater")
  install_skill(src)

  writeLines("# Demo skill v2", fs::path(src, "SKILL.md"))
  update_skill("updater")

  expect_equal(
    readLines(".agents/skills/updater/SKILL.md"),
    "# Demo skill v2"
  )
})

test_that("install_skill with copy = TRUE copies the Claude folder", {
  proj <- withr::local_tempdir()
  withr::local_dir(proj)

  install_skill(make_local_skill("copy-me"), copy = TRUE)

  expect_false(fs::link_exists(".claude/skills/copy-me"))
  expect_true(fs::dir_exists(".claude/skills/copy-me"))
  expect_true(fs::file_exists(".claude/skills/copy-me/SKILL.md"))
})

test_that("install_skill refuses a folder without a SKILL.md", {
  proj <- withr::local_tempdir()
  withr::local_dir(proj)
  src <- withr::local_tempdir()
  writeLines("not a skill", fs::path(src, "README.md"))

  expect_error(install_skill(src), "SKILL.md")
  expect_false(fs::dir_exists(".agents/skills"))
})

test_that("scope = 'user' installs under the home folder, not the project", {
  home <- withr::local_tempdir()
  withr::local_envvar(HOME = home, USERPROFILE = home)
  proj <- withr::local_tempdir()
  withr::local_dir(proj)

  res <- install_skill(make_local_skill("everywhere"), scope = "user")

  expect_equal(res$scope, "user")
  expect_true(fs::file_exists(fs::path(home, ".agents/skills/everywhere/SKILL.md")))
  expect_true(fs::file_exists(fs::path(home, ".claude/skills/everywhere/SKILL.md")))
  expect_false(fs::dir_exists(".agents"))

  expect_equal(installed_skills(scope = "user"), "everywhere")
  expect_equal(installed_skills(), character())

  remove_skill("everywhere", scope = "user")
  expect_false(fs::dir_exists(fs::path(home, ".agents/skills/everywhere")))
  expect_false(fs::link_exists(fs::path(home, ".claude/skills/everywhere")))
})

test_that("supported_agents lists Claude Code only (Codex is native)", {
  expect_equal(names(supported_agents()), "claude")
})
