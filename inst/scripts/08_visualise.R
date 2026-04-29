# 08_visualise.R - Generate the seven publication figures.
library(contagionchannels)
res_path <- file.path(tempdir(), "pipeline_results.rds")
if (!file.exists(res_path)) stop("Run 03_stage2_attribution.R first.")
res <- readRDS(res_path)
fig_dir <- Sys.getenv("FIG_DIR", unset = file.path(tempdir(), "figures"))
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

if (requireNamespace("ggplot2", quietly = TRUE)) {
  p1 <- plot_attribution_stack(res$period_shares)
  out <- file.path(fig_dir, "fig1_attribution_stack.pdf")
  tryCatch(ggplot2::ggsave(out, p1, width = 8, height = 5, dpi = 300),
           error = function(e) message("ggsave failed: ", e$message))
  message(sprintf("Wrote figures to %s", fig_dir))
} else {
  message("Install ggplot2 to produce figures.")
}
