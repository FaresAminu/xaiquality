# Summarize explanation audits

Combines one or more xaiquality audit objects into a data frame
containing estimates, intervals, decisions and quality diagnostics.

## Usage

``` r
xai_summary(x, ...)
```

## Arguments

- x:

  An object of class `xaiquality_audit` or a list of such objects.

- ...:

  Unused.

## Value

A data frame with one row per audited feature and audit.

## Examples

``` r
# \donttest{
fit <- lm(mpg ~ wt + hp, data = mtcars)
a <- xai_audit(fit, mtcars[2:20, c("wt", "hp")],
  mtcars[1, c("wt", "hp")], n_boot = 10, n_perturb = 20,
  min_kept = 1, prediction_tolerance = 0.2, seed = 1)
xai_summary(a)
#>    feature  estimate     lower    upper    width relative_width  decision
#> wt      wt 0.8762644 0.2982476 1.412182 1.113934      1.2712309 uncertain
#> hp      hp 3.1775761 2.2761591 4.398629 2.122469      0.6679523 uncertain
#>     fidelity kept_perturbations audit_id
#> wt 0.9189836                 20        1
#> hp 0.9189836                 20        1
# }
```
