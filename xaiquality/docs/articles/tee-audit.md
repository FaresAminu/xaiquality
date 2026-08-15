# Auditing Local Explanations with the Trustworthy Explanation Envelope

## Motivation

A feature ranking is not sufficient evidence that a local explanation is
reliable. The `xaiquality` package reports a reference-contrast
explanation together with bootstrap uncertainty, prediction-preserving
stability, local fidelity and a transparent decision.

## Reproducible audit

The following code audits a linear model. The default `predict_fun` uses
[`stats::predict()`](https://rdrr.io/r/stats/predict.html), and the
background rows define the reference distribution.

``` r
fit <- lm(mpg ~ wt + hp, data = mtcars)
background <- mtcars[2:20, c("wt", "hp")]
case <- mtcars[1, c("wt", "hp")]

audit <- xai_audit(
  fit, data = background, newdata = case,
  n_boot = 40, n_perturb = 60,
  prediction_tolerance = 0.20,
  min_kept = 5, seed = 123
)
print(audit)
```

The decision is intentionally conservative. `reliable` means that the
empirical interval width, prediction-preserving stability and local
fidelity pass the selected operational thresholds. The alternative
states identify why an explanation should not be treated as strong
evidence.

``` r
xai_summary(audit)
```

## Interpretation and limitations

The bootstrap interval quantifies sensitivity to the reference sample;
it is not a universal finite-sample confidence guarantee.
Prediction-preserving perturbations are a practical local robustness
protocol, not a proof of invariance. The fidelity score detects
disagreement between the attribution and the model, but cannot establish
causality or fairness. Thresholds should therefore be selected
prospectively and reported in sensitivity analyses.
