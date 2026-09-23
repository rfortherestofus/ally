# update_skill will not overwrite an edited skill unless forced

    Code
      update_skill("demo")
    Condition
      Error in `update_skill()`:
      ! Not overwriting "demo", which has local changes.
      x '<project>/.agents/skills/demo' has been edited since it was installed.
      i Copy anything you want to keep, then run again with `force = TRUE` to overwrite it.

