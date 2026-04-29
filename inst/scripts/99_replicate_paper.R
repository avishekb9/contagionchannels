# =============================================================================
#  99_replicate_paper.R
#  Master replication script — runs the full pipeline end-to-end and writes
#  every result needed to reproduce the headline tables and figures.
#
#  Usage:
#    Rscript 99_replicate_paper.R
#  or interactively:
#    source("99_replicate_paper.R")
#
#  Environment variables:
#    OUT_DIR — output directory (default: tempdir() with timestamp)
#    N_CORES — number of parallel cores (default: detectCores() - 2)
# =============================================================================

suppressMessages({
  library(contagionchannels)
  library(parallel); library(zoo); library(xts)
})

OUT_DIR <- Sys.getenv("OUT_DIR", unset = "")
if (OUT_DIR == "") {
  OUT_DIR <- file.path(tempdir(),
                       sprintf("contagion_results_%s",
                               format(Sys.time(), "%Y%m%d_%H%M%S")))
}
N_CORES <- as.integer(Sys.getenv("N_CORES", unset = max(1, detectCores() - 2)))
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)
cat(sprintf("[contagionchannels] OUT_DIR=%s | N_CORES=%d\n", OUT_DIR, N_CORES))

# ---- 1. Load bundled datasets ----------------------------------------------
d <- load_paper_data()
returns <- d$returns; periods <- d$periods
cat(sprintf("[01] Loaded data: %d days x %d markets\n",
            nrow(returns), ncol(returns)))

# ---- 2. Build channel composites -------------------------------------------
ch <- build_channel_composites(d$proxies)
cat(sprintf("[02] Composites: 5 channels; trade SD=%.3f (was 0 in pre-build)\n",
            sd(ch$Trade)))

# ---- 3. Stage 1: WQTE detection per period ---------------------------------
cat("[03] Stage-1 WQTE per period (this may take several minutes)\n")
t0 <- Sys.time()
res <- run_contagion_pipeline(returns, ch, periods,
                               scale = 5, tau = 0.50,
                               threshold_period = "PreCrisis",
                               edge_quantile = 0.75,
                               n_cores = N_CORES)
cat(sprintf("    Pipeline wall time: %.1f minutes\n",
            as.numeric(Sys.time() - t0, units = "mins")))
saveRDS(res, file.path(OUT_DIR, "pipeline_results.rds"))

# ---- 4. Per-period summary -------------------------------------------------
stage1_summary <- do.call(rbind, lapply(names(res$stage1), function(p) {
  s <- res$stage1[[p]]
  pos <- s$F[s$F > 0]
  data.frame(Period = p,
             MeanQTE = round(mean(pos, na.rm = TRUE), 4),
             MaxQTE  = round(max(s$F, na.rm = TRUE), 4),
             Density = round(s$summary$density * 100, 2),
             NEdges  = s$summary$n_edges,
             TopTransmitter = colnames(s$F)[which.max(s$summary$out_degree)],
             TopReceiver    = colnames(s$F)[which.max(s$summary$in_degree)],
             stringsAsFactors = FALSE)
}))
write.csv(stage1_summary, file.path(OUT_DIR, "stage1_summary.csv"), row.names = FALSE)
cat("[04] Stage-1 summary:\n"); print(stage1_summary)

write.csv(res$period_shares, file.path(OUT_DIR, "period_attribution_shares.csv"),
          row.names = FALSE)
cat("[05] Stage-2 attribution shares:\n"); print(res$period_shares)

# ---- 5. Walktrap communities -----------------------------------------------
walk <- list()
for (p in names(res$stage1)) {
  walk[[p]] <- walktrap_communities(res$stage1[[p]]$network)
}
saveRDS(walk, file.path(OUT_DIR, "walktrap_communities.rds"))
cat("[06] Walktrap communities:\n")
for (p in names(walk)) {
  if (!is.null(walk[[p]])) cat(sprintf("   %s: %d communities\n",
                                       p, length(unique(walk[[p]]))))
}

# ---- 6. Top contagion links ------------------------------------------------
all_top <- do.call(rbind, lapply(names(res$stage1), function(p) {
  F <- res$stage1[[p]]$F
  ij <- which(F > res$threshold, arr.ind = TRUE)
  if (nrow(ij) == 0) return(NULL)
  data.frame(Source = colnames(F)[ij[, 1]], Target = colnames(F)[ij[, 2]],
             QTE = F[ij], Period = p, stringsAsFactors = FALSE)
}))
all_top <- all_top[order(all_top$QTE, decreasing = TRUE), ]
write.csv(head(all_top, 15), file.path(OUT_DIR, "top_contagion_links.csv"),
          row.names = FALSE)
cat("[07] Top 15 contagion links saved.\n")

cat(sprintf("\n[contagionchannels] Replication complete. Outputs in %s\n", OUT_DIR))
cat("Run Rscript 08_visualise.R OUT_DIR=", OUT_DIR, " for figures.\n", sep = "")
