# =============================================================================
#  Visualisation helpers. The package functions are designed to be lightweight
#  and to depend only on base graphics; they fall back gracefully if
#  ggplot2 / patchwork are unavailable. For publication-quality figures the
#  user should consult the bundled `inst/scripts/06_visualise.R` file.
# =============================================================================

#' Stacked Bar Plot of Channel-Attribution Shares
#'
#' Draws a stacked bar chart of channel-attribution shares across crisis
#' sub-periods. Returns a ggplot if \pkg{ggplot2} is available, else uses
#' base \code{barplot}.
#'
#' @param period_shares A data.frame with columns \code{Period}, \code{Trade},
#'   \code{Financial}, \code{Geopolitical}, \code{Behavioral}, \code{Monetary}.
#' @param ... Additional arguments passed to \code{ggplot2::ggsave} or to
#'   \code{barplot}.
#' @return A ggplot object (or invisibly the matrix used for base plotting).
#' @examples
#' \donttest{
#' d <- load_paper_data()
#' ch <- build_channel_composites(d$proxies)
#' res <- run_contagion_pipeline(d$returns, ch, d$periods, n_cores = 2)
#' plot_attribution_stack(res$period_shares)
#' }
#' @export
plot_attribution_stack <- function(period_shares, ...) {
  if (requireNamespace("ggplot2", quietly = TRUE) &&
      requireNamespace("tidyr",   quietly = TRUE)) {
    long <- tidyr::pivot_longer(period_shares,
                                cols = c("Trade","Financial","Geopolitical",
                                         "Behavioral","Monetary"),
                                names_to = "Channel", values_to = "Share")
    long$Channel <- factor(long$Channel,
                            levels = c("Trade","Financial","Geopolitical",
                                       "Behavioral","Monetary"))
    long$Period <- factor(long$Period, levels = period_shares$Period)
    ggplot2::ggplot(long, ggplot2::aes(x = Period, y = Share, fill = Channel)) +
      ggplot2::geom_bar(stat = "identity") +
      ggplot2::scale_fill_manual(values = c(Trade = "#1f77b4", Financial = "#d62728",
                                             Geopolitical = "#2ca02c",
                                             Behavioral = "#9467bd",
                                             Monetary = "#ff7f0e")) +
      ggplot2::labs(x = NULL, y = "Attribution share (%)",
                     title = "Channel-attribution shares by sub-period") +
      ggplot2::theme_minimal(base_size = 11) +
      ggplot2::theme(legend.position = "bottom",
                      panel.grid.minor = ggplot2::element_blank(),
                      axis.text.x = ggplot2::element_text(angle = 30, hjust = 1))
  } else {
    M <- t(as.matrix(period_shares[, c("Trade","Financial","Geopolitical",
                                        "Behavioral","Monetary")]))
    colnames(M) <- period_shares$Period
    graphics::barplot(M, las = 2, ylab = "Attribution share (%)",
                      legend.text = TRUE, args.legend = list(x = "topright"), ...)
    invisible(M)
  }
}

#' Two-Panel QTE Intensity Plot
#'
#' Top panel: mean QTE per sub-period. Bottom panel: network density per
#' sub-period.
#' @param stage1_summary A data.frame with columns \code{Period}, \code{MeanQTE},
#'   \code{Density}.
#' @return A patchwork ggplot if available, else a multi-panel base plot.
#' @export
plot_qte_intensity <- function(stage1_summary) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    graphics::par(mfrow = c(2, 1))
    graphics::plot(stage1_summary$MeanQTE, type = "b", xaxt = "n",
                   xlab = "", ylab = "Mean QTE")
    graphics::axis(1, at = seq_along(stage1_summary$Period),
                   labels = stage1_summary$Period, las = 2)
    graphics::barplot(stage1_summary$Density,
                      names.arg = stage1_summary$Period, las = 2,
                      ylab = "Density (%)")
    graphics::par(mfrow = c(1, 1)); return(invisible())
  }
  s1 <- stage1_summary
  s1$Period <- factor(s1$Period, levels = s1$Period)
  base_q <- s1$MeanQTE[1]
  p1 <- ggplot2::ggplot(s1, ggplot2::aes(x = Period, y = MeanQTE, group = 1)) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(size = 3) +
    ggplot2::geom_hline(yintercept = base_q, linetype = "dashed") +
    ggplot2::labs(x = NULL, y = "Mean QTE", title = "Mean QTE by sub-period") +
    ggplot2::theme_minimal(base_size = 11)
  p2 <- ggplot2::ggplot(s1, ggplot2::aes(x = Period, y = Density)) +
    ggplot2::geom_col() +
    ggplot2::labs(x = NULL, y = "Density (%)",
                   title = "Network density (varies under absolute thresholding)") +
    ggplot2::theme_minimal(base_size = 11)
  if (requireNamespace("patchwork", quietly = TRUE)) {
    patchwork::wrap_plots(p1, p2, ncol = 1)
  } else { print(p1); print(p2); invisible(list(p1, p2)) }
}

#' Robustness-Value Heatmap
#'
#' Heatmap of Cinelli-Hazlett robustness values per channel and sub-period.
#'
#' @param rv_matrix Numeric matrix with rownames = periods, colnames =
#'   channels.
#' @return A ggplot object.
#' @export
plot_robustness_value <- function(rv_matrix) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    graphics::image(rv_matrix, axes = FALSE, main = "RV heatmap")
    return(invisible())
  }
  df <- expand.grid(Period = rownames(rv_matrix), Channel = colnames(rv_matrix),
                    stringsAsFactors = FALSE)
  df$RV <- as.vector(rv_matrix)
  ggplot2::ggplot(df, ggplot2::aes(Channel, Period, fill = RV)) +
    ggplot2::geom_tile() +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%.2f", RV)),
                        size = 3) +
    ggplot2::scale_fill_gradient(low = "white", high = "#08306b",
                                  limits = c(0, 0.5)) +
    ggplot2::labs(x = NULL, y = NULL,
                   title = "Cinelli-Hazlett robustness values") +
    ggplot2::theme_minimal(base_size = 11)
}

#' Evolution-of-Shares Line Plot
#'
#' Line plot of channel-attribution share evolution across crisis sub-periods.
#'
#' @param period_shares Per-period share data.frame (output from
#'   \code{\link{run_contagion_pipeline}}).
#' @return A ggplot object.
#' @export
plot_attribution_evolution <- function(period_shares) {
  if (!requireNamespace("ggplot2", quietly = TRUE) ||
      !requireNamespace("tidyr",   quietly = TRUE)) {
    M <- t(as.matrix(period_shares[, c("Trade","Financial","Geopolitical",
                                        "Behavioral","Monetary")]))
    graphics::matplot(t(M), type = "b", xaxt = "n", ylab = "Share (%)")
    return(invisible(M))
  }
  long <- tidyr::pivot_longer(period_shares,
                              cols = c("Trade","Financial","Geopolitical",
                                       "Behavioral","Monetary"),
                              names_to = "Channel", values_to = "Share")
  long$Period <- factor(long$Period, levels = period_shares$Period)
  ggplot2::ggplot(long, ggplot2::aes(x = Period, y = Share, colour = Channel,
                                       group = Channel)) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(size = 2) +
    ggplot2::geom_hline(yintercept = 20, linetype = "dotted") +
    ggplot2::labs(x = NULL, y = "Share (%)",
                   title = "Evolution of channel-attribution shares") +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom",
                    axis.text.x = ggplot2::element_text(angle = 30, hjust = 1))
}
