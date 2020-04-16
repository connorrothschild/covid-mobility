library(readr)
library(dplyr)
library(tidyr)

# reading mobility data (has both state and county)
path_raw <- '../data/mobility/all-data-raw.csv'
mobility_raw <- read.csv(path_raw,stringsAsFactors = FALSE)

# state data
mobility_state <- mobility_raw %>% filter(admin_level==1)
# converting into percentage change
mobility_state[,6:ncol(mobility_state)] <- mobility_state[
  ,6:ncol(mobility_state)] - 100
write.csv(mobility_state,
          '../data/mobility/state/state-data-wide.csv',
          row.names = FALSE)

# county data
mobility_county <- mobility_raw %>% filter(admin_level==2)
# converting into percent change
mobility_county[,6:ncol(mobility_county)] <- mobility_county[
  ,6:ncol(mobility_county)] - 100
write.csv(mobility_county,
          '../data/mobility/county/county-data-wide.csv',
          row.names = FALSE)

# long data
mobility_county_long <- mobility_county %>% 
  pivot_longer(c("X2020.03.01":"X2020.04.12"), names_to = "date") %>% 
  mutate(date = gsub("X","", date, fixed = TRUE),
         date = gsub(".", "-", date, fixed = TRUE),
         date = lubridate::ymd(date))
# removing NAs
mobility_county_long <- na.omit(mobility_county_long)

### standardizing by day of the week
# day of the week as number (0-6 starting with Sunday)
day_of_week <- (as.numeric(
  mobility_county_long$date-as.Date('2020-03-01')) %% 7)
# converting to character and adding to data frame
mobility_county_long <- mobility_county_long %>% 
  mutate(day_of_week = sapply(day_of_week,function(x){
    c('Su','M','Tu','W','Th','F','Sa')[x+1]
  }))
# adding value standardized by day of the week (across all counties)
mobility_county_long <- merge(mobility_county_long,
                              mobility_county_long %>% 
                                group_by(day_of_week) %>% 
                                summarise(mean=mean(value),sd=sd(value)),
                              by='day_of_week') %>% 
  mutate(value_std=(value-mean)/sd) %>% 
  select(-c(mean,sd)) %>% 
  arrange(fips,date)
write.csv(mobility_county_long,
          '../data/mobility/county/county-data-long.csv',
          row.names = FALSE)