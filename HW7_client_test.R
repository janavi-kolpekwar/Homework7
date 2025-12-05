library(httr)
library(jsonlite)
library(readr)
library(dplyr)
library(lubridate)

test <- read_csv("test_dataset.csv.gz")

sample <- test[1:3, ]  # send 3 rows
sample_json <- toJSON(sample, dataframe = "rows")

res_prob <- POST(
  url = "http://127.0.0.1:8000/predict_prob",
  body = sample_json,
  encode = "json"
)

prob_result <- fromJSON(content(res_prob, as = "text"))
print("Predicted probabilities:")
print(prob_result)

res_class <- POST(
  url = "http://127.0.0.1:8000/predict_class",
  body = sample_json,
  encode = "json"
)

class_result <- fromJSON(content(res_class, as = "text"))
print("Predicted classes:")
print(class_result)
