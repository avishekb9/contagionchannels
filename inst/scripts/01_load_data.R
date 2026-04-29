# 01_load_data.R — Load the bundled datasets for replication.
library(contagionchannels)
d <- load_paper_data()
cat(sprintf("Loaded: returns %dx%d ; proxies %dx%d ; %d crisis periods.\n",
            nrow(d$returns), ncol(d$returns),
            nrow(d$proxies), ncol(d$proxies), length(d$periods)))
