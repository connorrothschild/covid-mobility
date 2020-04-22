library(tidyverse)

with_stay_at_home <- readr::read_csv('../viz/data/mobility/county/county-data-long.csv')
without_stay_at_home <- readr::read_csv('../viz/data/mobility/county/predictions_w_fips.csv')

with_latest <- with_stay_at_home %>% 
  filter(date == "2020-03-29")

with_clean <- with_latest %>% 
  select(admin1, admin2, fips, value)

without_clean <- without_stay_at_home %>% 
  select(-X1) %>% 
  mutate(with_without = "without")

with_clean <- with_clean %>% 
  rename('State' = 'admin1',
         'county' = 'admin2',
         'pred' = 'value') %>% 
  mutate(with_without = "with")

with_without_final <- full_join(with_clean, without_clean)

write.csv(with_without_final, '../viz/data/mobility/county/with_without_stayathome.csv')
