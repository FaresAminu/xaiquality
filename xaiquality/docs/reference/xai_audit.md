# Statistical quality audit of a local explanation

Computes a reference-based local explanation and audits it using
bootstrap uncertainty, prediction-preserving stability, local fidelity,
and a transparent decision rule.

## Usage

``` r
xai_audit(model, data, newdata = data[1L, , drop = FALSE],
  predict_fun = NULL, explain_fun = NULL, n_boot = 200L,
  n_perturb = 200L, conf_level = 0.95,
  prediction_tolerance = 0.01, min_kept = 30L, seed = NULL,
  thresholds = list(max_relative_width = 1,
    min_stability = 0.75, min_fidelity = 0.75), ...)
```

## Arguments

- model:

  A fitted model.

- data:

  Background/reference data frame.

- newdata:

  One-row data frame to explain.

- predict_fun:

  Optional prediction function with arguments `model` and `newdata`.

- explain_fun:

  Optional attribution function.

- n_boot:

  Number of bootstrap replications.

- n_perturb:

  Number of local perturbation candidates.

- conf_level:

  Confidence level for percentile intervals.

- prediction_tolerance:

  Relative tolerance for prediction-preserving perturbations.

- min_kept:

  Minimum number of retained perturbations.

- seed:

  Optional random seed.

- thresholds:

  Named decision thresholds.

- ...:

  Additional arguments passed to prediction or attribution functions.

## Value

An object of class `xaiquality_audit`.

## See also

[`xai_attribution`](https://faresaminu.github.io/xaiquality/reference/xai_attribution.md),
[`xai_perturb`](https://faresaminu.github.io/xaiquality/reference/xai_perturb.md)

## Examples

``` r
# \donttest{
fit <- lm(mpg ~ wt + hp, data = mtcars)
a <- xai_audit(fit, mtcars[2:20, c("wt", "hp")],
  mtcars[1, c("wt", "hp")], n_boot = 20, n_perturb = 30,
  min_kept = 1, prediction_tolerance = 0.2, seed = 1)
print(a)
#> xaiquality explanation audit
#> Decision: uncertain 
#> Prediction-preserving perturbations: 30 / 30 
#> Fidelity score: 0.919 
#> 
#>  feature  estimate     lower    upper    width relative_width
#>       wt 0.8762644 0.2093252 1.423010 1.213685      1.3850668
#>       hp 3.1775761 2.0102266 4.381464 2.371237      0.7462409
# }
```
