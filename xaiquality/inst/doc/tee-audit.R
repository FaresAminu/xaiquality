## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>",
                      eval = identical(Sys.getenv("R_XAIQUALITY_VIGNETTE"), "true"))
library(xaiquality)

## ----audit--------------------------------------------------------------------
#  fit <- lm(mpg ~ wt + hp, data = mtcars)
#  background <- mtcars[2:20, c("wt", "hp")]
#  case <- mtcars[1, c("wt", "hp")]
#  
#  audit <- xai_audit(
#    fit, data = background, newdata = case,
#    n_boot = 40, n_perturb = 60,
#    prediction_tolerance = 0.20,
#    min_kept = 5, seed = 123
#  )
#  print(audit)

## ----summary------------------------------------------------------------------
#  xai_summary(audit)

