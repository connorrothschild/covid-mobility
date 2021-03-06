library(tidyverse)

## list filepaths
filenames = list.files(path="./data-for-merge/", full.names=TRUE)

## lapply https://towardsdatascience.com/using-r-to-merge-the-csv-files-in-code-point-open-into-one-massive-file-933b1808106
all <- lapply(filenames, function(i){
  
  ## read in each tsv
  i <- read.table(i,
             header = TRUE,
             sep = "\t",
             fill = TRUE)
  
  ## mutate regions to be character
  i <- i %>%
    mutate(Region = as.character(Region))

  ## grab the state for each grouping. This will be the first row (and the next 5 rows)
  state <- i[[1]][[1]]

  ## append state to be its own column for each grouping
  i <- i %>%
    mutate(State = state) %>%
    select(Region, State, Category, everything())
  
})

## rbind together
merged <- do.call(rbind.data.frame, all)

## bring in FIPS
fips_codes <- maps::county.fips

fips_codes <- fips_codes %>% 
  mutate(state = sapply(strsplit(polyname, ",", fixed = TRUE), `[`, 1),
         county = sapply(strsplit(polyname, ",", fixed = TRUE), `[`, 2),
         combined_for_fips = paste(county, state))

merged_for_fips <- merged %>% 
  mutate(State = stringr::str_replace_all(State, "Haweill", "Hawaii"),
         State = stringr::str_replace_all(State, "inots", "Illinois"),
         State = stringr::str_replace_all(State, "lowa", "Iowa"),
         State = gsub("Rhode |sland", "Rhode Island", State, fixed = TRUE),
         ## louisiana has parishes not counties
         Region = stringr::str_replace_all(Region, "Parish", "County")
  ) %>% 
  mutate(state_for_fips = str_to_lower(State),
         county_for_fips = str_to_lower(Region),
         county_for_fips = str_replace_all(county_for_fips, " county", ""),
         combined_for_fips = paste(county_for_fips, state_for_fips))

# see which counties we missed
# setdiff(merged_for_fips$combined_for_fips, fips_codes$combined_for_fips)

final_merged <- left_join(merged_for_fips, fips_codes, by = "combined_for_fips")

## convert FIPS codes into characters, add trailing zero
final_merged <- final_merged %>% 
  mutate(fips = as.character(fips),
         fips = stringr::str_pad(fips, 5, pad = "0", side = "left")) %>%
  select(Region, State, fips, Category, everything())

  # filter out the state level 
final_merged <- final_merged %>% 
  filter(Region != State) %>% 
  select(-c(state_for_fips:county))

county_data_wide <- final_merged

county_data_long <- final_merged %>% 
  pivot_longer(c("X2020.02.16":"X2020.03.29"), names_to = "date") %>% 
  mutate(date = gsub("X","", date, fixed = TRUE),
         date = gsub(".", "-", date, fixed = TRUE),
         date = lubridate::ymd(date))

## write
write.csv(county_data_wide, "../data/mobility/county/county-data-wide.csv")
write.csv(county_data_long, "../data/mobility/county/county-data-long.csv")

# ## average of all six categories 
# county_data_long_grouped <- county_data_long %>% 
#   group_by(Region, fips, date) %>% 
#   summarise(value = mean(value, na.rm = TRUE))
# 
# write.csv(county_data_long_grouped, "../data/mobility/county/county-data-long-averages.csv")

## clean!
source('Mobility_cleaning.R')
