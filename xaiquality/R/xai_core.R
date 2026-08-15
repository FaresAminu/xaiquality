`%||%` <- function(x, y) if (is.null(x)) y else x

.validate_frame <- function(x, name) {
  if (is.null(x)) stop(name, " must not be NULL.", call. = FALSE)
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  if (nrow(x) < 1L || ncol(x) < 1L) {
    stop(name, " must contain at least one row and one column.", call. = FALSE)
  }
  if (is.null(names(x)) || any(!nzchar(names(x)))) {
    stop(name, " must have non-empty column names.", call. = FALSE)
  }
  x
}

.validate_compatible <- function(newdata, background) {
  if (!identical(names(newdata), names(background))) {
    stop("newdata and background must have identical column names.", call. = FALSE)
  }
  for (j in seq_along(newdata)) {
    if (is.factor(newdata[[j]]) != is.factor(background[[j]])) {
      stop("Column '", names(newdata)[j], "' has incompatible factor classes.",
           call. = FALSE)
    }
  }
  invisible(TRUE)
}

.default_predict <- function(model, newdata) {
  out <- stats::predict(model, newdata = newdata)
  if (is.matrix(out) || is.data.frame(out)) {
    if (ncol(out) != 1L) {
      stop("predict_fun must return one numeric prediction per row.", call. = FALSE)
    }
    out <- out[, 1L]
  }
  if (is.factor(out) || is.character(out) || !is.numeric(out)) {
    stop("predict_fun must return a numeric vector; supply a custom predict_fun for classification.",
         call. = FALSE)
  }
  as.numeric(out)
}

.validate_predict <- function(pred, n, label = "predict_fun") {
  if (length(pred) != n || any(!is.finite(pred))) {
    stop(label, " must return a finite numeric vector of length nrow(newdata).",
         call. = FALSE)
  }
  as.numeric(pred)
}

.check_columns <- function(newdata, background) {
  .validate_compatible(newdata, background)
  invisible(TRUE)
}

.reference_row <- function(background) {
  out <- background[1L, , drop = FALSE]
  for (j in seq_along(background)) {
    z <- background[[j]]
    if (is.numeric(z) || is.integer(z)) {
      out[[j]] <- stats::median(z, na.rm = TRUE)
    } else if (is.factor(z)) {
      tab <- table(z)
      lev <- names(tab)[which.max(tab)]
      out[[j]] <- factor(lev, levels = levels(z))
    } else {
      tab <- table(z)
      out[[j]] <- names(tab)[which.max(tab)]
    }
  }
  out
}

.prediction_scale <- function(pred) max(abs(pred), 1e-8)

#' Reference-contrast feature attribution
#'
#' Computes model-agnostic local feature contributions by replacing one
#' feature at a time with values observed in a background data set.
#'
#' @param model A fitted model accepted by `predict_fun`.
#' @param newdata Data frame containing observations to explain.
#' @param background Data frame defining the reference distribution.
#' @param predict_fun Function with arguments `model` and `newdata` returning
#'   one numeric prediction per row. Defaults to `stats::predict`.
#' @param ... Additional arguments passed to `predict_fun`.
#' @return A numeric matrix with one row per observation and one column per
#'   feature.
#' @export
xai_attribution <- function(model, newdata, background, predict_fun = NULL, ...) {
  newdata <- .validate_frame(newdata, "newdata")
  background <- .validate_frame(background, "background")
  .check_columns(newdata, background)
  predict_fun <- predict_fun %||% .default_predict
  if (!is.function(predict_fun)) stop("predict_fun must be a function.", call. = FALSE)
  p_x <- .validate_predict(do.call(predict_fun, c(list(model = model, newdata = newdata), list(...))),
                           nrow(newdata))
  out <- matrix(0, nrow = nrow(newdata), ncol = ncol(newdata),
                dimnames = list(NULL, names(newdata)))
  for (j in seq_along(newdata)) {
    mixed <- background[rep(seq_len(nrow(background)), each = nrow(newdata)), , drop = FALSE]
    x_rep <- newdata[rep(seq_len(nrow(newdata)), times = nrow(background)), , drop = FALSE]
    mixed[[j]] <- x_rep[[j]]
    p_mixed <- do.call(predict_fun, c(list(model = model, newdata = mixed), list(...)))
    p_mixed <- .validate_predict(p_mixed, nrow(mixed))
    by_obs <- matrix(p_mixed, nrow = nrow(newdata), ncol = nrow(background), byrow = FALSE)
    out[, j] <- p_x - rowMeans(by_obs)
  }
  out
}

#' Generate local perturbations for explanation stability
#'
#' @param newdata A one-row data frame to perturb.
#' @param background Reference data frame used for empirical categorical draws
#'   and scale estimates.
#' @param n Number of perturbations.
#' @param scale Numeric multiplier for numeric perturbations.
#' @return A data frame of perturbed observations.
#' @export
xai_perturb <- function(newdata, background, n = 200L, scale = 0.10) {
  newdata <- .validate_frame(newdata, "newdata")
  background <- .validate_frame(background, "background")
  .check_columns(newdata, background)
  if (nrow(newdata) != 1L) stop("newdata must contain exactly one row.", call. = FALSE)
  if (length(n) != 1L || !is.finite(n) || n < 1 || n != as.integer(n)) {
    stop("n must be one positive integer.", call. = FALSE)
  }
  if (length(scale) != 1L || !is.finite(scale) || scale < 0) {
    stop("scale must be one non-negative number.", call. = FALSE)
  }
  out <- newdata[rep(1L, n), , drop = FALSE]
  for (j in seq_along(out)) {
    z <- background[[j]]
    if (is.numeric(z) || is.integer(z)) {
      s <- stats::sd(z, na.rm = TRUE)
      if (!is.finite(s) || s == 0) s <- 1
      vals <- as.numeric(newdata[[j]]) + stats::rnorm(n, sd = scale * s)
      if (is.integer(z)) vals <- as.integer(round(vals))
      out[[j]] <- vals
    } else {
      out[[j]] <- sample(z, size = n, replace = TRUE)
      if (is.factor(z)) out[[j]] <- factor(out[[j]], levels = levels(z))
    }
  }
  out
}

.clamp01 <- function(x) max(0, min(1, as.numeric(x)))

.safe_spearman <- function(x, y) {
  if (length(x) < 2L || stats::sd(x) == 0 || stats::sd(y) == 0) return(1)
  z <- suppressWarnings(stats::cor(x, y, method = "spearman"))
  if (!is.finite(z)) 0 else (z + 1) / 2
}

.sign_agreement <- function(x, y) {
  mean(sign(x) == sign(y))
}

.deletion_fidelity <- function(model, x, background, attr, predict_fun, ...) {
  ref <- .reference_row(background)
  p_x <- .validate_predict(do.call(predict_fun, c(list(model = model, newdata = x), list(...))), 1L)[1L]
  p_ref <- .validate_predict(do.call(predict_fun, c(list(model = model, newdata = ref), list(...))), 1L)[1L]
  delta <- p_x - p_ref
  order_j <- order(abs(attr), decreasing = TRUE)
  drops <- numeric(length(order_j) + 1L)
  drops[1L] <- 0
  for (k in seq_along(order_j)) {
    xx <- x
    jj <- order_j[seq_len(k)]
    for (j in jj) xx[[j]] <- ref[[j]]
    p_k <- .validate_predict(do.call(predict_fun, c(list(model = model, newdata = xx), list(...))), 1L)[1L]
    drops[k + 1L] <- abs(p_x - p_k)
  }
  expected <- c(0, cumsum(abs(attr)))
  if (max(expected) > 0) expected <- expected / max(expected) * abs(delta)
  curve <- 1 - mean(abs(drops - expected)) / max(abs(delta), 1e-8)
  additive <- 1 - abs(delta - sum(attr)) / max(abs(delta), 1e-8)
  list(additive = .clamp01(additive), deletion = .clamp01(curve),
       score = .clamp01(mean(c(additive, curve))))
}

#' Statistical quality audit of a local explanation
#'
#' @param model A fitted model.
#' @param data Background/reference data frame.
#' @param newdata One-row data frame to explain.
#' @param predict_fun Optional model prediction function.
#' @param explain_fun Optional attribution function with arguments
#'   `model`, `newdata`, and `background` returning a numeric matrix.
#' @param n_boot Number of background bootstrap replications.
#' @param n_perturb Number of local perturbation candidates.
#' @param conf_level Confidence level for percentile intervals.
#' @param prediction_tolerance Relative tolerance for prediction-preserving
#'   perturbations.
#' @param min_kept Minimum number of prediction-preserving perturbations.
#' @param seed Optional random seed.
#' @param thresholds Named list with `max_relative_width`, `min_stability`,
#'   and `min_fidelity`.
#' @param ... Additional arguments passed to prediction or attribution
#'   functions.
#' @return An object of class `xaiquality_audit`.
#' @export
xai_audit <- function(model, data, newdata = data[1L, , drop = FALSE],
                      predict_fun = NULL, explain_fun = NULL,
                      n_boot = 200L, n_perturb = 200L,
                      conf_level = 0.95, prediction_tolerance = 0.01,
                      min_kept = 30L, seed = NULL,
                      thresholds = list(max_relative_width = 1,
                                        min_stability = 0.75,
                                        min_fidelity = 0.75), ...) {
  data <- .validate_frame(data, "data")
  newdata <- .validate_frame(newdata, "newdata")
  .check_columns(newdata, data)
  if (nrow(newdata) != 1L) stop("newdata must contain exactly one row.", call. = FALSE)
  for (nm in c("n_boot", "n_perturb", "min_kept")) {
    val <- get(nm)
    if (length(val) != 1L || !is.finite(val) || val < 1 || val != as.integer(val)) {
      stop(nm, " must be one positive integer.", call. = FALSE)
    }
  }
  if (conf_level <= 0 || conf_level >= 1) stop("conf_level must be between 0 and 1.", call. = FALSE)
  if (prediction_tolerance < 0) stop("prediction_tolerance must be non-negative.", call. = FALSE)
  thresholds <- utils::modifyList(list(max_relative_width = 1,
                                       min_stability = 0.75,
                                       min_fidelity = 0.75), thresholds)
  if (any(!is.finite(unlist(thresholds))) || thresholds$max_relative_width < 0 ||
      thresholds$min_stability < 0 || thresholds$min_stability > 1 ||
      thresholds$min_fidelity < 0 || thresholds$min_fidelity > 1) {
    stop("thresholds contain invalid values.", call. = FALSE)
  }
  predict_fun <- predict_fun %||% .default_predict
  if (!is.function(predict_fun)) stop("predict_fun must be a function.", call. = FALSE)
  explain_fun <- explain_fun %||% xai_attribution
  if (!is.function(explain_fun)) stop("explain_fun must be a function.", call. = FALSE)
  if (!is.null(seed)) set.seed(seed)
  call_args <- list(model = model, newdata = newdata, background = data)
  if (identical(explain_fun, xai_attribution)) {
    point <- do.call(explain_fun, c(call_args, list(predict_fun = predict_fun), list(...)))
  } else {
    point <- do.call(explain_fun, c(call_args, list(...)))
  }
  point <- as.matrix(point)
  if (nrow(point) != 1L || ncol(point) != ncol(data) || is.null(colnames(point))) {
    stop("explain_fun must return a one-row numeric matrix with one column per feature.", call. = FALSE)
  }
  if (any(!is.finite(point))) stop("explain_fun returned non-finite values.", call. = FALSE)
  colnames(point) <- names(data)
  boot <- matrix(NA_real_, nrow = n_boot, ncol = ncol(data),
                 dimnames = list(NULL, names(data)))
  for (b in seq_len(n_boot)) {
    idx <- sample.int(nrow(data), nrow(data), replace = TRUE)
    bg_b <- data[idx, , drop = FALSE]
    if (identical(explain_fun, xai_attribution)) {
      z <- do.call(explain_fun, list(model = model, newdata = newdata,
                                     background = bg_b, predict_fun = predict_fun))
    } else {
      z <- do.call(explain_fun, c(list(model = model, newdata = newdata,
                                       background = bg_b), list(...)))
    }
    boot[b, ] <- as.numeric(z[1L, ])
  }
  alpha <- (1 - conf_level) / 2
  intervals <- data.frame(feature = names(data), estimate = as.numeric(point[1L, ]),
                          lower = apply(boot, 2L, stats::quantile, probs = alpha, na.rm = TRUE,
                                         names = FALSE),
                          upper = apply(boot, 2L, stats::quantile, probs = 1 - alpha, na.rm = TRUE,
                                         names = FALSE), stringsAsFactors = FALSE)
  intervals$width <- intervals$upper - intervals$lower
  intervals$relative_width <- intervals$width / pmax(abs(intervals$estimate), 1e-8)

  pert <- xai_perturb(newdata, data, n = n_perturb)
  p0 <- .validate_predict(do.call(predict_fun, c(list(model = model, newdata = newdata), list(...))), 1L)[1L]
  pp <- .validate_predict(do.call(predict_fun, c(list(model = model, newdata = pert), list(...))), nrow(pert))
  keep <- abs(pp - p0) <= prediction_tolerance * .prediction_scale(p0)
  kept <- pert[keep, , drop = FALSE]
  if (nrow(kept) > 0L) {
    st_attr <- if (identical(explain_fun, xai_attribution)) {
      do.call(explain_fun, list(model = model, newdata = kept, background = data,
                                predict_fun = predict_fun))
    } else {
      do.call(explain_fun, c(list(model = model, newdata = kept, background = data), list(...)))
    }
    st_attr <- as.matrix(st_attr)
  } else st_attr <- matrix(numeric(), nrow = 0L, ncol = ncol(data))
  stability <- data.frame(feature = names(data), rank_stability = NA_real_,
                          sign_agreement = NA_real_, stringsAsFactors = FALSE)
  if (nrow(st_attr) >= 1L) {
    rank_scores <- vapply(seq_len(nrow(st_attr)), function(i)
      .safe_spearman(abs(st_attr[i, ]), abs(point[1L, ])), numeric(1L))
    global_rank <- mean(rank_scores)
    stability$rank_stability <- rep(global_rank, ncol(data))
    stability$sign_agreement <- vapply(seq_len(ncol(st_attr)), function(j)
      .sign_agreement(st_attr[, j], rep(point[1L, j], nrow(st_attr))), numeric(1L))
  }
  stability$score <- rowMeans(stability[, c("rank_stability", "sign_agreement")], na.rm = TRUE)
  stability$score[!is.finite(stability$score)] <- NA_real_
  fidelity <- .deletion_fidelity(model, newdata, data, as.numeric(point[1L, ]), predict_fun, ...)
  max_width <- max(intervals$relative_width, na.rm = TRUE)
  mean_stability <- if (nrow(kept) >= min_kept) mean(stability$score, na.rm = TRUE) else NA_real_
  if (nrow(kept) < min_kept) {
    decision <- "insufficient_evidence"
  } else if (max_width > thresholds$max_relative_width) {
    decision <- "uncertain"
  } else if (!is.finite(mean_stability) || mean_stability < thresholds$min_stability) {
    decision <- "unstable"
  } else if (fidelity$score < thresholds$min_fidelity) {
    decision <- "unfaithful"
  } else decision <- "reliable"
  out <- list(point = intervals, bootstrap = boot, stability = stability,
              fidelity = fidelity, decision = decision,
              kept_perturbations = nrow(kept), total_perturbations = nrow(pert),
              settings = list(n_boot = n_boot, n_perturb = n_perturb,
                              conf_level = conf_level,
                              prediction_tolerance = prediction_tolerance,
                              min_kept = min_kept, thresholds = thresholds),
              call = match.call(), session = utils::sessionInfo())
  class(out) <- "xaiquality_audit"
  out
}

#' @export
print.xaiquality_audit <- function(x, ...) {
  cat("xaiquality explanation audit\n")
  cat("Decision:", x$decision, "\n")
  cat("Prediction-preserving perturbations:", x$kept_perturbations, "/",
      x$total_perturbations, "\n")
  cat("Fidelity score:", format(round(x$fidelity$score, 3), nsmall = 3), "\n\n")
  print(x$point, row.names = FALSE)
  invisible(x)
}

#' Summarize one or more explanation audits
#'
#' @param x An `xaiquality_audit` object or a list of such objects.
#' @param ... Unused.
#' @return A data frame of explanation estimates and quality diagnostics.
#' @export
xai_summary <- function(x, ...) {
  audits <- if (inherits(x, "xaiquality_audit")) list(x) else x
  if (!is.list(audits) || !all(vapply(audits, inherits, logical(1), "xaiquality_audit"))) {
    stop("x must be an xaiquality_audit object or a list of them.", call. = FALSE)
  }
  do.call(rbind, lapply(seq_along(audits), function(i) {
    z <- audits[[i]]
    out <- z$point
    out$decision <- z$decision
    out$fidelity <- z$fidelity$score
    out$kept_perturbations <- z$kept_perturbations
    out$audit_id <- i
    out
  }))
}

#' Plot an explanation audit
#'
#' @param x An `xaiquality_audit` object.
#' @param ... Graphical arguments; `type` may be `"interval"` or `"stability"`.
#' @export
plot.xaiquality_audit <- function(x, ..., type = "interval") {
  if (!inherits(x, "xaiquality_audit")) stop("x must be an xaiquality_audit object.", call. = FALSE)
  type <- match.arg(type, c("interval", "stability"))
  old <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(old), add = TRUE)
  if (type == "interval") {
    d <- x$point
    ord <- order(abs(d$estimate), decreasing = TRUE)
    graphics::par(mar = c(5, 8, 4, 2))
    graphics::plot(d$estimate[ord], seq_along(ord), xlim = range(c(d$lower[ord], d$upper[ord], 0)),
                   yaxt = "n", xlab = "Estimated contribution", ylab = "",
                   main = paste("Explanation audit:", x$decision), pch = 19, ...)
    graphics::axis(2, at = seq_along(ord), labels = d$feature[ord], las = 1)
    graphics::segments(d$lower[ord], seq_along(ord), d$upper[ord], seq_along(ord))
    graphics::abline(v = 0, lty = 2, col = "grey50")
  } else {
    d <- x$stability
    graphics::par(mar = c(5, 8, 4, 2))
    graphics::barplot(d$score, names.arg = d$feature, horiz = TRUE, las = 1,
                      xlim = c(0, 1), xlab = "Stability score",
                      main = paste("Prediction-preserving stability:", x$decision), ...)
    graphics::abline(v = x$settings$thresholds$min_stability, lty = 2, col = "grey50")
  }
  invisible(x)
}
