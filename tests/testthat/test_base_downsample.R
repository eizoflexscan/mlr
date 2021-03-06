context("downsample")

test_that("downsample",  {
  down.tsk = downsample(multiclass.task, perc = 1/3)
  expect_equal(getTaskSize(down.tsk), 50L)
  rsm.methods = c("Bootstrap", "Subsample", "Holdout")
  for (rsm.method in rsm.methods) {
    rin = makeResampleInstance(rsm.method, task = binaryclass.task)
    rin2 = downsample(rin, perc = 0.5)
    sapply(seq_along(rin$train.inds), function(i)
      expect_equal(
        length(rin2$train.inds[[i]]),
        length(rin$train.inds[[i]]) / 2
      )
    )
  }
})

test_that("downsample wrapper",  {
  # test it with classif
  rdesc = makeResampleDesc("CV", iters = 2)
  lrn = makeDownsampleWrapper("classif.rpart", dw.perc = 0.5)
  r = resample(lrn, binaryclass.task, rdesc)
  expect_true(!is.na(r$aggr))

  # test it with regr
  rdesc = makeResampleDesc("CV", iters = 2)
  lrn = makeDownsampleWrapper("regr.rpart", dw.perc = 0.5)
  r = resample(lrn, regr.task, rdesc)
  expect_true(!is.na(r$aggr))
})

test_that("downsample wrapper works with xgboost, we had issue #492",  {
  skip_if_not_installed("xgboost") # xgboost broken on CRAN, they cannot run our tests
  rdesc = makeResampleDesc("CV", iters = 2)
  lrn = makeDownsampleWrapper("classif.xgboost", dw.perc = 0.5)
  expect_output(print(lrn), "down")
  r = resample(lrn, binaryclass.task, rdesc)
  expect_true(!is.na(r$aggr))
})

test_that("downsample wrapper works with weights, we had issue #838",  {
  n = nrow(regr.df)
  w = 1:n
  task = makeRegrTask(data = regr.df, target = regr.target, weights = w)

  # weights from task, use all
  lrn = makeDownsampleWrapper("regr.__mlrmocklearners__6", dw.perc = 1)
  m = train(lrn, task)
  expect_set_equal(getLearnerModel(m, more.unwrap = TRUE)$weights, w)

  # weights from task, really downsample
  lrn = makeDownsampleWrapper("regr.__mlrmocklearners__6", dw.perc = 0.5)
  m = train(lrn, task)
  u = getLearnerModel(m, more.unwrap = TRUE)$weights
  expect_true(length(u) == n/2 && all(u %in% w))

  # weights from train
  lrn = makeDownsampleWrapper("regr.__mlrmocklearners__6", dw.perc = 0.5)
  m = train(lrn, task, subset = 1:10, weights = 1:10)
  u = getLearnerModel(m, more.unwrap = TRUE)$weights
  expect_true(length(u) == 5 && all(u %in% 1:10))
})


