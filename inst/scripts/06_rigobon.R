# 06_rigobon.R — Rigobon 2003 heteroskedasticity-based identification.
library(contagionchannels)
d <- load_paper_data()
ch <- build_channel_composites(d$proxies)
ps <- period_subset(d$returns, ch, d$periods$GFC)
src <- as.numeric(ps$R[, "USA"]); tgt <- as.numeric(ps$R[, "SouthKorea"])
rg <- rigobon_id(src * tgt, ps$C, ps$R)
print(rg)
