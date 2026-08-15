# xaiquality

## Statistical quality audits for explainable artificial intelligence

`xaiquality` turns a local feature attribution into an auditable
statistical object. Instead of returning only a ranking, it reports
reference-contrast contributions, bootstrap uncertainty,
prediction-preserving stability, local fidelity and a transparent
reliability decision.

> An explanation is not certified merely because it is visually
> plausible: its uncertainty, robustness and fidelity must be reported
> together.

The package is **model-agnostic**. The default attribution works with
any model accepted by
[`stats::predict()`](https://rdrr.io/r/stats/predict.html), while
advanced users can provide `predict_fun` and `explain_fun` to audit
SHAP, LIME, permutation, gradient or domain-specific explanations.

## Installation

The development version can be installed from a local source tarball
after building it with `R CMD build`. The package is designed for CRAN:
it has no compiled code, no network access at runtime, no mandatory
tidyverse dependency and no external data download.

## Minimal example

``` r
library(xaiquality)

fit <- lm(mpg ~ wt + hp, data = mtcars)
background <- mtcars[2:20, c("wt", "hp")]
case <- mtcars[1, c("wt", "hp")]

audit <- xai_audit(
  fit, data = background, newdata = case,
  n_boot = 100, n_perturb = 150,
  prediction_tolerance = 0.20,
  min_kept = 10, seed = 123
)

print(audit)
xai_summary(audit)
plot(audit)
plot(audit, type = "stability")
```

## Decision states

The audit returns `reliable` only when the requested evidence thresholds
are met. Other states are scientifically meaningful: `uncertain`
indicates wide bootstrap intervals, `unstable` indicates that
prediction-preserving perturbations change the explanation, `unfaithful`
indicates poor local agreement with model behavior, and
`insufficient_evidence` indicates that too few prediction-preserving
perturbations were available.

These states are **operational diagnostics**, not causal claims or
clinical certifications. Bootstrap intervals are empirical uncertainty
summaries and their coverage depends on the data-generating process and
the chosen resampling scheme.

## Relation to existing tools

Packages such as DALEX provide a mature model-agnostic abstraction for
model exploration and explanation. `xaiquality` is intended as a
complementary statistical quality layer that can audit an explanation
produced elsewhere.

## Reproducibility and citation

The package stores the audit settings and session information in each
result object. Use `citation("xaiquality")` to obtain the citation
metadata once the package is released.

## Status

This is a research prototype. The code and method require further
benchmarking, independent review and a formal CRAN submission. No
package or article acceptance can be guaranteed in advance.
