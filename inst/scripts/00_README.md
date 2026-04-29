# Replication Scripts — contagionchannels package

This directory contains the scripts that reproduce every numerical result
and figure reported in the headline paper. The scripts are designed to run
in numerical order, with each producing intermediate outputs consumed by
later scripts.

## Quick start

```r
# Install the package and set the working directory to the inst/scripts/ folder
library(contagionchannels)

# Master script that runs everything end-to-end
source("99_replicate_paper.R")

# Or run scripts individually:
source("01_load_data.R")
source("02_stage1_wqte.R")
source("03_stage2_attribution.R")
source("04_lasso_iv.R")
source("05_local_projections.R")
source("06_rigobon.R")
source("07_robustness.R")
source("08_visualise.R")
```

## Script-by-script overview

| Script | Purpose | Output | Approx wall time |
|---|---|---|---|
| `01_load_data.R` | Load the bundled datasets | none | <1s |
| `02_stage1_wqte.R` | Stage-1 WQTE detection on 8 sub-periods | `stage1.rds` | 3-5 min on 8 cores |
| `03_stage2_attribution.R` | Stage-2 IV/2SLS per significant link | `stage2.rds` | 5-10 min on 8 cores |
| `04_lasso_iv.R` | LASSO IV cross-validation (BCH 2014) | `lasso_iv.rds` | 10-15 min on 8 cores |
| `05_local_projections.R` | Jordà 2005 LP at h=1,5,22 | `lp.rds` | 5-10 min on 8 cores |
| `06_rigobon.R` | Rigobon 2003 heteroskedasticity ID | `rigobon.rds` | 1-2 min |
| `07_robustness.R` | Cinelli-Hazlett RV, bootstrap CIs | `robustness.rds` | 2-3 min |
| `08_visualise.R` | Generate all 7 figures | PDFs | 30 s |
| `99_replicate_paper.R` | Master script that runs all of the above | all of above | 30-45 min |

## Output directory

By default the scripts write to `tempdir()`; set the `OUT_DIR` environment
variable to redirect:

```bash
OUT_DIR=/path/to/results Rscript 99_replicate_paper.R
```

## Dependencies

Beyond the package's `Imports`, the LASSO IV script (`04_lasso_iv.R`) requires
the optional `hdm` package:

```r
install.packages("hdm")
```

The visualisation script (`08_visualise.R`) requires `ggplot2`, `dplyr`,
`tidyr`, `patchwork`, `RColorBrewer`, `viridis`, and `scales`:

```r
install.packages(c("ggplot2","dplyr","tidyr","patchwork",
                   "RColorBrewer","viridis","scales"))
```

## Data provenance

The bundled datasets (`g20_returns`, `channel_proxies`, `crisis_periods`)
are constructed from raw XLSX files at `inst/extdata/G20.xlsx` and
`inst/extdata/channel_proxies.xlsx`. The build script is at
`data-raw/DATASET.R`; rerun it via `Rscript data-raw/DATASET.R` from the
package root.
