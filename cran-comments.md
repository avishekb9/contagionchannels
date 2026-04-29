## Test environments
* local: Linux Ubuntu 22.04, R 4.1.2
* win-builder (R-devel and R-release)
* GitHub Actions: ubuntu-latest, macos-latest, windows-latest (R-release, R-devel, R-oldrel-1)

## R CMD check results
0 errors | 0 warnings | 1 note

* New submission. The maintainer (Avishek Bhandari) is a first-time CRAN
  contributor for this package; the work continues a programme of
  multi-scale financial-network research at IIT Bhubaneswar.

## Reverse dependencies
None — first release.

## Notes
The package contains daily-return data for 18 G20 equity markets and a
collection of channel-proxy time series compiled from public sources
(Yahoo Finance, FRED, Caldara-Iacoviello GPR data library). All datasets
total approximately 700 KB and are stored in the standard R `.rda` format
under `xz` compression.

Exported functions that use `parallel::mclapply` cap their `n_cores`
default at 2L per CRAN policy; users may raise this for production runs.
On Windows the implementation falls back to single-threaded `lapply`.
