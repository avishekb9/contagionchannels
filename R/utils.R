#' Z-score Standardisation
#'
#' Returns the z-score of a numeric vector, robust to NAs and zero-variance
#' input.
#'
#' @param x Numeric vector.
#' @return Numeric vector of the same length as \code{x} with mean zero and
#'   unit standard deviation; returns a zero vector if the input has no
#'   finite variation.
#' @examples
#' zscore(rnorm(100))
#' @export
zscore <- function(x) {
  x <- as.numeric(x)
  m <- mean(x, na.rm = TRUE); s <- stats::sd(x, na.rm = TRUE)
  if (!is.finite(s) || s < 1e-12) return(rep(0, length(x)))
  (x - m) / s
}

#' Build a Lagged Vector with Leading NAs
#'
#' Returns a vector \eqn{x_{t-\ell}} where the first \eqn{\ell} positions are
#' \code{NA} and the remaining positions are the lagged values of \code{x}.
#' Used throughout the package for instrument and predictor construction.
#'
#' @param x Numeric vector.
#' @param lg Positive integer lag.
#' @return Numeric vector of the same length as \code{x}.
#' @examples
#' build_lag(1:10, 3)
#' @export
build_lag <- function(x, lg) {
  c(rep(NA_real_, lg), x[seq_len(length(x) - lg)])
}

#' Orthogonalise One Series Against Another
#'
#' Returns the residuals from a regression of \code{y} on \code{x}; the
#' residual is by construction orthogonal to \code{x} in the sample. This
#' is the pre-processing step used to construct the behavioural channel
#' composite, which is orthogonalised against the financial composite to
#' avoid the within-VIX decomposition that contaminates cross-channel
#' identification when both composites share VIX-derivative inputs.
#'
#' @param y Numeric vector to be orthogonalised.
#' @param x Numeric vector against which \code{y} is orthogonalised.
#' @return Numeric vector of length \code{length(y)} containing the residuals.
#' @examples
#' a <- rnorm(100); b <- 0.5 * a + rnorm(100); cor(a, orthogonalise_residual(b, a))
#' @export
orthogonalise_residual <- function(y, x) {
  ok <- is.finite(y) & is.finite(x)
  out <- rep(NA_real_, length(y))
  if (sum(ok) > 30) {
    fit <- stats::lm(y[ok] ~ x[ok])
    out[ok] <- stats::residuals(fit)
  } else out <- y
  out
}

#' Subset a Returns and Channel Panel by Period
#'
#' Selects the rows of an xts returns object and the matching rows of a
#' channel-composite data.frame that fall within a date range.
#'
#' @param returns_xts An xts object of daily returns indexed by Date.
#' @param channels_df A data.frame with a \code{Date} column matching the
#'   index of \code{returns_xts}.
#' @param period_dates A character or Date vector of length 2 \code{c(start, end)}.
#' @return A list with elements \code{R} (xts subset) and \code{C}
#'   (data.frame subset).
#' @examples
#' \donttest{
#' d <- load_paper_data()
#' ch <- build_channel_composites(d$proxies)
#' p <- period_subset(d$returns, ch, c("2008-01-01","2008-12-31"))
#' nrow(p$C)
#' }
#' @export
period_subset <- function(returns_xts, channels_df, period_dates) {
  d1 <- as.Date(period_dates[1]); d2 <- as.Date(period_dates[2])
  idx <- which(zoo::index(returns_xts) >= d1 & zoo::index(returns_xts) <= d2)
  list(R = returns_xts[idx, , drop = FALSE], C = channels_df[idx, , drop = FALSE])
}

#' Load the Paper's Bundled Data
#'
#' Convenience loader returning a named list with the three bundled datasets
#' (returns, channel proxies, crisis periods) used in the paper replication.
#'
#' @return A named list with elements \code{returns}, \code{proxies}, and
#'   \code{periods}.
#' @examples
#' \donttest{ d <- load_paper_data(); str(d, max.level = 1) }
#' @export
load_paper_data <- function() {
  e <- new.env()
  utils::data("g20_returns",     package = "contagionchannels", envir = e)
  utils::data("channel_proxies", package = "contagionchannels", envir = e)
  utils::data("crisis_periods",  package = "contagionchannels", envir = e)
  list(returns = e$g20_returns,
       proxies = e$channel_proxies,
       periods = e$crisis_periods)
}

# Silence R CMD check NSE warnings from ggplot2 / tidyr column references
utils::globalVariables(c("Channel", "Density", "MeanQTE", "Period", "RV", "Share"))
