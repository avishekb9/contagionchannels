test_that("build_channel_composites produces five named channels", {
  data(channel_proxies)
  ch <- build_channel_composites(channel_proxies)
  expect_named(ch, c("Date","Trade","Financial","Geopolitical",
                     "Behavioral","Monetary_Policy"))
  expect_equal(nrow(ch), nrow(channel_proxies))
})

test_that("trade composite is genuinely time-varying (non-zero variance)", {
  data(channel_proxies)
  ch <- build_channel_composites(channel_proxies)
  expect_gt(sd(ch$Trade), 0)
})

test_that("behavioural composite is orthogonal to financial composite", {
  data(channel_proxies)
  ch <- build_channel_composites(channel_proxies)
  ok <- is.finite(ch$Behavioral) & is.finite(ch$Financial)
  expect_lt(abs(cor(ch$Behavioral[ok], ch$Financial[ok])), 0.01)
})

test_that("financial composite has unit-scale variance", {
  data(channel_proxies)
  ch <- build_channel_composites(channel_proxies)
  expect_gt(sd(ch$Financial), 0.5)
  expect_lt(sd(ch$Financial), 2)
})
