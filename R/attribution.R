CHN_DEFAULT <- c("Trade","Financial","Geopolitical","Behavioral","Monetary_Policy")

# Internal helper: assemble the IV/2SLS dataset (predictor + instrument matrix)
# for a single bilateral co-movement series.
.build_iv_dataset <- function(C_ij, ch_per, R_full,
                              channel_names = CHN_DEFAULT) {
  T0 <- nrow(ch_per); if (T0 < 80) return(NULL)
  Z_list <- list()
  for (c_ in channel_names) for (lg in c(5, 10, 15)) {
    Z_list[[paste0(c_,"_l",lg)]] <- build_lag(ch_per[[c_]], lg)
  }
  c5 <- lapply(channel_names, function(c_) build_lag(ch_per[[c_]], 5))
  names(c5) <- channel_names
  for (a in 1:(length(channel_names) - 1))
    for (b in (a + 1):length(channel_names))
      Z_list[[paste0(channel_names[a],"x",channel_names[b])]] <-
        c5[[channel_names[a]]] * c5[[channel_names[b]]]
  C_lag <- build_lag(C_ij, 1)
  f_t <- tryCatch(stats::prcomp(R_full, center = TRUE, scale. = TRUE)$x[, 1],
                  error = function(e) rep(0, nrow(R_full)))
  dat <- data.frame(C = C_ij, C_lag = C_lag, f_t = f_t,
                    ch_per[, channel_names, drop = FALSE],
                    do.call(cbind, Z_list))
  dat[stats::complete.cases(dat), , drop = FALSE]
}

#' Five-Channel IV/2SLS Channel Attribution for One Bilateral Link
#'
#' Estimates the structural equation
#' \deqn{C_{ij,t} = \alpha + \sum_{c=1}^{5} \theta_c \, \mathrm{Channel}_{c,t} +
#'  \gamma_1 f_t + \gamma_2 C_{ij,t-1} + \varepsilon_{ij,t}}
#' via two-stage least squares, treating the five channel composites as
#' endogenous and instrumenting them with their own lagged values at
#' \eqn{t-5,\,t-10,\,t-15} plus cross-channel interactions at \eqn{t-5}. The
#' first-stage F-statistic per channel, the Sargan over-identification J-test,
#' and the Durbin-Wu-Hausman endogeneity test are reported.
#'
#' @param C_ij Numeric vector of pairwise daily co-movement
#'   (\code{r_i * r_j}).
#' @param ch_per A data.frame containing the five channel composites for
#'   the current period (with columns named per \code{channel_names}).
#' @param R_full Numeric matrix of returns for the period (used to construct
#'   the global factor \eqn{f_t}).
#' @param channel_names Character vector of channel column names. Default
#'   \code{c("Trade","Financial","Geopolitical","Behavioral","Monetary_Policy")}.
#' @return A list with elements \code{theta} (5-vector of structural
#'   coefficients), \code{partial_F} (per-channel first-stage F-stats),
#'   \code{J_stat}, \code{J_p}, \code{dwh_F}, \code{dwh_p}, and \code{n_obs};
#'   or \code{NULL} if the regression cannot be run.
#' @references Stock, J. H., & Watson, M. W. (2018). Identification and
#'   Estimation of Dynamic Causal Effects in Macroeconomics Using External
#'   Instruments. Economic Journal, 128(610), 917-948. \doi{10.1111/ecoj.12593}.
#'
#'   Mertens, K., & Ravn, M. O. (2013). The Dynamic Effects of Personal and
#'   Corporate Income Tax Changes in the United States. American Economic
#'   Review, 103(4), 1212-1247. \doi{10.1257/aer.103.4.1212}.
#' @examples
#' \donttest{
#' d <- load_paper_data()
#' ch <- build_channel_composites(d$proxies)
#' p <- period_subset(d$returns, ch, d$periods$GFC)
#' src <- as.numeric(p$R[, "USA"]); tgt <- as.numeric(p$R[, "SouthKorea"])
#' fit <- iv_2sls_attribute(src * tgt, p$C, p$R)
#' fit$theta
#' }
#' @export
iv_2sls_attribute <- function(C_ij, ch_per, R_full,
                              channel_names = CHN_DEFAULT) {
  dat <- .build_iv_dataset(C_ij, ch_per, R_full, channel_names)
  if (is.null(dat) || nrow(dat) < 80) return(NULL)
  y <- dat$C
  X_exog <- as.matrix(dat[, c("C_lag", "f_t"), drop = FALSE])
  D_endo <- as.matrix(dat[, channel_names, drop = FALSE])
  Z_inst <- as.matrix(dat[, !(names(dat) %in% c("C","C_lag","f_t",channel_names)),
                          drop = FALSE])
  z_sd <- apply(Z_inst, 2, stats::sd, na.rm = TRUE)
  Z_inst <- Z_inst[, z_sd > 1e-10, drop = FALSE]
  if (ncol(Z_inst) < ncol(D_endo)) return(NULL)

  partial_out <- function(M, X) {
    fit <- stats::lm.fit(cbind(1, X), M)
    M - cbind(1, X) %*% fit$coefficients
  }
  y_p <- partial_out(matrix(y, ncol = 1), X_exog)
  D_p <- partial_out(D_endo, X_exog)
  Z_p <- partial_out(Z_inst, X_exog)

  Pz <- Z_p %*% MASS::ginv(t(Z_p) %*% Z_p) %*% t(Z_p)
  D_hat <- Pz %*% D_p
  beta <- tryCatch(MASS::ginv(t(D_hat) %*% D_hat) %*% t(D_hat) %*% y_p,
                   error = function(e) NULL)
  if (is.null(beta) || any(!is.finite(beta))) return(NULL)
  theta <- as.numeric(beta)

  partial_F <- numeric(length(channel_names))
  for (c_ in seq_along(channel_names)) {
    d_c <- D_p[, c_]
    rss_full <- sum((d_c - Z_p %*% (MASS::ginv(t(Z_p) %*% Z_p) %*% t(Z_p) %*% d_c))^2)
    rss_null <- sum(d_c^2)
    n <- length(d_c); k <- ncol(Z_p)
    partial_F[c_] <- if (rss_full > 0) ((rss_null - rss_full) / k) / (rss_full / max(n - k, 1)) else NA_real_
  }
  resid_2sls <- as.numeric(y_p - D_p %*% theta)
  K <- ncol(Z_p); L <- ncol(D_p); J_stat <- NA_real_; J_p <- NA_real_
  if (K > L) {
    Pz_resid <- Z_p %*% MASS::ginv(t(Z_p) %*% Z_p) %*% t(Z_p) %*% resid_2sls
    sigma2 <- sum(resid_2sls^2) / length(resid_2sls)
    J_stat <- if (sigma2 > 0) sum(resid_2sls * Pz_resid) / sigma2 else NA_real_
    J_p <- if (is.finite(J_stat)) stats::pchisq(J_stat, df = K - L, lower.tail = FALSE) else NA_real_
  }
  resid_first <- D_p - D_hat
  dwh_F <- tryCatch({
    rss_dwh <- sum(stats::residuals(stats::lm(y_p ~ D_p + resid_first - 1))^2)
    rss_null_dwh <- sum(stats::lm(y_p ~ D_p - 1)$residuals^2)
    n <- length(y_p)
    ((rss_null_dwh - rss_dwh) / 5) / (rss_dwh / max(n - 10, 1))
  }, error = function(e) NA_real_)
  dwh_p <- if (is.finite(dwh_F)) stats::pf(dwh_F, 5, length(y_p) - 10, lower.tail = FALSE) else NA_real_

  list(theta = theta, partial_F = partial_F,
       J_stat = J_stat, J_p = J_p, K = K, L = L,
       dwh_F = dwh_F, dwh_p = dwh_p, n_obs = length(y_p))
}

#' LASSO-Based Instrument Selection IV Attribution (Belloni-Chernozhukov-Hansen)
#'
#' Estimates the channel-attribution coefficients via post-double-selection
#' LASSO IV with the high-dimensional instrument set. Uses
#' \code{hdm::rlassoIV} per channel with controls for the other endogenous
#' regressors. Requires the optional \pkg{hdm} package.
#'
#' @inheritParams iv_2sls_attribute
#' @return A list with elements \code{theta} and \code{se}, or \code{NULL}.
#' @references Belloni, A., Chernozhukov, V., & Hansen, C. (2014). Inference
#'   on Treatment Effects after Selection among High-Dimensional Controls.
#'   Review of Economic Studies, 81(2), 608-650.
#'   \doi{10.1093/restud/rdt044}.
#' @examples
#' \donttest{
#' if (requireNamespace("hdm", quietly = TRUE)) {
#'   d <- load_paper_data()
#'   ch <- build_channel_composites(d$proxies)
#'   p <- period_subset(d$returns, ch, d$periods$GFC)
#'   src <- as.numeric(p$R[, "USA"]); tgt <- as.numeric(p$R[, "SouthKorea"])
#'   fit <- lasso_iv_attribute(src * tgt, p$C, p$R)
#' }
#' }
#' @export
lasso_iv_attribute <- function(C_ij, ch_per, R_full,
                               channel_names = CHN_DEFAULT) {
  if (!requireNamespace("hdm", quietly = TRUE)) {
    stop("Package 'hdm' is required for LASSO IV; install via install.packages('hdm').")
  }
  dat <- .build_iv_dataset(C_ij, ch_per, R_full, channel_names)
  if (is.null(dat) || nrow(dat) < 80) return(NULL)
  y <- dat$C
  X_exog <- as.matrix(dat[, c("C_lag", "f_t"), drop = FALSE])
  D_endo <- as.matrix(dat[, channel_names, drop = FALSE])
  Z_inst <- as.matrix(dat[, !(names(dat) %in% c("C","C_lag","f_t",channel_names)),
                          drop = FALSE])
  z_sd <- apply(Z_inst, 2, stats::sd, na.rm = TRUE)
  Z_inst <- Z_inst[, z_sd > 1e-10, drop = FALSE]
  if (ncol(Z_inst) < 5) return(NULL)
  thetas <- numeric(length(channel_names))
  ses    <- numeric(length(channel_names))
  for (c_ in seq_along(channel_names)) {
    other_endo <- D_endo[, -c_, drop = FALSE]
    X_full <- cbind(X_exog, other_endo)
    fit <- tryCatch(
      hdm::rlassoIV(x = X_full, d = D_endo[, c_], y = y, z = Z_inst,
                    select.X = TRUE, select.Z = TRUE),
      error = function(e) NULL)
    if (is.null(fit)) { thetas[c_] <- NA_real_; ses[c_] <- NA_real_; next }
    thetas[c_] <- as.numeric(stats::coef(fit))
    ses[c_]    <- as.numeric(fit$se)
  }
  list(theta = thetas, se = ses)
}

#' Local-Projection Channel Attribution at Multiple Horizons
#'
#' Estimates horizon-specific impulse responses of the pairwise co-movement
#' to each channel composite at horizons \eqn{h \in \{1, 5, 22\}} days
#' following Jorda (2005). The local projection at horizon \eqn{h} estimates
#' \deqn{C_{ij,t+h} = \alpha_h + \beta_{c,h} \, \mathrm{Channel}_{c,t} +
#'                    \mathrm{controls} + u_{ij,t+h}}
#' separately for each channel \eqn{c}, with the other four channels and the
#' lagged co-movement and global factor entering as controls.
#'
#' @inheritParams iv_2sls_attribute
#' @param horizons Integer vector of horizons. Default \code{c(1, 5, 22)}.
#' @return A list with one element per horizon; each element is a
#'   length-\code{length(channel_names)} numeric vector of LP coefficients.
#' @references Jorda, O. (2005). Estimation and Inference of Impulse
#'   Responses by Local Projections. American Economic Review, 95(1),
#'   161-182. \doi{10.1257/0002828053828518}.
#'
#'   Plagborg-Moller, M., & Wolf, C. K. (2021). Local Projections and VARs
#'   Estimate the Same Impulse Responses. Econometrica, 89(2), 955-980.
#'   \doi{10.3982/ECTA17813}.
#' @examples
#' \donttest{
#' d <- load_paper_data()
#' ch <- build_channel_composites(d$proxies)
#' p <- period_subset(d$returns, ch, d$periods$GFC)
#' src <- as.numeric(p$R[, "USA"]); tgt <- as.numeric(p$R[, "SouthKorea"])
#' lp <- local_projections(src * tgt, p$C, p$R)
#' }
#' @export
local_projections <- function(C_ij, ch_per, R_full, horizons = c(1, 5, 22),
                              channel_names = CHN_DEFAULT) {
  T0 <- length(C_ij); if (T0 < 80) return(NULL)
  C_lag <- build_lag(C_ij, 1)
  f_t <- tryCatch(stats::prcomp(R_full, center = TRUE, scale. = TRUE)$x[, 1],
                  error = function(e) rep(0, nrow(R_full)))
  out <- list()
  for (h in horizons) {
    C_lead <- c(C_ij[(h + 1):T0], rep(NA_real_, h))
    betas <- numeric(length(channel_names))
    for (c_ in seq_along(channel_names)) {
      ch_c <- ch_per[[channel_names[c_]]]
      other <- ch_per[, channel_names[-c_], drop = FALSE]
      df <- data.frame(y = C_lead, x = ch_c, C_lag = C_lag, f_t = f_t, other)
      df <- df[stats::complete.cases(df), , drop = FALSE]
      if (nrow(df) < 50) { betas[c_] <- NA_real_; next }
      fit <- tryCatch(stats::lm(y ~ ., data = df), error = function(e) NULL)
      betas[c_] <- if (is.null(fit)) NA_real_ else as.numeric(stats::coef(fit)["x"])
    }
    out[[paste0("h", h)]] <- betas
  }
  out
}

#' Heteroskedasticity-Based Identification (Rigobon 2003)
#'
#' Identifies the channel-attribution coefficients by exploiting regime
#' shifts in the variance of returns within the period. Useful when the
#' Sargan over-identification test rejects the joint validity of external
#' instruments and an alternative identification strategy is required.
#'
#' @inheritParams iv_2sls_attribute
#' @return A list with element \code{theta}: a length-five numeric vector of
#'   structural coefficients, or \code{NULL}.
#' @references Rigobon, R. (2003). Identification through
#'   Heteroskedasticity. Review of Economics and Statistics, 85(4),
#'   777-792. \doi{10.1162/003465303772815727}.
#' @examples
#' \donttest{
#' d <- load_paper_data()
#' ch <- build_channel_composites(d$proxies)
#' p <- period_subset(d$returns, ch, d$periods$GFC)
#' src <- as.numeric(p$R[, "USA"]); tgt <- as.numeric(p$R[, "SouthKorea"])
#' rig <- rigobon_id(src * tgt, p$C, p$R)
#' }
#' @export
rigobon_id <- function(C_ij, ch_per, R_full, channel_names = CHN_DEFAULT) {
  T0 <- length(C_ij); if (T0 < 80) return(NULL)
  rv <- zoo::rollapply(rowMeans(R_full^2, na.rm = TRUE), width = 21,
                       FUN = mean, fill = NA, align = "right")
  med_rv <- stats::median(rv, na.rm = TRUE)
  H <- which(rv > med_rv); L <- which(rv <= med_rv)
  if (length(H) < 30 || length(L) < 30) return(NULL)
  thetas <- numeric(length(channel_names))
  for (c_ in seq_along(channel_names)) {
    ch_c <- ch_per[[channel_names[c_]]]
    cov_H <- stats::cov(C_ij[H], ch_c[H], use = "pairwise.complete.obs")
    cov_L <- stats::cov(C_ij[L], ch_c[L], use = "pairwise.complete.obs")
    var_H <- stats::var(ch_c[H], na.rm = TRUE)
    var_L <- stats::var(ch_c[L], na.rm = TRUE)
    denom <- var_H - var_L
    thetas[c_] <- if (!is.finite(denom) || abs(denom) < 1e-12) NA_real_
                  else (cov_H - cov_L) / denom
  }
  list(theta = thetas)
}

#' Cinelli-Hazlett Robustness Value
#'
#' Computes the partial-\eqn{R^2} that an unobserved confounder would need
#' to share with both the treatment and the outcome to drive the structural
#' coefficient to zero. The robustness value is bounded in [0, 1]; values
#' near zero indicate that even a weakly correlated confounder could explain
#' away the result, while values near one indicate identification-robust
#' findings.
#'
#' @param theta Estimated structural coefficient.
#' @param se Standard error of \code{theta}.
#' @param df Residual degrees of freedom.
#' @return A scalar in \eqn{[0,1]}, or \code{NA} if inputs are invalid.
#' @references Cinelli, C., & Hazlett, C. (2020). Making Sense of
#'   Sensitivity: Extending Omitted Variable Bias. Journal of the Royal
#'   Statistical Society Series B, 82(1), 39-67. \doi{10.1111/rssb.12348}.
#' @examples
#' cinelli_hazlett_rv(theta = 0.4, se = 0.1, df = 200)
#' @export
cinelli_hazlett_rv <- function(theta, se, df) {
  if (!is.finite(theta) || !is.finite(se) || se < 1e-12 || df <= 0) return(NA_real_)
  t_val <- theta / se
  f2 <- t_val^2 / df
  0.5 * (sqrt(f2^2 + 4 * f2) - f2)
}
