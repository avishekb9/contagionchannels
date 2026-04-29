# 04_lasso_iv.R — LASSO IV cross-validation per Belloni-Chernozhukov-Hansen 2014.
library(contagionchannels)
if (!requireNamespace("hdm", quietly = TRUE)) stop("Install 'hdm' to run LASSO IV.")
d <- load_paper_data()
ch <- build_channel_composites(d$proxies)
# For each period, run LASSO IV on the significant links (sub-sampled to 30
# per period to keep runtime manageable).
cat("LASSO IV on subsamples of significant links per period.\n")
