library(plumber)
library(readr)
library(dplyr)
library(lubridate)
library(caret)

train <- read_csv("train_dataset.csv.gz")
test  <- read_csv("test_dataset.csv.gz")
factor_cols <- c("provider_id", "address", "specialty")

for (col in factor_cols) {
  combined_levels <- union(unique(train[[col]]), unique(test[[col]]))
  train[[col]] <- factor(train[[col]], levels = combined_levels)
  test[[col]]  <- factor(test[[col]],  levels = combined_levels)
}


train$no_show <- factor(train$no_show, levels = c(0, 1), labels = c("Show", "NoShow"))
train <- train %>%
  mutate(days_between = as.numeric(difftime(appt_time, appt_made, units = "days")))

set.seed(123)
model <- train(
  no_show ~ provider_id + address + specialty + days_between,
  data = train,
  method = "glm",
  trControl = trainControl(method = "cv", number = 5, classProbs = TRUE)
)

prepare_newdata <- function(df) {
  df$provider_id <- factor(df$provider_id, levels = levels(train$provider_id))
  df$address     <- factor(df$address,     levels = levels(train$address))
  df$specialty   <- factor(df$specialty,   levels = levels(train$specialty))
  df$days_between <- as.numeric(difftime(df$appt_time, df$appt_made, units = "days"))
  
  return(df)
}


#* @apiTitle No-Show Prediction API
#* Predict probability of no-show (0–1)
#* @post /predict_prob
function(req, res) {
  df <- jsonlite::fromJSON(req$postBody)
  df <- prepare_newdata(df)
  probs <- predict(model, newdata = df, type = "prob")[, "NoShow"]
  return(probs)
}

#* Predict class (0 = Show, 1 = NoShow)
#* @post /predict_class
function(req, res) {
  df <- jsonlite::fromJSON(req$postBody)
  df <- prepare_newdata(df)
  probs <- predict(model, newdata = df, type = "prob")[, "NoShow"]
  class <- ifelse(probs > 0.5, 1, 0)
  return(class)
}

