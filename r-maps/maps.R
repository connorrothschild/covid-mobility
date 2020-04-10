library(tidyverse)

source("theme.R")

theme_set(custom_theme_map())

data <- readr::read_csv("../data/county-data-long.csv")

counties <- map_data("county")

data_for_merge <- data %>% 
  mutate(subregion = paste(stringr::str_to_lower(Region), stringr::str_to_lower(State)))

counties_for_merge <- counties %>% 
  mutate(subregion = paste0(subregion, " county ", region))

merged <- left_join(counties_for_merge, data_for_merge, by = "subregion")

make_plot <- function(category) {
  merged %>%
    filter(date == "2020-03-29",
           Category == category) %>%
    ggplot() +
    geom_polygon(aes(
      fill = value,
      x = long,
      y = lat,
      group = group
    )) +
    tpltheme::scale_fill_continuous(palette = "diverging", limits = c(-100, 100), na.value = "white") +
    coord_map() +
    # theme_void() +    
    theme(
      legend.key.width = unit(.5, "in"),
      panel.border = element_blank(),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.line = element_blank(),
      axis.text.x = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks = element_blank(),
      # panel.background = element_rect(fill = "white"),
      legend.position = "bottom",
      legend.direction = "horizontal"
    ) +
    labs(fill = "% change\n\n",
         title = glue::glue("{category}")
         # subtitle = "For the week of March 29",
         # caption = "Source: Google Community Mobility Reports"
         )
}

p1 <- make_plot("Retail & recreation")
p2 <- make_plot("Transit stations")
p3 <- make_plot("Grocery & pharmacy")
p4 <- make_plot("Parks")
p5 <- make_plot("Workplace")
p6 <- make_plot("Residential")

combined <- ggpubr::ggarrange(p1, p2, p3, p4, p5, p6, ncol = 2, nrow = 3, common.legend = TRUE, legend = "bottom")

ggsave("./outputs/combined-county-plots.jpg", combined, device = "jpg")
ggsave("./outputs/combined-county-plots.svg", combined, device = "svg")

state_data <- readr::read_csv("../data/state-level-data.csv")

state_data_long <- state_data %>% 
  pivot_longer(cols = c("2/16/20":"3/29/20"), names_to = "date") %>% 
  mutate(date = as.Date(date, format = "%m/%d/%y"))

states_fips_for_merge <- map_data("state")

state_data_for_merge <- state_data_long %>% 
  filter(Name != "United States") %>% 
  mutate(region = str_to_lower(Name))

state_data_merged <- left_join(states_fips_for_merge, state_data_for_merge, by = "region")

make_state_plot <- function(category) {
  state_data_merged %>%
    filter(date == "2020-03-29",
           Category == category) %>%
    ggplot() +
    geom_polygon(aes(
      fill = value,
      x = long,
      y = lat,
      group = group
    )) +
    tpltheme::scale_fill_continuous(palette = "diverging", limits = c(-100, 100)) +
    coord_map() +
    # theme_void() +
    theme(
      legend.key.width = unit(.5, "in"),
      panel.border = element_blank(),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.line = element_blank(),
      axis.text.x = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks = element_blank(),
      # panel.background = element_rect(fill = "white"),
      legend.position = "bottom",
      legend.direction = "horizontal"
    ) + 
    labs(fill = "% change\n\n",
         title = glue::glue("{category}"))
         # subtitle = "For the week of March 29",
         # caption = "Source: Google Community Mobility Reports")
}

p1 <- make_state_plot("Retail & recreation")
p2 <- make_state_plot("Transit stations")
p3 <- make_state_plot("Grocery & pharmacy")
p4 <- make_state_plot("Parks")
p5 <- make_state_plot("Workplace")
p6 <- make_state_plot("Residential")

combined <- ggpubr::ggarrange(p1, p2, p3, p4, p5, p6, ncol = 2, nrow = 3, common.legend = TRUE, legend = "bottom")

ggsave("./outputs/combined-state-plots.jpg", combined, device = "jpg")
ggsave("./outputs/combined-state-plots.svg", combined, device = "svg")
