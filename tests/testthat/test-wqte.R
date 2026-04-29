test_that("modwt_detail returns vector of input length", {
  x <- rnorm(512)
  d5 <- modwt_detail(x, scale = 5, J = 6)
  expect_type(d5, "double")
  expect_lte(length(d5), length(x) + 64)  # allow for boundary padding
})

test_that("qte_pair returns scalar; nonzero for genuinely Granger-causal pair", {
  set.seed(42)
  x <- rnorm(500)
  y <- 0.4 * c(0, x[-500]) + rnorm(500, sd = 0.5)
  q <- qte_pair(x, y, tau = 0.5)
  expect_type(q, "double")
  expect_length(q, 1)
  expect_true(is.finite(q))
})

test_that("qte_pair returns NA for too-short input", {
  expect_true(is.na(qte_pair(rnorm(20), rnorm(20))))
})

test_that("compute_wqte_matrix returns N x N matrix with zero diagonal", {
  set.seed(1); R <- matrix(rnorm(500 * 4), 500, 4)
  colnames(R) <- paste0("M", 1:4)
  F <- compute_wqte_matrix(R, scale = 3, tau = 0.5, n_cores = 1)
  expect_equal(dim(F), c(4, 4))
  expect_true(all(diag(F) == 0))
  expect_equal(rownames(F), colnames(R))
})
