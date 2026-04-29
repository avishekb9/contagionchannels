test_that("zscore returns mean 0 sd 1", {
  set.seed(1); x <- rnorm(100, mean = 5, sd = 3)
  z <- zscore(x)
  expect_equal(mean(z), 0, tolerance = 1e-8)
  expect_equal(sd(z), 1, tolerance = 1e-8)
})

test_that("zscore handles zero-variance input", {
  z <- zscore(rep(2, 10))
  expect_true(all(z == 0))
})

test_that("build_lag inserts NAs at the start", {
  out <- build_lag(1:10, 3)
  expect_equal(length(out), 10)
  expect_true(all(is.na(out[1:3])))
  expect_equal(out[4:10], 1:7)
})

test_that("orthogonalise_residual produces orthogonal residuals", {
  set.seed(1); a <- rnorm(200); b <- 0.5 * a + rnorm(200)
  r <- orthogonalise_residual(b, a)
  expect_equal(cor(a, r, use = "complete.obs"), 0, tolerance = 1e-6)
})
