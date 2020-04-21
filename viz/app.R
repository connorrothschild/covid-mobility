## app.R ##
library(shinydashboard)
library(highcharter)
library(flexdashboard)
library(ggplot2)
library(knitr)
library(kableExtra)
library(dplyr)
library(tidyr)
library(data.table)
library(shiny)
library(DT)
library(ggrepel)
library(shinycssloaders)
library(shinythemes)
library(SwimmeR)
library(plotly)
library(r2d3)


thm <-
  hc_theme(
    colors = c("#1a6ecc", "#434348", "#90ed7d"),
    chart = list(
      backgroundColor = "transparent",
      style = list(fontFamily = "Source Sans Pro")
    ),
    xAxis = list(gridLineWidth = 1)
  )

source('theme.R')
theme_set(custom_theme_print())

# load ACS data
ACS_econ <-
  read.csv("data/demographics/ACS_ECONOMIC_2018.csv",
           stringsAsFactors = FALSE)
ACS_social <-
  read.csv("data/demographics/ACS_SOCIAL_2018.csv",
           stringsAsFactors = FALSE)

# rename GEO_ID to FIPS
names(ACS_econ)[1] <- "FIPS1"
names(ACS_social)[1] <- "FIPS2"

# extract abbreviated FIPS code
ACS_econ$FIPS1 = substr(ACS_econ$FIPS, 10, 14)
ACS_social$FIPS2 = substr(ACS_social$FIPS, 10, 14)

ACS_econ <- ACS_econ[-1, ]
ACS_social <- ACS_social[-1, ]

ACS_social_sub <-
  ACS_social[, c(
    "FIPS2",
    "DP05_0037PE",
    "DP05_0038PE",
    "DP05_0039PE",
    "DP05_0044PE",
    "DP05_0052PE",
    "DP05_0057PE",
    "DP05_0071PE",
    "DP05_0002PE",
    "DP05_0003PE"
  )]
ACS_econ_sub <-
  ACS_econ[, c(
    "FIPS1",
    "DP03_0002PE",
    "DP03_0009PE",
    "DP03_0025E",
    "DP03_0027PE",
    "DP03_0028PE",
    "DP03_0029PE",
    "DP03_0030E",
    "DP03_0031PE",
    "DP03_0062E",
    "DP03_0063E"
  )]

ACS_social_sub[, 2:10] <- as.numeric(unlist(ACS_social_sub[, 2:10]))
ACS_econ_sub <- na.omit(ACS_econ_sub)

ACS_econ_sub[, 2:11] <- as.numeric(unlist(ACS_econ_sub[, 2:11]))
ACS_econ_sub <- na.omit(ACS_econ_sub)


# laod SVI CDC data
SVI_dat <- read.csv("data/demographics/SVI2018_US_COUNTY.csv")

# select relevant columns from SVI data
SVI_sub <-
  SVI_dat[, c(
    "FIPS",
    "STATE",
    "ST_ABBR",
    "COUNTY",
    "E_TOTPOP",
    "EP_POV",
    "EP_UNEMP",
    "EP_PCI",
    "EP_AGE65",
    "EP_MINRTY",
    "EP_MUNIT"
  )]


# load mobility data
mobility <-
  read.csv("data/archived/county-data-wide-cleaned.csv")
mobility <- na.omit(mobility)

mobility$net_mob <-
  (
    mobility$X2020.03.22 + mobility$X2020.03.23 + mobility$X2020.03.24 + mobility$X2020.03.25 + mobility$X2020.03.26 + mobility$X2020.03.27 + mobility$X2020.03.28 + mobility$X2020.03.29
  ) / 8

# Aggregate all mobility for each county (average over categories to get net mobility)
mobility_agg <- mobility %>%
  select(-one_of("X", "Region", "Category", "State")) %>%
  group_by(fips) %>%
  summarise_all(funs(mean))

# clean up to get each county by fips
mobility_agg <- unique(mobility_agg)
names(mobility_agg)[1] <- "County_FIPS"


mobility_work <-
  cbind("FIPS3" = mobility$fips[mobility$Category == "Workplace"],
        "net_work_mob" = mobility$net_mob[mobility$Category == "Workplace"])
mobility_residential <-
  cbind("FIPS4" = mobility$fips[mobility$Category == "Residential"], "net_res_mob" =
          mobility$net_mob[mobility$Category == "Residential"])
mobility_retaill <-
  cbind("FIPS5" = mobility$fips[mobility$Category == "Retail & recreation"],
        "net_retail_mob" = mobility$net_mob[mobility$Category == "Retail & recreation"])
mobility_grocery <-
  cbind("FIPS6" = mobility$fips[mobility$Category == "Grocery & pharmacy"],
        "net_grocery_mob" = mobility$net_mob[mobility$Category == "Grocery & pharmacy"])
mobility_transit <-
  cbind("FIPS7" = mobility$fips[mobility$Category == "Transit stations"],
        "net_transit_mob" = mobility$net_mob[mobility$Category == "Transit stations"])
mobility_parks <-
  cbind("FIPS8" = mobility$fips[mobility$Category == "Parks"],
        "net_parks_mob" = mobility$net_mob[mobility$Category == "Parks"])


# join SVI, ACS, and mobility into one frame
full_dat <-
  merge(mobility_agg, SVI_sub, by.x = "County_FIPS", by.y = "FIPS")
full_dat <-
  merge(
    full_dat,
    ACS_social_sub,
    by.x = "County_FIPS",
    by.y = "FIPS2",
    all.x = TRUE
  )
full_dat <-
  merge(
    full_dat,
    ACS_econ_sub,
    by.x = "County_FIPS",
    by.y = "FIPS1",
    all.x = TRUE
  )
full_dat <-
  merge(
    full_dat,
    mobility_work,
    by.x = "County_FIPS",
    by.y = "FIPS3",
    all.x = TRUE
  )
full_dat <-
  merge(
    full_dat,
    mobility_residential,
    by.x = "County_FIPS",
    by.y = "FIPS4",
    all.x = TRUE
  )
full_dat <-
  merge(
    full_dat,
    mobility_retaill,
    by.x = "County_FIPS",
    by.y = "FIPS5",
    all.x = TRUE
  )
full_dat <-
  merge(
    full_dat,
    mobility_grocery,
    by.x = "County_FIPS",
    by.y = "FIPS6",
    all.x = TRUE
  )
full_dat <-
  merge(
    full_dat,
    mobility_transit,
    by.x = "County_FIPS",
    by.y = "FIPS7",
    all.x = TRUE
  )
full_dat <-
  merge(
    full_dat,
    mobility_parks,
    by.x = "County_FIPS",
    by.y = "FIPS8",
    all.x = TRUE
  )


# get average change in mobility for last week in data
full_dat$net_mob <-
  (
    full_dat$X2020.03.22 + full_dat$X2020.03.23 + full_dat$X2020.03.24 + full_dat$X2020.03.25 + full_dat$X2020.03.26 + full_dat$X2020.03.27 + full_dat$X2020.03.28 + full_dat$X2020.03.29
  ) / 8

# Remove bad data
full_dat <- full_dat[full_dat$EP_POV > 0,]


# Demographic columns to plot
DEMOGRAPHIC_VALUES <-
  c(
    "Median Household Income ($)",
    "Mean Commute Time (min)",
    "% Service Jobs",
    "% Sales/Office Jobs",
    "% Production/Transport Jobs",
    "% Below Poverty",
    "% Asian",
    "% White",
    "% African-American",
    "% Hispanic/Latino",
    "% Minority"
  )

############ STATE MOBILITY DATA

# Aggregate all columns in c by weighted average, using E_TOTPOP as the weights
state_mobility <- data.table(full_dat, key = "STATE")
for (n in colnames(full_dat)[!colnames(full_dat) %in% c("STATE", "E_TOTPOP", "County_FIPS")]) {
  state_mobility[,
                 (n) := weighted.mean(get(n), E_TOTPOP),
                 #with = FALSE,
                 by = STATE]
}
# Remove uninteresting columns
state_mobility <-
  state_mobility %>% select(-contains("DP")) %>% select(-contains("EP"))
state_mobility <-
  subset(state_mobility,
         select = -c(County_FIPS, E_TOTPOP, net_mob, net_work_mob, ST_ABBR))
# Remove duplicate rows
state_mobility <- as.data.frame(state_mobility) %>% distinct()
# Wide form to long form
state_mobility <-
  gather(state_mobility,
         date,
         mobility,
         X2020.02.17:X2020.03.29,
         factor_key = FALSE)
state_mobility$date <-
  as.Date(state_mobility$date, format = 'X%Y.%m.%d')

######## STATE POLICY DATA

state_policies <-
  read.csv("data/policies/covid_us_state_policies.csv")
colnames(state_policies) <- toupper(colnames(state_policies))
state_policies$STATE <- toupper(state_policies$STATE)
state_policies$STATE.OF.EMERGENCY <-
  as.Date(state_policies$STATE.OF.EMERGENCY, format = '%m/%d/%Y')
state_policies$STAY.AT.HOME..SHELTER.IN.PLACE <-
  as.Date(state_policies$STAY.AT.HOME..SHELTER.IN.PLACE, format = '%m/%d/%Y')
state_policies$CLOSED.NON.ESSENTIAL.BUSINESSES <-
  as.Date(state_policies$CLOSED.NON.ESSENTIAL.BUSINESSES, format = '%m/%d/%Y')
state_policies[state_policies == 0] <- NA

ALL_STATES <- unique(state_mobility$STATE)

####### CASES + MOBILITY
county_cases <- read.csv("data/cases/us-counties-cases.csv")
state_cases <- read.csv("data/cases/us-states-cases.csv")
state_cases$date <- as.Date(state_cases$date)
state_cases$state <- toupper(state_cases$state)
names(state_cases)[2] <- toupper(names(state_cases)[2])
state_cases <- state_cases[order(state_cases$STATE, state_cases$date), ]

state_cases$date <- as.character(state_cases$date)
state_mobility$date <- as.character(state_mobility$date)

case_mobility <- merge(state_cases, state_mobility, by=c('date','STATE'))
case_mobility$date <- as.Date(case_mobility$date)
case_mobility <- case_mobility[order(case_mobility$STATE, case_mobility$date), ]
state_cases$date <- as.Date(state_cases$date)
state_mobility$date <- as.Date(state_mobility$date)


###### SHINY DASHBOARD UI
ui <- fluidPage(
  #CSS 
  
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
  ),
  
  #Navbar structure for UI
  navbarPage(
    "Mobility and Predictors of Movement During COVID-19",
    theme = shinytheme("lumen"),
    tabPanel(
        "Introduction", 
        fluid = TRUE,
        icon = icon("hand-paper-o"),
          fluidRow(column(width = 6,
            h1("Mobility and Movement During COVID-19"),
            h4("By Connor Rothschild, Kyran Adams, Rebecca Francis, and Mario Paciuc"),
            p("The Coronavirus has changed the way we move. Public health officials and lawmakers have urged or, in some states, mandated citizens to ‘social distance,’ self-quarantine, and stay home."),
            p("Despite the popularity of such recommendations, we know little about the effectiveness of stay-at-home orders and similar laws. Although, as of this writing,", 
            tags$a(href = 'https://www.businessinsider.com/us-map-stay-at-home-orders-lockdowns-2020-3', target = '_blank', '95% of citizens are under stay-at-home orders'), 
            "researchers have not yet done a rigorous analysis to explore if such orders are effective at reducing travel."),
            p('Moreover, the effectiveness of such ordinances may be inconsistent across different communities. Many in popular media have made the claim that ',
            tags$a(href = 'https://www.nytimes.com/2020/04/05/opinion/coronavirus-social-distancing.html', target = '_blank', 'social distancing is a privilege.'), 
            'Stay-at-home orders may generally reduce travel, but not for individuals who are deemed essential workers or live in a food desert.'),
            br(),
            p('The present dashboard is a rigorous exploration of ',
              tags$ol(
                tags$li("How mobility and movement has changed during the era of COVID-19,"), 
                tags$li("How effective various public policies have been at meaningfully reducing travel, and"), 
                tags$li("What factors make a community more or less likely to abide by travel-limiting regulations.")
              )
              ),
            h4('Explore each of these questions by visiting the tabs on the top of the screen (in order of appearance).'),
            # actionButton("link_to_start_presentation", "Let's Begin!")
          ),
                column(width = 6,
                       tags$div(tags$img(src = 'https://raw.githubusercontent.com/connorrothschild/covid-mobility/master/README-files/low-qual-final-states.jpg',
                                height = 650, width = 650), style = "display: flex; align-items: center; justify-content: center;"
                       )
                )
          )
    ),
    
    tabPanel(
      # h1("See the changes in mobility over time"),
      fluid = TRUE,
      icon = icon("globe-americas"),
      # titlePanel("How does your county compare?"),
      title = "Changes in mobility",
      fluidRow(
        tags$iframe(
          seamless = NA,
          src = "https://connorrothschild.github.io/covid-mobility/viz/",
          height = 800,
          width = 1400
        )
      )
    ),
    
    tabPanel(
      "How does your county compare?",
      fluid = TRUE,
      icon = icon("map"),
      # titlePanel("How does your county compare?"),
      fluidRow(
        tags$iframe(
          seamless = NA,
          src = "https://connorrothschild.github.io/covid-mobility/viz/line-chart",
          height = 800,
          width = 1400
        )
      )
    ),
    
    tabPanel(
      "Cases and Mobility",
      fluid = TRUE,
      icon = icon("shoe-prints"),
      h2("We know from our research that as the number of cases increases, community members begin to travel less."),
      h3("You can explore how this relationship has unfolded in your state here:"),
      br(),
      sidebarLayout(
        sidebarPanel(
          fluidRow(
            selectInput(
              inputId = "CaseStateSelector",
              label = "Select State",
              choices = stringr::str_to_title(levels(ALL_STATES)),
              selected = "Texas",
              width = "220px"
            ),
          )
        ),
        mainPanel(
          fluidRow(withSpinner(
            plotlyOutput(outputId = "case_mobility")
          ))
        )
      )
    ),
    
    tabPanel(
      "Demographics and Mobility",
      fluid = TRUE,
      icon = icon("address-book"),
      h3("But regardless of increasing caseloads, are there certain factors which limit a population’s ability to ‘social distance’?"),
      h4("Use this tab to explore the relationship between a host of demographic variables and changes in mobility. You can also filter your display to focus on one of six categories to see how the trends change between different domains."),
      h4("The correlation table below the chart will allow you to determine whether the relationship you see visually is statistically significant."),
      # Sidebar layout with a input and output definitions
      sidebarLayout(
        sidebarPanel(
          # titlePanel("Demographic Characteristics"),
          fluidRow(
            selectInput(
              inputId = "DemographicsSelector",
              label = "Select Demographic Value",
              choices = DEMOGRAPHIC_VALUES,
              selected = DEMOGRAPHIC_VALUES[1],
              width = "220px"
            ),
            radioButtons(
              inputId = "MobilitySelector",
              label = "Display:",
              choices = c(
                "Aggregate",
                "Workplace",
                "Residential",
                "Retail & recreation",
                "Parks",
                "Grocery & pharmacy",
                "Transit stations"
              ),
              selected = "Aggregate"
            )
            
          )
        ),
        mainPanel(
          fluidRow(column(
            3,
            offset = 9,
            selectizeInput(
              "StateSelector",
              "Select your State",
              choices = stringr::str_to_title(levels(ALL_STATES)),
              multiple = TRUE
            )
          )),
          # hr(),
          withSpinner(plotlyOutput(outputId = "demo_scatter")),
          fluidRow(column(
            width = 5,
            verbatimTextOutput("demo_hover_info")
          )),
          fluidRow(withSpinner(
            dataTableOutput(outputId = "demo_correlation_table")
          ))
        )
      )
      
    ),
    tabPanel(
      "Policies and Mobility",
      fluid = TRUE,
      icon = icon("poll"),
      h2("Finally, do policies like stay-at-home orders succeed in reducing travel?"),
      h4("We can first answer this question by visually exploring trends in mobility before and after states implemented laws such as stay-at-home orders."),
      # titlePanel("Policies and Mobility"),
      fluidRow(column(
        6,
        selectInput(
          inputId = "state_selected",
          label = "Select State",
          choices = stringr::str_to_title(ALL_STATES),
          selected = "Texas",
          width = "220px"
        ),
        checkboxGroupInput(
          inputId = "selected_policies",
          label = "Select Policies:",
          choices = c(
            "State of Emergency",
            "Stay at Home",
            "Closed Non-essential Businesses"
          ),
          selected = "State of Emergency"
        )
      )),
      hr(),
      fluidRow(withSpinner(
        plotlyOutput(outputId = "policy_mobility")
      ))
    ),
    tabPanel(
      "Regression",
      fluid = TRUE,
      icon = icon("bar-chart"),
      h2("But a wide variety of factors confound the relationship between stay-at-home orders and reduced mobility."),
      h3("By bringing in data related to case loads, demographics, and prior trends in mobility, we can develop a more informed view of this relationship."),
      # titlePanel("Policies and Mobility"),
      fluidRow(column(
        6,
        p("In order to assess the effectiveness of policy on reducing mobility, various confounding factors must be accounted for. For example, the number of cases or deaths is likely correlated with both reduced mobility and increased intervention from the government. Additionally, as shown in our prior analyses, socioeconomic factors could have an impact on people’s ability to social distance. While these analyses hinted at some relations, we also performed Lasso regression to obtain a set of thirteen county-level socioeconomic variables to include in our models. For example, these include per capita income, the proportion of the population that falls into various age groups, and the proportion of the labor force that works in production or transportation."),
        p("Policy was represented by a binary variable indicating whether a stay-at-home order was in effect in a given day. We considered the seven days before the policy was enacted and every day after that (with data up to 4/12). Along with the socioeconomic variables and the number of cases and deaths (both at the county level and at the national level), this policy variable was included as a feature in a linear model which predicts daily mobility at the county level. Interactions between policy and each socioeconomic variable were also included as a measure of a county’s ability to social distance."),
        p("Using a fixed effects model with the within estimator ",
          tags$a(href = 'https://faculty.washington.edu/ezivot/econ582/fixedEffects.pdf', target = '_blank','(Fixed Effects Estimation of Panel Data)'), 
          "the socioeconomic factors--which are constant across time--are removed, but their interaction with policy--which change over time--must be included."),
        p("While mobility has certainly decreased following stay-at-home-orders (on average, mobility was .41 standard deviations below the mean in the seven days prior to policy and .73 standard deviations below the mean in the days since), the policy did not appear to cause this change. Instead, the model attributed the reduction in mobility mostly to the nation-wide number of coronavirus cases; seemingly, a growing fear of the virus, rather than compliance with government policy, has been the force motivating people to stay home. The process was repeated using a state-of-emergency declaration as the policy variable, yielding similar results. ")
      ),
        column(
          6, tags$img(src = "https://raw.githubusercontent.com/connorrothschild/covid-mobility/master/README-files/Regression%20table.jpg", height = 550)
          )
    )
    ),
  tabPanel(
    "Conclusion",
    fluid = TRUE,
    icon = icon("bar-chart"),
    # titlePanel("Policies and Mobility"),
    fluidRow(column(
      6,
      h2("Concluding thoughts"),
      p("In approaching this project, we sought to explore broadly how COVID-19 has affected the extent to which communities are moving around the country. We did this by examining questions of how people have changed their movement, if at all; the efficacy of policies limiting travel in meaningfully reducing movement; and what predictors may determine a particular community’s likelihood to abide by mobility regulations. We found that over the course of the virus spreading, mobility has broadly declined across the United States. There is a clear inverse relationship between a community’s number of cases and their overall mobility: as cases increase, mobility generally decreases."),
      p("In particular, we saw policies such as the enactment of “stay-at-home” orders correspond with a sharp decrease in mobility, but whether these orders are actually causing the decline in mobility is more difficult to answer. People’s perception of the threat of the virus (roughly estimated by the number of cases and deaths) is a clear confounding factor. We must also account for a county’s ability to reduce mobility. A lack of social distancing does not necessarily imply a reluctance to social distance; sometimes, it can imply an inability to social distance, caused by a variety of socioeconomic factors. In fact, preliminary models showed little causal relation between policy and change in mobility. However, these models are very basic and are not yet robust enough to draw significant conclusions from.")
    ),
    column(
      6,
      h2("Next steps"),
      p("In particular, we saw policies such as the enactment of “stay-at-home” orders correspond with a sharp decrease in mobility, but whether these orders are actually causing the decline in mobility is more difficult to answer. People’s perception of the threat of the virus (roughly estimated by the number of cases and deaths) is a clear confounding factor. We must also account for a county’s ability to reduce mobility. A lack of social distancing does not necessarily imply a reluctance to social distance; sometimes, it can imply an inability to social distance, caused by a variety of socioeconomic factors. In fact, preliminary models showed little causal relation between policy and change in mobility. However, these models are very basic and are not yet robust enough to draw significant conclusions from. "),
      p("However, we recognize that the research done for this competition is not complete. We suggest future research continue to explore the extent to which reduced mobility, which is purportedly evidence of “social distancing,” reliably reduces transmission rates. Future models should seek to establish this relationship to determine the exact effectiveness of these measures to reduce the disease transmission."),
      p("For more information on our project, please visit our ",
        tags$a(href = 'https://github.com/connorrothschild/covid-mobility', target = '_blank', 'GitHub repository.')),
      "There, you can find our code, data, and visualizations. The README contains our week 1 update for the CHRP competition. Thank you!")
    )
    )
  )
)
  
###### SHINY DASHBOARD INTERACTION
server <- function(input, output, session) {
  
  # observeEvent(input$link_to_start_presentation, {
  #   updateTabItems(session, "Introduction", "Effects of Demographics on Mobility")
  #   # tags$a(href = "#tab-8413-2")
  # })
  
  set.seed(122)
  
  get_demographic_column <- function(full_dat, name) {
    if (name == "Median Household Income ($)") {
      x <- as.numeric(full_dat$DP03_0062E)
    } else if (name == "Mean Commute Time (min)") {
      x <- as.numeric(full_dat$DP03_0025E)
    } else if (name == "% Service Jobs") {
      x <- as.numeric(full_dat$DP03_0028PE)
    } else if (name == "% Sales/Office Jobs") {
      x <- as.numeric(full_dat$DP03_0029PE)
    } else if (name == "% Production/Transport Jobs") {
      x <- as.numeric(full_dat$DP03_0031PE)
    } else if (name == "% Below Poverty") {
      x <- as.numeric(full_dat$EP_POV)
    } else if (name == "% Asian") {
      x <- as.numeric(full_dat$DP05_0044PE)
    } else if (name == "% White") {
      x <- as.numeric(full_dat$DP05_0037PE)
    } else if (name == "% African-American") {
      x <- as.numeric(full_dat$DP05_0038PE)
    } else if (name == "% Hispanic/Latino") {
      x <- as.numeric(full_dat$DP05_0071PE)
    } else if (name == "% Minority") {
      x <- as.numeric(full_dat$EP_MINRTY)
    }
    
    return(x)
  }
  get_mobility_column <- function(full_dat, name) {
    if (name == "Aggregate") {
      y <- full_dat$net_mob
    } else if (name == "Workplace") {
      y <- full_dat$net_work_mob
    } else if (name == "Residential") {
      y <- full_dat$net_res_mob
    } else if (name == "Retail & recreation") {
      y <- full_dat$net_retail_mob
    } else if (name == "Grocery & pharmacy") {
      y <- full_dat$net_grocery_mob
    } else if (name == "Transit stations") {
      y <- full_dat$net_transit_mob
    } else if (name == "Parks") {
      y <- full_dat$net_parks_mob
    }
    
    return(y)
  }
  
  output$demo_scatter <- renderPlotly({
    options(scipen = 999)
    
    dat <- full_dat
    if (!is.null(input$StateSelector)) {
      dat <- full_dat %>%
        filter(STATE %in% stringr::str_to_upper(input$StateSelector))
    }
    x <- get_demographic_column(dat, input$DemographicsSelector)
    y <- get_mobility_column(dat, input$MobilitySelector)
    
    p <- ggplot(dat, aes(x = x, y = y)) +
      geom_point(alpha = .5, aes(text = paste0("<b>", COUNTY, " County, ", stringr::str_to_title(STATE), "</b>",
                                       '<br>', '<i>Change in ', 
                           
                                       ifelse(input$MobilitySelector == "Aggregate", 'aggregate mobility', 'mobility related to '),
                                       ifelse(input$MobilitySelector == "Aggregate", "", stringr::str_to_lower(input$MobilitySelector)), 
                                              ':</i> ', round(y, digits = 0), "%",
                                       '<br><i>', stringr::str_to_sentence(input$DemographicsSelector), ':</i> ', scales::comma(x, accuracy = 1)
                                       ),
                     
                     ), 
                 color = "aquamarine3") +
      geom_smooth(method = 'lm',
                  formula = y ~ x,
                  color = "aquamarine4") +
      xlab(input$DemographicsSelector) +
      ylab(paste(
        "Average Change in",
        input$MobilitySelector,
        "Mobility, 3/22-3/29"
      )) +
      scale_x_continuous(labels = scales::comma_format())
    ggplotly(p, tooltip = "text")
  })
  
  output$demo_correlation_table <- DT::renderDataTable({
    x <- get_demographic_column(full_dat, input$DemographicsSelector)
    y <- get_mobility_column(full_dat, input$MobilitySelector)
    
    test <- cor.test(x, y)
    
    cor_tab <- cbind(c(test$estimate), c(test$p.value))
    rownames(cor_tab) <- c(input$DemographicsSelector)
    colnames(cor_tab) <- c("Pearson's r", "p-value")
    
    DT::datatable(cor_tab, options = list(dom = 't'))
  })
  output$policy_mobility <- renderPlotly({
    selected_state_mobility <-
      state_mobility[which(toupper(state_mobility$STATE) == toupper(input$state_selected)),]
    selected_state_policies <-
      state_policies[which(toupper(state_policies$STATE) == toupper(input$state_selected)),]
    
    selected_state_of_emergency <-
      selected_state_policies[1, "STATE.OF.EMERGENCY"]
    selected_stay_at_home <-
      selected_state_policies[1, "STAY.AT.HOME..SHELTER.IN.PLACE"]
    selected_closed_business <-
      selected_state_policies[1, "CLOSED.NON.ESSENTIAL.BUSINESSES"]
    
    p <-
      ggplot(data = state_mobility, aes(x = date, y = mobility)) +
      geom_line(color = "gray",
                alpha = 0.3,
                group = state_mobility$STATE,
                aes(text = paste0('<b>', stringr::str_to_title(STATE), "</b><br>", format(date, format = "%B %d"), ": ", round(mobility, 1), "%"))) +
      geom_line(data = selected_state_mobility,
                color = "steelblue",
                alpha = 1,
                size = 1, 
                group = selected_state_mobility$STATE,
                aes(text = paste0('<b>', stringr::str_to_title(STATE), "</b><br>", format(date, format = "%B %d"), ": ", round(mobility, 1), "%")))
    
    if ("State of Emergency" %in% input$selected_policies) {
      p <-
        p + geom_vline(
          aes(
            xintercept = as.numeric(selected_state_of_emergency),
            color = "State of Emergency"
          ),
          alpha = 0.5,
          show.legend = T
        )
    }
    if ("Stay at Home" %in% input$selected_policies) {
      p <-
        p + geom_vline(
          aes(
            xintercept = as.numeric(selected_stay_at_home),
            color = "Stay at Home"
          ),
          alpha = 0.5,
          show.legend = T
        )
    }
    if ("Closed Non-essential Businesses" %in% input$selected_policies) {
      p <-
        p + geom_vline(
          aes(
            xintercept = as.numeric(selected_closed_business),
            color = "Closed Non-essential Businesses"
          ),
          alpha = 0.5,
          show.legend = T
        )
    }
    
    p <- p +
      scale_color_manual(
        name = "Policies",
        values = c(
          "Stay at Home" = "red",
          "State of Emergency" = "green",
          "Closed Non-essential Businesses" = "cyan"
        )
      ) +
      scale_x_date(date_breaks = "5 days" , date_labels = "%m/%d") +
      labs(x = "Date", y = "% Mobility Above Baseline") +
      theme(legend.position = "bottom")
    
    ggplotly(p, tooltip = "text")
  })
  
  output$case_mobility <- renderPlotly({
    selected <- case_mobility[which(case_mobility$STATE == stringr::str_to_upper(input$CaseStateSelector)), ]
    selected_state_policies <- state_policies[which(toupper(state_policies$STATE) == toupper(input$CaseStateSelector)), ]
    print(selected_state_policies)
    selected_state_of_emergency <- selected_state_policies[1, "STATE.OF.EMERGENCY"]
    selected_stay_at_home <- selected_state_policies[1, "STAY.AT.HOME..SHELTER.IN.PLACE"]
    selected_closed_business <- selected_state_policies[1, "CLOSED.NON.ESSENTIAL.BUSINESSES"]
    
    coeff = 1/((max(selected$cases)-min(selected$cases))/(max(selected$mobility)-min(selected$mobility)))
    
    p <- ggplot() +
      
      geom_point(data=selected, size = 1, aes(x=date, y=cases,
                                    text = paste0('<b>', format(date, format = "%B %d"), " in ", stringr::str_to_title(STATE), '</b>',
                                                  "<br><i>Cases:</i> ", scales::comma(cases, accuracy = 1))), 
                                   color='steelblue') +
      geom_line(data=selected, aes(x=date, y=cases), 
                                   color='steelblue') +
      geom_point(data=selected, size = 1, aes(x=date, y=mobility/coeff,
                                   text = paste0('<b>', format(date, format = "%B %d"), " in ", stringr::str_to_title(STATE), '</b>',
                                                 "<br><i>Mobility:</i> ", round(mobility, 1), "%")), 
                                   color='seagreen3') +
      geom_line(data=selected, aes(x=date, y=mobility/coeff),
                                  color='seagreen3') +
      geom_vline(aes(xintercept=as.numeric(selected_state_of_emergency), color = "State of Emergency"), alpha=0.75, show.legend=T) + 
      geom_vline(aes(xintercept=as.numeric(selected_stay_at_home), color = "Stay at Home"), alpha=0.5, show.legend=T) +
      geom_vline(aes(xintercept=as.numeric(selected_closed_business), color = "Closed Non-essential Businesses"), alpha=0.5, show.legend=T) +
      scale_color_manual(name = "Policies", values = c("Stay at Home" = "red", "State of Emergency" = "green", "Closed Non-essential Businesses" = "cyan")) +
                        
      scale_y_continuous(
        
        # Features of the first axis
        name = "Cases",
        
        # Add a second axis and specify its features
        sec.axis = sec_axis(~.*coeff, name="Mobility", breaks = seq(-50,50,10))
      ) +
      
      labs(
        x = "Date"
      ) + 
      
      theme(
        # axis.title.y = element_text(color = 'slateblue2', size=13),
        # axis.title.y.right = element_text(color = 'seagreen3', size=13)
      ) +
      
      ggtitle("Cases vs. Mobility")
    
    ay <- list(
      tickfont = list(size=11.7),
      titlefont=list(size=14.6),
      overlaying = "y",
      nticks = 5,
      side = "right",
      title = "Second y axis"
    )
    
    ggplotly(p, tooltip = 'text') %>% 
      layout(legend = list(orientation = "h", x = -0.05, y = -0.2)) 
  })
}

shinyApp(ui, server)
