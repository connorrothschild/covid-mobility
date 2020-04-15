library(tidyverse)
library(zoo)

data <- readr::read_csv("https://raw.githubusercontent.com/jataware/covid-19-data/master/County-NPIs.csv")

data <- data %>% 
  mutate(date = as.Date(publish_date, origin = "1900-01-01"))

data <- data %>% 
  filter(category == "state_of_emergency") %>% 
  select(-c(publish_date, category))

write.csv(data, '../data/interventions/state_of_emergency_data.csv')
