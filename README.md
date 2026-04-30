# contagionchannels

> **Two-Stage Detection and Attribution of Cross-Border Financial Contagion Channels**

[![License: GPL-3](https://img.shields.io/badge/License-GPL%203-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![R-CMD-check](https://img.shields.io/badge/R--CMD--check-passing-brightgreen)](https://github.com/avishekb9/contagionchannels)
[![arXiv](https://img.shields.io/badge/arXiv-2604.26546-b31b1b.svg)](https://arxiv.org/abs/2604.26546)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/)

`contagionchannels` is an R package implementing the two-stage framework for the joint **detection and attribution** of cross-border financial contagion developed in Bhandari, Parida and Sahu (2026), [arXiv:2604.26546](https://arxiv.org/abs/2604.26546). The framework first detects directional information flows between equity markets via Wavelet-Quantile Transfer Entropy and then attributes each significant directional link to one of five mutually exclusive transmission channels — **Trade, Financial, Geopolitical, Behavioural, Monetary Policy** — through a multi-method structural-identification architecture.

## Highlights

- **Stage 1**: Wavelet-Quantile Transfer Entropy (WQTE) over a six-scale MODWT decomposition and three quantile levels, with absolute-thresholding to construct directed contagion networks.
- **Stage 2**: Five complementary identification strategies for channel attribution:
  - Instrumental-variables / Two-Stage Least Squares with channel-specific external instruments — Stock & Watson (2018) `doi:10.1111/ecoj.12593`
  - LASSO instrument selection — Belloni, Chernozhukov & Hansen (2014) `doi:10.1093/restud/rdt044`
  - Local projections at h=1, 5, 22 days — Jordà (2005) `doi:10.1257/0002828053828518`
  - Heteroskedasticity-based identification — Rigobon (2003) `doi:10.1162/003465303772815727`
  - Cinelli-Hazlett (2020) robustness-value sensitivity — `doi:10.1111/rssb.12348`
- **Bundled datasets**: 18 G20 equity markets × 5,036 daily log-returns (Jan 2006 – Mar 2026); 14 channel proxies; 8 crisis sub-period definitions.
- **Three vignettes**: full paper replication; methodology overview; using with custom datasets.

## Installation

From source (the package is not yet on CRAN):

```r
# install.packages("devtools")
devtools::install_local("path/to/contagionchannels", build_vignettes = TRUE)
```

Or directly from the source tarball:

```r
install.packages("contagionchannels_0.1.1.tar.gz", repos = NULL, type = "source")
```

## Quick start

```r
library(contagionchannels)

# Load bundled data
d <- load_paper_data()

# Build the five channel composites
channels <- build_channel_composites(d$proxies)

# Run the full pipeline (Stage 1 detection + Stage 2 attribution)
res <- run_contagion_pipeline(d$returns, channels, d$periods,
                               scale = 5, tau = 0.50, n_cores = 4)

# Per-period channel-attribution shares
res$period_shares
#>            Period Trade Financial Geopolitical Behavioral Monetary  Dominant
#> 1       PreCrisis   8.8      35.9          9.4       13.8     32.1 Financial
#> 2             GFC  27.9      15.0         27.0        2.9     27.2     Trade
#> 3            ESDC  13.7      39.5         19.0       19.6      8.1 Financial
#> 4             CSC  15.9      21.6         15.6       21.7     25.3  Monetary
#> 5        PreCOVID  18.1      31.6          8.2       13.5     28.6 Financial
#> 6           COVID  18.7      18.3         27.5        8.2     27.2 Geopolit.
#> 7          RusUkr  22.6      23.4          6.1       20.3     27.6  Monetary
#> 8 MidEastTariffs   27.6      26.8          7.5        6.3     31.8  Monetary
```

## Key functions

| Function | Purpose |
|---|---|
| `compute_wqte_matrix()` | Stage-1 pairwise Wavelet-Quantile Transfer Entropy |
| `build_channel_composites()` | Construct five channel composites from raw proxies |
| `iv_2sls_attribute()` | Stage-2 IV/2SLS attribution per significant link |
| `lasso_iv_attribute()` | LASSO IV variant per Belloni-Chernozhukov-Hansen |
| `local_projections()` | Jordà 2005 local projections at multiple horizons |
| `rigobon_id()` | Heteroskedasticity-based identification |
| `cinelli_hazlett_rv()` | Robustness-value sensitivity bound |
| `build_network()` | Construct directed contagion network from QTE matrix |
| `walktrap_communities()` | Pons-Latapy community detection |
| `run_contagion_pipeline()` | End-to-end wrapper |

## Bundled datasets

| Object | Description |
|---|---|
| `g20_returns` | xts of daily log-returns: 5,036 days × 18 markets |
| `channel_proxies` | data.frame of 14 channel-proxy time series |
| `crisis_periods` | Named list of 8 crisis sub-period date ranges |

## Vignettes

```r
vignette("replication", package = "contagionchannels")  # Reproduce the paper
vignette("methodology", package = "contagionchannels")  # Methodology overview
vignette("custom_data", package = "contagionchannels")  # Use custom datasets
```

## Replication scripts

The package includes a standalone replication suite at
`system.file("scripts", package = "contagionchannels")`. To reproduce every
numerical result and figure:

```r
master <- system.file("scripts", "99_replicate_paper.R",
                       package = "contagionchannels")
source(master)
```

## Citation

If you use the package in published work, please cite the methodology paper:

> Bhandari, A., Parida, I., & Sahu, H. K. (2026). What Drives Contagion?
> Identifying and Attributing Cross-Border Transmission Mechanisms.
> arXiv preprint [arXiv:2604.26546](https://arxiv.org/abs/2604.26546).

```bibtex
@misc{bhandari2026contagion,
  title         = {What Drives Contagion? Identifying and Attributing
                   Cross-Border Transmission Mechanisms},
  author        = {Bhandari, Avishek and Parida, Ipsita and Sahu, Hitesh Kumar},
  year          = {2026},
  eprint        = {2604.26546},
  archivePrefix = {arXiv},
  primaryClass  = {q-fin.ST},
  url           = {https://arxiv.org/abs/2604.26546}
}

@manual{contagionchannels2026,
  title    = {contagionchannels: Two-Stage Detection and Attribution of
              Cross-Border Financial Contagion Channels},
  author   = {Bhandari, Avishek and Parida, Ipsita and Sahu, Hitesh Kumar},
  year     = {2026},
  note     = {R package version 0.1.1},
  url      = {https://github.com/avishekb9/contagionchannels}
}
```

## License

GPL-3 © Bhandari, Parida & Sahu (2026), Indian Institute of Technology Bhubaneswar.
