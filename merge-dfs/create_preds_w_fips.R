predictions <- readr::read_csv('../regression/predictions.csv')

library(tidycensus)
library(tidyverse)

fips <- fips_codes

fips <- fips %>% 
  mutate(county = paste0(stringr::str_to_title(county), " County"),
         State = stringr::str_to_title(state))

predictions_w_fips <- 
  left_join(fips, predictions, by = "fips") %>% 
  select(fips, county, State, pred)

predictions_w_fips

write.csv(predictions_w_fips, '../data/predictions_w_fips.csv')
