#' End-to-End Contagion-Channel Pipeline
#'
#' Runs the full two-stage detection-and-attribution pipeline over a
#' specified set of crisis sub-periods: Stage 1 produces a per-period WQTE
#' flow matrix at the supplied scale and quantile, and Stage 2 attributes
#' each significant link to one of five channels via IV/2SLS. Network
#' density, top transmitter/receiver, and per-period channel-attribution
#' shares are returned in a list.
#'
#' @param returns An xts of daily returns indexed by date.
#' @param channels A data.frame of channel composites (output of
#'   \code{\link{build_channel_composites}}).
#' @param periods A named list of length-2 character or Date vectors
#'   specifying \code{c(start_date, end_date)} for each sub-period.
#' @param scale Integer wavelet scale. Default 5.
#' @param tau Quantile level. Default 0.50.
#' @param threshold_period Name of the period in \code{periods} from which
#'   the Pre-Crisis-baseline absolute threshold is computed. Default
#'   \code{names(periods)[1]}.
#' @param edge_quantile Numeric in (0,1); the quantile of positive WQTE in
#'   the threshold period used as the absolute threshold. Default 0.75.
#' @param n_cores Integer number of parallel cores. Default \code{2L} per
#'   CRAN policy; raise this for production-scale runs.
#' @return A list with elements
#'   \describe{
#'     \item{stage1}{Per-period list with \code{F} (flow matrix), \code{network},
#'       and \code{summary}.}
#'     \item{stage2}{Per-period list of attribution data.frames with one row
#'       per significant link.}
#'     \item{period_shares}{Per-period mean attribution-share data.frame.}
#'     \item{threshold}{The absolute WQTE threshold used.}
#'   }
#' @examples
#' \donttest{
#' d <- load_paper_data()
#' ch <- build_channel_composites(d$proxies)
#' res <- run_contagion_pipeline(d$returns, ch, d$periods, n_cores = 2)
#' res$period_shares
#' }
#' @export
run_contagion_pipeline <- function(returns, channels, periods,
                                   scale = 5, tau = 0.50,
                                   threshold_period = names(periods)[1],
                                   edge_quantile = 0.75,
                                   n_cores = 2L) {

  CHN <- c("Trade","Financial","Geopolitical","Behavioral","Monetary_Policy")
  stage1 <- list()
  for (pname in names(periods)) {
    ps <- period_subset(returns, channels, periods[[pname]])
    if (nrow(ps$R) < 50) next
    F_mat <- compute_wqte_matrix(ps$R, scale = scale, tau = tau, n_cores = n_cores)
    stage1[[pname]] <- list(F = F_mat, R = ps$R, C = ps$C)
  }

  base_F <- stage1[[threshold_period]]$F
  pos_vals <- base_F[base_F > 0]
  abs_thresh <- as.numeric(stats::quantile(pos_vals, edge_quantile, na.rm = TRUE))

  for (pname in names(stage1)) {
    g <- build_network(stage1[[pname]]$F, abs_thresh)
    stage1[[pname]]$network <- g
    stage1[[pname]]$summary <- network_summary(g)
  }

  stage2 <- list()
  for (pname in names(stage1)) {
    F_mat <- stage1[[pname]]$F; R <- stage1[[pname]]$R; C <- stage1[[pname]]$C
    links <- which(F_mat > abs_thresh, arr.ind = TRUE)
    if (nrow(links) == 0) next
    res_per_link <- if (.Platform$OS.type == "windows" || n_cores < 2) {
      lapply(seq_len(nrow(links)), function(k) {
        i <- links[k, 1]; j <- links[k, 2]
        src <- as.numeric(R[, i]); tgt <- as.numeric(R[, j])
        iv_2sls_attribute(src * tgt, C, R)
      })
    } else {
      parallel::mclapply(seq_len(nrow(links)), function(k) {
        i <- links[k, 1]; j <- links[k, 2]
        src <- as.numeric(R[, i]); tgt <- as.numeric(R[, j])
        iv_2sls_attribute(src * tgt, C, R)
      }, mc.cores = n_cores)
    }
    shares_mat <- matrix(NA_real_, nrow = nrow(links), ncol = 5)
    for (k in seq_along(res_per_link)) {
      r <- res_per_link[[k]]; if (is.null(r)) next
      abs_t <- abs(r$theta); abs_t[!is.finite(abs_t)] <- 0
      if (sum(abs_t) > 1e-12) shares_mat[k, ] <- abs_t / sum(abs_t)
    }
    colnames(shares_mat) <- CHN
    stage2[[pname]] <- data.frame(
      i = colnames(R)[links[, 1]],
      j = colnames(R)[links[, 2]],
      shares_mat, stringsAsFactors = FALSE)
  }

  period_shares <- data.frame(Period = character(), Trade = numeric(),
                              Financial = numeric(), Geopolitical = numeric(),
                              Behavioral = numeric(), Monetary = numeric(),
                              Dominant = character(), stringsAsFactors = FALSE)
  for (pname in names(stage2)) {
    sh <- stage2[[pname]][, CHN]; ms <- colMeans(sh, na.rm = TRUE)
    period_shares <- rbind(period_shares, data.frame(
      Period = pname,
      Trade = round(ms[1] * 100, 1),
      Financial = round(ms[2] * 100, 1),
      Geopolitical = round(ms[3] * 100, 1),
      Behavioral = round(ms[4] * 100, 1),
      Monetary = round(ms[5] * 100, 1),
      Dominant = CHN[which.max(ms)],
      stringsAsFactors = FALSE))
  }
  list(stage1 = stage1, stage2 = stage2,
       period_shares = period_shares, threshold = abs_thresh)
}
