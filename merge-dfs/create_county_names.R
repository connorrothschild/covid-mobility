counties <- readr::read_csv("../data/mobility/county/county-data-long-averages.csv")

county_names <- counties %>% 
  mutate(county_state = paste0(Region, ", ", State)) %>% 
  distinct(county_state) 

write.csv(county_names, "../data/mobility/county/county-names.csv")
