\name{xai_summary}
\alias{xai_summary}
\title{Summarize explanation audits}
\description{Combines one or more xaiquality audit objects into a data frame containing estimates, intervals, decisions and quality diagnostics.}
\usage{xai_summary(x, ...)}
\arguments{
  \item{x}{An object of class \code{xaiquality_audit} or a list of such objects.}
  \item{...}{Unused.}
}
\value{A data frame with one row per audited feature and audit.}
\examples{\donttest{
fit <- lm(mpg ~ wt + hp, data = mtcars)
a <- xai_audit(fit, mtcars[2:20, c("wt", "hp")],
  mtcars[1, c("wt", "hp")], n_boot = 10, n_perturb = 20,
  min_kept = 1, prediction_tolerance = 0.2, seed = 1)
xai_summary(a)
}}
\keyword{models}
\keyword{utilities}
