suppressMessages({
library(data.table)
library(ROCR)
library(catboost)
})

set.seed(123)

d_train <- fread("train.csv", showProgress=FALSE, stringsAsFactors=TRUE)
d_test <- fread("test.csv", showProgress=FALSE, stringsAsFactors=FALSE)   ## to match factors in train and test with bind

d_train_test <- rbind(d_train, d_test)
p <- ncol(d_train_test)-1

d_train_test$dep_delayed_15min <- ifelse(d_train_test$dep_delayed_15min=="Y",1,0)   ## need numeric y

d_train <- d_train_test[(1:nrow(d_train)),]
d_test <-  d_train_test[(nrow(d_train)+1):(nrow(d_train)+nrow(d_test)),]


dx_train <- catboost.load_pool(d_train[,1:p], label = d_train$dep_delayed_15min)
dx_test  <- catboost.load_pool(d_test[,1:p])


params <- list(iterations = 100, depth = 10, learning_rate = 0.1,
   task_type = "GPU",
   verbose = 0)
cat(system.time({
  md <- catboost.train(learn_pool = dx_train, test_pool = NULL, params = params)
})[[3]]," ",sep="")


phat <- catboost.predict(md, dx_test)
rocr_pred <- prediction(phat, d_test$dep_delayed_15min)
cat(performance(rocr_pred, "auc")@y.values[[1]],"\n")

