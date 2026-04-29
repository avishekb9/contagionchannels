# 03_stage2_attribution.R — Stage 2: IV/2SLS attribution per significant link.
library(contagionchannels)
d <- load_paper_data()
ch <- build_channel_composites(d$proxies)
res <- run_contagion_pipeline(d$returns, ch, d$periods,
                               scale = 5, tau = 0.50,
                               n_cores = max(1, parallel::detectCores() - 2))
print(res$period_shares)
saveRDS(res, file.path(tempdir(), "pipeline_results.rds"))
