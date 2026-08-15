\name{xai_audit}
\alias{xai_audit}
\title{Statistical quality audit of a local explanation}
\description{Computes a reference-based local explanation and audits it using bootstrap uncertainty, prediction-preserving stability, local fidelity, and a transparent decision rule.}
\usage{
xai_audit(model, data, newdata = data[1L, , drop = FALSE],
  predict_fun = NULL, explain_fun = NULL, n_boot = 200L,
  n_perturb = 200L, conf_level = 0.95,
  prediction_tolerance = 0.01, min_kept = 30L, seed = NULL,
  thresholds = list(max_relative_width = 1,
    min_stability = 0.75, min_fidelity = 0.75), ...)
}
\arguments{
  \item{model}{A fitted model.}
  \item{data}{Background/reference data frame.}
  \item{newdata}{One-row data frame to explain.}
  \item{predict_fun}{Optional prediction function with arguments \code{model} and \code{newdata}.}
  \item{explain_fun}{Optional attribution function.}
  \item{n_boot}{Number of bootstrap replications.}
  \item{n_perturb}{Number of local perturbation candidates.}
  \item{conf_level}{Confidence level for percentile intervals.}
  \item{prediction_tolerance}{Relative tolerance for prediction-preserving perturbations.}
  \item{min_kept}{Minimum number of retained perturbations.}
  \item{seed}{Optional random seed.}
  \item{thresholds}{Named decision thresholds.}
  \item{...}{Additional arguments passed to prediction or attribution functions.}
}
\value{An object of class \code{xaiquality_audit}.}
\seealso{\code{\link{xai_attribution}}, \code{\link{xai_perturb}}}
\examples{\donttest{
fit <- lm(mpg ~ wt + hp, data = mtcars)
a <- xai_audit(fit, mtcars[2:20, c("wt", "hp")],
  mtcars[1, c("wt", "hp")], n_boot = 20, n_perturb = 30,
  min_kept = 1, prediction_tolerance = 0.2, seed = 1)
print(a)
}}
\keyword{models}
\keyword{explain}
