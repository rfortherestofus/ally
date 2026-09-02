#' Create a relative symlink, falling back to copying on failure
#'
#' Links `link` to `target` with a relative path, so the link keeps working when the
#' project is moved, cloned or committed. If the link cannot be created (typically
#' Windows without developer mode), the folder is copied instead and a message says so.
#'
#' @param target Path of the folder the link should point to.
#' @param link   Path of the link to create.
#' @param force_copy If `TRUE`, skip the link attempt and copy directly.
#'
#' @return Invisibly, a list with `link`, `target` (the relative path used) and `mode`
#'   ("symlink" or "copy").
#' @keywords internal
#' @noRd
link_or_copy <- function(target, link, force_copy = FALSE) {
  fs::dir_create(fs::path_dir(link), recurse = TRUE)

  if (fs::link_exists(link)) {
    fs::link_delete(link)
  } else if (fs::dir_exists(link) || fs::file_exists(link)) {
    fs::dir_delete(link)
  }

  relative <- fs::path_rel(fs::path_abs(target), start = fs::path_abs(fs::path_dir(link)))

  if (!force_copy) {
    ok <- tryCatch(
      {
        fs::link_create(relative, link)
        TRUE
      },
      error = function(e) {
        cli::cli_alert_warning(
          "Could not create a link at {.path {link}}: {conditionMessage(e)}"
        )
        cli::cli_alert_info("Copying the skill folder instead.")
        FALSE
      }
    )
    if (ok) {
      return(invisible(list(link = link, target = relative, mode = "symlink")))
    }
  }

  fs::dir_copy(target, link, overwrite = TRUE)
  invisible(list(link = link, target = relative, mode = "copy"))
}
