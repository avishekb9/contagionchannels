#' Construct a Directed Contagion Network from a WQTE Flow Matrix
#'
#' Builds a directed weighted network from a pairwise WQTE flow matrix by
#' retaining only the edges whose intensity exceeds the supplied threshold.
#' The network construction follows the standard contagion-network
#' literature (Diebold and Yilmaz, 2014; Billio et al., 2012).
#'
#' @param F_matrix An \eqn{N \times N} numeric matrix of WQTE values.
#' @param threshold Numeric threshold for edge retention; edges with
#'   \code{F_matrix[i,j] > threshold} are retained.
#' @return An igraph object with \code{weight} edge attribute equal to the
#'   WQTE value.
#' @examples
#' m <- matrix(runif(25, 0, 0.1), 5, 5); diag(m) <- 0
#' g <- build_network(m, threshold = 0.05)
#' igraph::ecount(g)
#' @export
build_network <- function(F_matrix, threshold) {
  adj <- F_matrix * (F_matrix > threshold); diag(adj) <- 0
  igraph::graph_from_adjacency_matrix(adj, mode = "directed", weighted = TRUE)
}

#' Summary Statistics of a Contagion Network
#'
#' Returns a list of standard centrality and density statistics for a
#' directed contagion network.
#'
#' @param g An igraph object.
#' @return A list with elements \code{n_edges}, \code{density},
#'   \code{in_degree}, \code{out_degree}, \code{betweenness}, and
#'   \code{eigenvector}.
#' @examples
#' m <- matrix(runif(25, 0, 0.1), 5, 5); diag(m) <- 0
#' g <- build_network(m, threshold = 0.05)
#' network_summary(g)$density
#' @export
network_summary <- function(g) {
  n <- igraph::vcount(g)
  list(
    n_edges    = igraph::ecount(g),
    density    = if (n > 1) igraph::ecount(g) / (n * (n - 1)) else 0,
    in_degree  = igraph::degree(g, mode = "in"),
    out_degree = igraph::degree(g, mode = "out"),
    betweenness = igraph::betweenness(g, directed = TRUE),
    eigenvector = tryCatch(
      igraph::eigen_centrality(igraph::as_undirected(g, mode = "collapse"),
                                weights = igraph::E(g)$weight)$vector,
      error = function(e) rep(NA_real_, n))
  )
}

#' Walktrap Community Detection on a Contagion Network
#'
#' Detects communities using the Walktrap algorithm of Pons and Latapy
#' (2006) on the symmetrised version of the directed contagion network.
#'
#' @param g An igraph object.
#' @return An integer vector of community memberships, one per vertex; or
#'   \code{NULL} if the network has too few edges.
#' @examples
#' m <- matrix(runif(25, 0, 0.1), 5, 5); diag(m) <- 0
#' g <- build_network(m, threshold = 0.02)
#' walktrap_communities(g)
#' @export
walktrap_communities <- function(g) {
  if (igraph::ecount(g) < 5) return(NULL)
  gu <- igraph::as_undirected(g, mode = "collapse")
  wc <- tryCatch(igraph::cluster_walktrap(gu), error = function(e) NULL)
  if (is.null(wc)) return(NULL)
  igraph::membership(wc)
}
