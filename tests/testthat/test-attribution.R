test_that("cinelli_hazlett_rv lies in [0,1]", {
  rv <- cinelli_hazlett_rv(theta = 0.4, se = 0.1, df = 200)
  expect_true(rv >= 0 && rv <= 1)
})

test_that("cinelli_hazlett_rv is monotone in |theta|/se", {
  rv1 <- cinelli_hazlett_rv(theta = 0.1, se = 0.1, df = 200)
  rv2 <- cinelli_hazlett_rv(theta = 1.0, se = 0.1, df = 200)
  expect_gt(rv2, rv1)
})

test_that("cinelli_hazlett_rv handles invalid input", {
  expect_true(is.na(cinelli_hazlett_rv(NA, 0.1, 200)))
  expect_true(is.na(cinelli_hazlett_rv(0.4, 0, 200)))
})

test_that("iv_2sls_attribute returns NULL for too-short input", {
  set.seed(1)
  C_ij <- rnorm(50)
  ch <- data.frame(Date = 1:50,
                   Trade = rnorm(50), Financial = rnorm(50),
                   Geopolitical = rnorm(50), Behavioral = rnorm(50),
                   Monetary_Policy = rnorm(50))
  R_full <- matrix(rnorm(50 * 4), 50, 4)
  out <- iv_2sls_attribute(C_ij, ch, R_full)
  expect_null(out)
})

test_that("local_projections returns list with horizon names", {
  set.seed(1); n <- 200
  C_ij <- rnorm(n)
  ch <- data.frame(Date = seq_len(n),
                   Trade = rnorm(n), Financial = rnorm(n),
                   Geopolitical = rnorm(n), Behavioral = rnorm(n),
                   Monetary_Policy = rnorm(n))
  R_full <- matrix(rnorm(n * 5), n, 5)
  lp <- local_projections(C_ij, ch, R_full, horizons = c(1, 5))
  expect_named(lp, c("h1","h5"))
  expect_length(lp$h1, 5)
})
