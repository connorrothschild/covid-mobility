library(tidyverse)

## using new dataset https://github.com/nacnudus/google-location-coronavirus

all_data <- readr::read_tsv("https://raw.githubusercontent.com/nacnudus/google-location-coronavirus/master/2020-04-05-region.tsv", )

counties <- all_data %>% 
  filter(!is.na(sub_region_name) & country_code == "US")

## bring in FIPS
fips_codes <- maps::county.fips

fips_codes <- fips_codes %>% 
  mutate(state = sapply(strsplit(polyname, ",", fixed = TRUE), `[`, 1),
         county = sapply(strsplit(polyname, ",", fixed = TRUE), `[`, 2),
         combined_for_fips = paste(county, state))

merged_for_fips <- counties %>% 
  mutate(sub_region_name = stringr::str_replace_all(sub_region_name, "Parish", "County"),
         state_for_fips = str_to_lower(region_name),
         county_for_fips = str_to_lower(sub_region_name),
         county_for_fips = str_replace_all(county_for_fips, " county", ""),
         combined_for_fips = paste(county_for_fips, state_for_fips))

setdiff(merged_for_fips$combined_for_fips, fips_codes$combined_for_fips)

## merge

final_merged <- left_join(merged_for_fips, fips_codes, by = "combined_for_fips")

## convert FIPS codes into characters, add trailing zero
final_merged0405 <- final_merged %>% 
  mutate(fips = as.character(fips),
         fips = stringr::str_pad(fips, 5, pad = "0", side = "left")) %>%
  select(region_name, sub_region_name, fips, category, fips, everything()) %>% 
  select(-c(url:group), -c(state_for_fips:county))

write.csv(final_merged0405, "../data/data-040520.csv")

## average of all six categories 
final_merged0405_averages <- final_merged0405 %>% 
  group_by(sub_region_name, fips, region_name, date) %>% 
  summarise(value = mean(trend, na.rm = TRUE))

write.csv(final_merged0405_averages, "../data/final_merged0405_averages.csv")
