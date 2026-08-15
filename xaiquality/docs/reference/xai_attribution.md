# Reference-contrast feature attribution

Computes model-agnostic local feature contributions by replacing one
feature at a time with values from a background data set.

## Usage

``` r
xai_attribution(model, newdata, background, predict_fun = NULL, ...)
```

## Arguments

- model:

  A fitted model accepted by `predict_fun`.

- newdata:

  Data frame containing observations to explain.

- background:

  Reference data frame.

- predict_fun:

  Optional function with arguments `model` and `newdata`.

- ...:

  Additional arguments passed to `predict_fun`.

## Value

A numeric matrix with one row per observation and one column per
feature.

## Examples

``` r
# \donttest{
fit <- lm(mpg ~ wt + hp, data = mtcars)
xai_attribution(fit, mtcars[1:2, c("wt", "hp")],
  mtcars[3:20, c("wt", "hp")])
#>             wt       hp
#> [1,] 0.9249458 3.299172
#> [2,] 0.9249458 2.310325
# }
```
