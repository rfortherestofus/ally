#' Create a symlink, falling back to copying on failure
#'
#' Attempts to create a symlink from `link` to `target`. If symlink creation
#' fails (typically on Windows without developer mode), the directory is
#' copied instead and a message is shown.
#'
#' @param target Path the link should point to (absolute).
#' @param link   Path of the link to create.
#' @param force_copy If `TRUE`, skip the symlink attempt and copy directly.
#'
#' @return Invisibly, a list with `link`, `target`, and `mode` ("symlink"
#'   or "copy").
#' @keywords internal
#' @noRd
link_or_copy <- function(target, link, force_copy = FALSE) {
  fs::dir_create(fs::path_dir(link), recurse = TRUE)

  if (fs::link_exists(link)) {
    fs::link_delete(link)
  } else if (fs::dir_exists(link) || fs::file_exists(link)) {
    fs::dir_delete(link)
  }

  if (!force_copy) {
    ok <- tryCatch(
      {
        fs::link_create(fs::path_abs(target), link)
        TRUE
      },
      error = function(e) {
        cli::cli_alert_warning(
          "Could not create symlink at {.path {link}}: {conditionMessage(e)}"
        )
        cli::cli_alert_info("Falling back to copying the skill directory.")
        FALSE
      }
    )
    if (ok) {
      return(invisible(list(link = link, target = target, mode = "symlink")))
    }
  }

  fs::dir_copy(target, link, overwrite = TRUE)
  invisible(list(link = link, target = target, mode = "copy"))
}
