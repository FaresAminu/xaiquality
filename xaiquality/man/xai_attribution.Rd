\name{xai_attribution}
\alias{xai_attribution}
\title{Reference-contrast feature attribution}
\description{Computes model-agnostic local feature contributions by replacing one feature at a time with values from a background data set.}
\usage{xai_attribution(model, newdata, background, predict_fun = NULL, ...)}
\arguments{
  \item{model}{A fitted model accepted by \code{predict_fun}.}
  \item{newdata}{Data frame containing observations to explain.}
  \item{background}{Reference data frame.}
  \item{predict_fun}{Optional function with arguments \code{model} and \code{newdata}.}
  \item{...}{Additional arguments passed to \code{predict_fun}.}
}
\value{A numeric matrix with one row per observation and one column per feature.}
\examples{\donttest{
fit <- lm(mpg ~ wt + hp, data = mtcars)
xai_attribution(fit, mtcars[1:2, c("wt", "hp")],
  mtcars[3:20, c("wt", "hp")])
}}
\keyword{models}
\keyword{explain}
