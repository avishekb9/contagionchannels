# 05_local_projections.R — Jordà 2005 local projections at h=1, 5, 22.
library(contagionchannels)
d <- load_paper_data()
ch <- build_channel_composites(d$proxies)
ps <- period_subset(d$returns, ch, d$periods$GFC)
src <- as.numeric(ps$R[, "USA"]); tgt <- as.numeric(ps$R[, "SouthKorea"])
lp <- local_projections(src * tgt, ps$C, ps$R, horizons = c(1, 5, 22))
print(lp)
