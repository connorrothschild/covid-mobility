library(tidyverse)

mobility <- readr::read_csv("../data/mobility/county/county-data-long-averages.csv")
cases <- readr::read_csv('https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv')
states_of_emergencies <- readr::read_csv('../data/policies/covid_us_state_policies.csv')

states_of_emergencies <- states_of_emergencies %>% 
  janitor::clean_names() %>% 
  select(state, state_of_emergency)

joined_soe <- left_join(mobility, states_of_emergencies, by = c('State' = 'state'))

# joined_soe %>% 
#   mutate(state_of_emergency = as.Date(state_of_emergency, format = "%m/%d/%Y")) %>% 
#   mutate(pre = ifelse(date < state_of_emergency, "1", "0"),
#          post = ifelse(date > state_of_emergency, "1", "0"))

with_soes <- joined_soe %>% 
  mutate(state_of_emergency = as.Date(state_of_emergency, format = "%m/%d/%Y")) %>% 
  mutate(state_of_emergency_declared = ifelse(date == state_of_emergency, "1", "0"))

pre_post7 <- with_soes %>% 
  mutate(pre_post7 = ifelse(state_of_emergency - date <= 7 &
                                          date - state_of_emergency < 0, "0", "1"),
         post7 = ifelse(date - state_of_emergency < 7 &
                                            date - state_of_emergency >= 0, "1", "0"))

only_prepost <- pre_post7 %>% 
  filter(pre7 == "1" | post7 == "1")

prepost_column <- only_prepost %>% 
  mutate(pre_post = case_when(pre7 == "1" ~ "Pre",
                              post7 == "1" ~ "Post"))

final <- prepost_column %>% 
  group_by(Region, fips, State, pre_post) %>% 
  summarise(average_mobility = mean(value, na.rm = TRUE)) %>% 
  filter(!is.nan(average_mobility))
# %>% 
#   group_by(pre_post) %>% 
#   summarise(average_mobility = mean(average_mobility, na.rm = TRUE))

write.csv(final, '../data/mobility/county/pre_post_7days.csv')

final %>% 
  ggplot(aes(x = average_mobility)) +
  geom_histogram() +
  facet_wrap(~pre_post)
# +
  # scale_x_continuous(limits = c(-40,40))
