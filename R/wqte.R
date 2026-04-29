#' MODWT Wavelet Detail at a Specified Scale
#'
#' Returns the MODWT detail coefficients of a return series at the specified
#' scale, using the Daubechies least-asymmetric filter of length 8 (LA8).
#' The maximal-overlap discrete wavelet transform is shift-invariant and
#' aligned with the original time-axis, making it suited to financial
#' returns; see Percival and Walden (2000).
#'
#' @param x Numeric vector of returns.
#' @param scale Integer scale (1-6) corresponding to dyadic horizons of
#'   \eqn{[2^s, 2^{s+1}]} trading days. Default 5 (32-64 day horizon).
#' @param J Integer maximum decomposition level. Default 6.
#' @param filter Character; the wavelet filter family to use. Default
#'   \code{"la8"} for the LA8 filter. See \code{\link[waveslim]{modwt}}.
#' @return Numeric vector of detail coefficients at scale \code{scale}.
#' @references Percival, D. B., & Walden, A. T. (2000). \emph{Wavelet
#'   Methods for Time Series Analysis}. Cambridge University Press.
#' @examples
#' x <- rnorm(512)
#' d5 <- modwt_detail(x, scale = 5)
#' length(d5)
#' @export
modwt_detail <- function(x, scale = 5, J = 6, filter = "la8") {
  x <- as.numeric(x); ok <- is.finite(x); x[!ok] <- 0
  pad_len <- 2^ceiling(log2(length(x)))
  if (pad_len > length(x)) x <- c(x, rep(0, pad_len - length(x)))
  w <- waveslim::modwt(x, wf = filter, n.levels = J)
  d <- w[[paste0("d", scale)]]
  d[seq_len(length(ok))][1:sum(ok)]
}

#' Pairwise Wavelet-Quantile Transfer Entropy
#'
#' Estimates the directional information flow from one wavelet-detail series
#' \code{x} to another \code{y} at the specified quantile, following the
#' quantile-regression-based transfer-entropy estimator. A positive value
#' indicates that conditioning on the past of \code{x} improves the
#' conditional-quantile prediction of \code{y} beyond what \code{y}'s own
#' past supplies.
#'
#' @param x Numeric source series (typically a MODWT detail coefficient).
#' @param y Numeric target series (typically a MODWT detail coefficient).
#' @param tau Quantile level in (0,1). Default 0.50 (median).
#' @return A scalar; \code{NA} if there are insufficient observations or the
#'   quantile regressions fail to converge.
#' @references Schreiber, T. (2000). Measuring Information Transfer.
#'   Physical Review Letters, 85(2), 461.
#'   \doi{10.1103/PhysRevLett.85.461}.
#'
#'   Han, H., Linton, O., Oka, T., & Whang, Y.-J. (2016). The Cross-
#'   Quantilogram. Journal of Econometrics, 193(1), 251-270.
#'   \doi{10.1016/j.jeconom.2016.03.001}.
#' @examples
#' x <- rnorm(500); y <- 0.3 * c(0, x[-500]) + rnorm(500)
#' qte_pair(x, y, tau = 0.5)
#' @export
qte_pair <- function(x, y, tau = 0.50) {
  n <- length(x); if (n < 50) return(NA_real_)
  Y_lead <- y[-1]; Y_lag <- y[-n]; X_lag <- x[-n]
  ok <- is.finite(Y_lead) & is.finite(Y_lag) & is.finite(X_lag)
  if (sum(ok) < 30) return(NA_real_)
  Y_lead <- Y_lead[ok]; Y_lag <- Y_lag[ok]; X_lag <- X_lag[ok]
  m1 <- tryCatch(quantreg::rq(Y_lead ~ Y_lag, tau = tau),
                 error = function(e) NULL)
  m2 <- tryCatch(quantreg::rq(Y_lead ~ Y_lag + X_lag, tau = tau),
                 error = function(e) NULL)
  if (is.null(m1) || is.null(m2)) return(NA_real_)
  e1 <- stats::residuals(m1); e2 <- stats::residuals(m2)
  s1 <- sum(abs(e1)); s2 <- sum(abs(e2))
  if (s1 < 1e-12 || s2 < 1e-12) return(NA_real_)
  log(s1) - log(s2)
}

#' Wavelet-Quantile Transfer Entropy Matrix
#'
#' Computes the bilateral WQTE matrix for a returns panel at one wavelet
#' scale and one quantile, producing the directed flow matrix that serves as
#' the Stage-1 input to the structural-attribution layer.
#'
#' @param returns An xts or matrix of returns (rows = time, cols = markets).
#' @param scale Integer wavelet scale. Default 5.
#' @param tau Quantile level. Default 0.50.
#' @param n_cores Integer; number of parallel cores for \code{mclapply}.
#'   Default \code{2L} per CRAN policy; on Windows the function falls back to
#'   serial \code{lapply}. Increase for production-scale workloads.
#' @return An \eqn{N \times N} matrix where entry \eqn{(i,j)} is the WQTE
#'   from market \eqn{i} to market \eqn{j} at the specified scale and
#'   quantile; row and column names are taken from \code{colnames(returns)}.
#' @references Bhandari, A., & Parida, I. (2026).
#'   Wavelet-quantile transfer entropy for financial-market contagion.
#' @examples
#' \donttest{
#' d <- load_paper_data()
#' ix <- which(zoo::index(d$returns) >= as.Date("2008-01-01") &
#'             zoo::index(d$returns) <= as.Date("2008-12-31"))
#' F <- compute_wqte_matrix(d$returns[ix, ], scale = 5, tau = 0.50, n_cores = 2)
#' }
#' @export
compute_wqte_matrix <- function(returns, scale = 5, tau = 0.50,
                                n_cores = 2L) {
  R <- if (inherits(returns, "xts")) zoo::coredata(returns) else as.matrix(returns)
  n <- ncol(R); mkts <- colnames(R)
  if (is.null(mkts)) mkts <- paste0("M", seq_len(n))
  decomps <- lapply(seq_len(n), function(i) modwt_detail(R[, i], scale = scale))
  pairs <- expand.grid(i = seq_len(n), j = seq_len(n))
  pairs <- pairs[pairs$i != pairs$j, , drop = FALSE]
  fl <- if (.Platform$OS.type == "windows" || n_cores < 2) {
    lapply(seq_len(nrow(pairs)), function(k)
      qte_pair(decomps[[pairs$i[k]]], decomps[[pairs$j[k]]], tau = tau))
  } else {
    parallel::mclapply(seq_len(nrow(pairs)), function(k)
      qte_pair(decomps[[pairs$i[k]]], decomps[[pairs$j[k]]], tau = tau),
      mc.cores = n_cores)
  }
  flow <- matrix(0, n, n); rownames(flow) <- mkts; colnames(flow) <- mkts
  for (k in seq_len(nrow(pairs))) {
    v <- fl[[k]]
    flow[pairs$i[k], pairs$j[k]] <- if (is.null(v) || !is.finite(v)) 0 else v
  }
  flow
}
