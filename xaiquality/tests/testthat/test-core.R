test_that("xai_attribution returns one contribution per feature", {
  fit <- lm(mpg ~ wt + hp, data = mtcars)
  x <- mtcars[1:3, c("wt", "hp"), drop = FALSE]
  b <- mtcars[4:20, c("wt", "hp"), drop = FALSE]
  a <- xai_attribution(fit, x, b)
  expect_equal(dim(a), c(3, 2))
  expect_equal(colnames(a), c("wt", "hp"))
  expect_true(all(is.finite(a)))
})

test_that("numeric perturbations preserve columns and row count", {
  p <- xai_perturb(mtcars[1, c("wt", "hp"), drop = FALSE],
                   mtcars[, c("wt", "hp")], n = 20, scale = 0.05)
  expect_equal(nrow(p), 20)
  expect_equal(names(p), c("wt", "hp"))
})

test_that("audit is reproducible with a seed", {
  fit <- lm(mpg ~ wt + hp, data = mtcars)
  x <- mtcars[1, c("wt", "hp"), drop = FALSE]
  b <- mtcars[2:20, c("wt", "hp"), drop = FALSE]
  a1 <- xai_audit(fit, b, x, n_boot = 20, n_perturb = 40,
                  min_kept = 1, prediction_tolerance = 0.2, seed = 42)
  a2 <- xai_audit(fit, b, x, n_boot = 20, n_perturb = 40,
                  min_kept = 1, prediction_tolerance = 0.2, seed = 42)
  expect_equal(a1$point, a2$point)
  expect_equal(a1$decision, a2$decision)
})

test_that("audit rejects incompatible data", {
  fit <- lm(mpg ~ wt + hp, data = mtcars)
  expect_error(xai_attribution(fit, mtcars[1, "wt", drop = FALSE],
                               mtcars[2:5, c("wt", "hp"), drop = FALSE]),
               "identical column names")
})

test_that("summary and plotting methods are available", {
  fit <- lm(mpg ~ wt + hp, data = mtcars)
  x <- mtcars[1, c("wt", "hp"), drop = FALSE]
  b <- mtcars[2:20, c("wt", "hp"), drop = FALSE]
  a <- xai_audit(fit, b, x, n_boot = 10, n_perturb = 20,
                 min_kept = 1, prediction_tolerance = 0.2, seed = 1)
  expect_s3_class(a, "xaiquality_audit")
  expect_equal(nrow(xai_summary(a)), 2)
  expect_invisible(plot(a))
})
