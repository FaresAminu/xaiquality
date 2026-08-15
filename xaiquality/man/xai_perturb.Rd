\name{xai_perturb}
\alias{xai_perturb}
\title{Generate local perturbations}
\description{Generates local numeric and categorical perturbations around one observation using scales and empirical values from a background data set.}
\usage{xai_perturb(newdata, background, n = 200L, scale = 0.10)}
\arguments{
  \item{newdata}{A one-row data frame to perturb.}
  \item{background}{Reference data frame.}
  \item{n}{Number of perturbations.}
  \item{scale}{Numeric multiplier for numeric perturbations.}
}
\value{A data frame with \code{n} perturbed observations.}
\examples{\donttest{
xai_perturb(mtcars[1, c("wt", "hp")], mtcars[, c("wt", "hp")], n = 10)
}}
\keyword{models}
\keyword{utilities}
