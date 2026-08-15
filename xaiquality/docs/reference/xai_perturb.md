# Generate local perturbations

Generates local numeric and categorical perturbations around one
observation using scales and empirical values from a background data
set.

## Usage

``` r
xai_perturb(newdata, background, n = 200L, scale = 0.10)
```

## Arguments

- newdata:

  A one-row data frame to perturb.

- background:

  Reference data frame.

- n:

  Number of perturbations.

- scale:

  Numeric multiplier for numeric perturbations.

## Value

A data frame with `n` perturbed observations.

## Examples

``` r
# \donttest{
xai_perturb(mtcars[1, c("wt", "hp")], mtcars[, c("wt", "hp")], n = 10)
#>                   wt        hp
#> Mazda RX4   2.509121 128.24846
#> Mazda RX4.1 2.534927 108.76411
#> Mazda RX4.2 2.546129 114.69666
#> Mazda RX4.3 2.607316 132.39547
#> Mazda RX4.4 2.521978 113.84364
#> Mazda RX4.5 2.539779 109.52680
#> Mazda RX4.6 2.524644 103.33265
#> Mazda RX4.7 2.679129 106.25245
#> Mazda RX4.8 2.673697  98.42184
#> Mazda RX4.9 2.709669  99.21936
# }
```
