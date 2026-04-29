# 07_robustness.R — Cinelli-Hazlett robustness values + bootstrap CIs.
library(contagionchannels)
# Demonstrate Cinelli-Hazlett RV
rv <- cinelli_hazlett_rv(theta = 0.4, se = 0.1, df = 200)
cat(sprintf("Robustness value at theta=0.4, se=0.1, df=200: rv = %.3f\n", rv))
