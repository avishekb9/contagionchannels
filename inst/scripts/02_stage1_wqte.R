# 02_stage1_wqte.R — Stage 1: Wavelet-Quantile Transfer Entropy detection.
library(contagionchannels)
d <- load_paper_data()
ch <- build_channel_composites(d$proxies)
n_cores <- max(1, parallel::detectCores() - 2)
stage1 <- list()
for (pname in names(d$periods)) {
  ps <- period_subset(d$returns, ch, d$periods[[pname]])
  if (nrow(ps$R) < 50) next
  stage1[[pname]] <- list(
    F = compute_wqte_matrix(ps$R, scale = 5, tau = 0.50, n_cores = n_cores),
    R = ps$R, C = ps$C)
  cat(sprintf("  %s: max QTE = %.4f\n", pname, max(stage1[[pname]]$F)))
}
saveRDS(stage1, file.path(tempdir(), "stage1.rds"))
