test_that("build_network produces directed weighted igraph", {
  set.seed(1); m <- matrix(runif(25, 0, 0.1), 5, 5); diag(m) <- 0
  g <- build_network(m, threshold = 0.05)
  expect_s3_class(g, "igraph")
  expect_true(igraph::is_directed(g))
  expect_true("weight" %in% igraph::edge_attr_names(g))
})

test_that("network_summary returns expected fields", {
  set.seed(1); m <- matrix(runif(25, 0, 0.1), 5, 5); diag(m) <- 0
  g <- build_network(m, threshold = 0.05)
  s <- network_summary(g)
  expect_named(s, c("n_edges","density","in_degree","out_degree",
                    "betweenness","eigenvector"))
  expect_true(s$density >= 0 && s$density <= 1)
  expect_length(s$in_degree, igraph::vcount(g))
})

test_that("walktrap_communities returns vector or NULL", {
  set.seed(1); m <- matrix(runif(100, 0, 0.5), 10, 10); diag(m) <- 0
  g <- build_network(m, threshold = 0.1)
  w <- walktrap_communities(g)
  expect_true(is.null(w) || length(w) == igraph::vcount(g))
})
