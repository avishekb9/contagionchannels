## Resubmission

This is a resubmission of contagionchannels 0.1.1, addressing the
feedback received from Uwe Ligges on the 0.1.0 pre-test:

> Please omit "+ file LICENSE" and the file itself which looks like a
> template for the MIT license. For GPL-3 it is only used to specify
> additional restrictions to the GPL such as attribution requirements.

Changes in 0.1.1:

* `License:` field changed from `GPL-3 + file LICENSE` to plain `GPL-3`.
* The auxiliary `LICENSE` file has been removed.
* The methodology preprint (Bhandari, Parida & Sahu 2026,
  arXiv:2604.26546) is now referenced in DESCRIPTION, inst/CITATION,
  and README.

## Test environments
* local: Linux Ubuntu 22.04, R 4.1.2
* win-builder (R-devel and R-release)
* GitHub Actions: ubuntu-latest, macos-latest, windows-latest
  (R-release, R-devel, R-oldrel-1)

## R CMD check results
0 errors | 0 warnings | 1 note

* The single NOTE flags the package as a new submission and lists
  proper-name spellings in DESCRIPTION (Belloni, Bhandari, Chernozhukov,
  Cinelli, Hazlett, Jorda, Oka, Parida, Rigobon, Sahu, Schreiber, Whang)
  plus the canonical econometrics term "heteroskedasticity"; all are
  intentional.

## Reverse dependencies
None -- first release.

## Notes
The package contains daily-return data for 18 G20 equity markets and a
collection of channel-proxy time series compiled from public sources
(Yahoo Finance, FRED, Caldara-Iacoviello GPR data library). All datasets
total approximately 700 KB and are stored in the standard R `.rda`
format under `xz` compression.

Exported functions that use `parallel::mclapply` cap their `n_cores`
default at 2L per CRAN policy; users may raise this for production
runs. On Windows the implementation falls back to single-threaded
`lapply`.
