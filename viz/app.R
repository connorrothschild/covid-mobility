## app.R ##
library(shinydashboard)
## THIS FILE IS RUN BEFORE THE SHINY DASHBOARD STARTS

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


thm <- 
  hc_theme(
    colors = c("#1a6ecc", "#434348", "#90ed7d"),
    chart = list(
      backgroundColor = "transparent",
      style = list(fontFamily = "Source Sans Pro")
    ),
    xAxis = list(
      gridLineWidth = 1
    )
  )


# load ACS data
ACS_econ <- read.csv("../data/demographics/ACS_ECONOMIC_2018.csv",stringsAsFactors=FALSE)
ACS_social <- read.csv("../data/demographics/ACS_SOCIAL_2018.csv",stringsAsFactors=FALSE)

# rename GEO_ID to FIPS
names(ACS_econ)[1] <- "FIPS1"
names(ACS_social)[1] <- "FIPS2"

# extract abbreviated FIPS code
ACS_econ$FIPS1 = substr(ACS_econ$FIPS, 10, 14)
ACS_social$FIPS2 = substr(ACS_social$FIPS, 10, 14)

ACS_econ <- ACS_econ[-1,]
ACS_social <- ACS_social[-1,]


# laod SVI CDC data
SVI_dat <- read.csv("../data/demographics/SVI2018_US_COUNTY.csv")

# load mobility data
mobility <- read.csv("../data/archived/county-data-wide-cleaned.csv")
mobility <- na.omit(mobility)

mobility$net_mob <- (mobility$X2020.03.22 + mobility$X2020.03.23 + mobility$X2020.03.24 + mobility$X2020.03.25 + mobility$X2020.03.26 + mobility$X2020.03.27 + mobility$X2020.03.28 + mobility$X2020.03.29)/8

# Aggregate all mobility for each county (average over categories to get net mobility)
mobility_agg <- mobility %>%
  select(-one_of("X", "Region", "Category", "State")) %>%
  group_by(fips) %>% 
  summarise_all(funs(mean))

# clean up to get each county by fips
mobility_agg<-unique(mobility_agg)
names(mobility_agg)[1] <- "County_FIPS"


mobility_work <- cbind("FIPS3"=mobility$fips[mobility$Category=="Workplace"],"net_work_mob"=mobility$net_mob[mobility$Category=="Workplace"])

# select relevant columns from SVI data
SVI_sub <- SVI_dat[,c("FIPS", "STATE", "ST_ABBR","E_TOTPOP","EP_POV","EP_UNEMP","EP_PCI","EP_AGE65","EP_MINRTY","EP_MUNIT")]
ACS_social_sub <- ACS_social[,c("FIPS2","DP05_0037PE","DP05_0038PE","DP05_0039PE","DP05_0044PE","DP05_0052PE","DP05_0057PE","DP05_0071PE","DP05_0002PE","DP05_0003PE")]
ACS_econ_sub <- ACS_econ[,c("FIPS1","DP03_0002PE","DP03_0009PE","DP03_0025E","DP03_0027PE","DP03_0028PE","DP03_0029PE","DP03_0030E","DP03_0031PE","DP03_0062E","DP03_0063E")]


ACS_social_sub[,2:10] <- as.numeric(unlist(ACS_social_sub[,2:10]))
ACS_econ_sub <- na.omit(ACS_econ_sub)

ACS_econ_sub[,2:11] <- as.numeric(unlist(ACS_econ_sub[,2:11]))
ACS_econ_sub <- na.omit(ACS_econ_sub)


# join SVI, ACS, and mobility into one frame
full_dat <- merge(mobility_agg, SVI_sub, by.x="County_FIPS", by.y="FIPS")
full_dat <- merge(full_dat, ACS_social_sub,  by.x="County_FIPS", by.y="FIPS2", all.x = TRUE)
full_dat <- merge(full_dat, ACS_econ_sub,  by.x="County_FIPS", by.y="FIPS1", all.x = TRUE)
full_dat <- merge(full_dat, mobility_work,  by.x="County_FIPS", by.y="FIPS3", all.x = TRUE)

# get average change in mobility for last week in data
full_dat$net_mob <- (full_dat$X2020.03.22 + full_dat$X2020.03.23 + full_dat$X2020.03.24 + full_dat$X2020.03.25 + full_dat$X2020.03.26 + full_dat$X2020.03.27 + full_dat$X2020.03.28 + full_dat$X2020.03.29)/8

# Remove bad data
full_dat <- full_dat[full_dat$EP_POV > 0, ]

# Demographic columns to plot
DEMOGRAPHIC_VALUES <- c("Median Household Income ($)", "Mean Commute Time (min)", 
                        "% Service Jobs", "% Sales/Office Jobs", "% Production/Transport Jobs",
                        "% Below Poverty",
                        "% Asian", "% White", "% African-American", "% Hispanic/Latino", "% Minority")

############ STATE MOBILITY DATA

# Aggregate all columns in c by weighted average, using E_TOTPOP as the weights
state_mobility <- data.table(full_dat, key = "STATE")
for(n in colnames(full_dat)[!colnames(full_dat) %in% c("STATE", "E_TOTPOP", "County_FIPS")]){
  state_mobility[,
                 (n) := weighted.mean(get(n), E_TOTPOP),
                 #with = FALSE,
                 by = STATE]
}
# Remove uninteresting columns
state_mobility <- state_mobility %>% select(-contains("DP")) %>% select(-contains("EP"))
state_mobility <- subset(state_mobility, select = -c(County_FIPS, E_TOTPOP, net_mob, net_work_mob, ST_ABBR ))
# Remove duplicate rows
state_mobility <- as.data.frame(state_mobility) %>% distinct()
# Wide form to long form
state_mobility <- gather(state_mobility, date, mobility, X2020.02.17:X2020.03.29, factor_key=FALSE)
state_mobility$date <- as.Date(state_mobility$date, format='X%Y.%m.%d')

######## STATE POLICY DATA

state_policies <- read.csv("../data/policies/covid_us_state_policies.csv")
colnames(state_policies) <- toupper(colnames(state_policies))
state_policies$STATE <- toupper(state_policies$STATE)
state_policies$STATE.OF.EMERGENCY <- as.Date(state_policies$STATE.OF.EMERGENCY, format='%m/%d/%Y')
state_policies$STAY.AT.HOME..SHELTER.IN.PLACE <- as.Date(state_policies$STAY.AT.HOME..SHELTER.IN.PLACE, format='%m/%d/%Y')
state_policies$CLOSED.NON.ESSENTIAL.BUSINESSES <- as.Date(state_policies$CLOSED.NON.ESSENTIAL.BUSINESSES, format='%m/%d/%Y')
state_policies[state_policies == 0] <- NA

ALL_STATES <- unique(state_mobility$STATE)


###### SHINY DASHBOARD UI
ui <- fluidPage(
  #Navbar structure for UI
  navbarPage("Mobility", theme = shinytheme("lumen"),
             tabPanel("Effects of Demographics on Mobility", fluid = TRUE, icon = icon("address-book"),
                      #tags$style(button_color_css),
                      # Sidebar layout with a input and output definitions
                      sidebarLayout(
                        sidebarPanel(
                          titlePanel("Demographic Characteristics"),
                          #shinythemes::themeSelector(),
                          fluidRow(selectInput(inputId = "DemographicsSelector",
                                               label = "Select Demographic Value",
                                               choices = DEMOGRAPHIC_VALUES,
                                               selected = DEMOGRAPHIC_VALUES[1],
                                               width = "220px"),
                                   radioButtons(inputId = "MobilitySelector",
                                                label = "Display:",
                                                choices = c("Aggregate", "Workplace", ""),
                                                selected = "Aggregate")
                                   
                        )),
                        mainPanel(
                          fluidRow(
                            column(3, offset = 9,
                                   
                                   radioButtons(inputId = "show_NamesFinder",
                                                label = "Display:",
                                                choices = c("School Names", "City Names", "Neither"),
                                                selected = "School Names")
                            )
                          ),
                          # hr(),
                          withSpinner(plotOutput(outputId = "demo_scatter")),
                          fluidRow(
                            column(width = 5,
                                   verbatimTextOutput("demo_hover_info")
                            )
                          ),
                          fluidRow(
                            withSpinner(dataTableOutput(outputId = "demo_correlation_table")))
                        )
                        )
                      
              ),
             tabPanel("Policies and Mobility", fluid = TRUE, icon = icon("poll"),
                      titlePanel("Policies and Mobility"),
                      fluidRow(
                        column(6,
                               selectInput(inputId = "state_selected",
                                           label = "Select State",
                                           choices = stringr::str_to_title(levels(ALL_STATES)),
                                           selected = "ALABAMA",
                                           width = "220px"),
                               checkboxGroupInput(inputId = "selected_policies",
                                                  label = "Select Policies:",
                                                  choices = c("State of Emergency", "Stay at Home", "Non-Essential Businesses"),
                                                  selected = "State of Emergency")
                        )
                      ),
                      hr(),
                      fluidRow(
                               withSpinner(plotOutput(outputId = "policy_mobility" 
                                                      # brush = "brush_SchoolComp"
                               ))
                        
                      )
             )
  )
)

###### SHINY DASHBOARD INTERACTION
server <- function(input, output) {
  set.seed(122)
  histdata <- rnorm(500)
  
  get_demographic_column <- function(name){
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
  get_mobility_column <- function(name){
    if (name == "Aggregate") {
      y <- full_dat$net_mob
    } else if (name == "Workplace") {
      y <- full_dat$net_work_mob
    } else if (name == "") {
      
    } else if (name == "") {
      
    }
    return(y)
  }

  
  output$demo_scatter <- renderPlot({
    x <- get_demographic_column(input$DemographicsSelector)
    y <- get_mobility_column(input$MobilitySelector)
    
    options(scipen = 999)
    
    ggplot(full_dat, aes(x=x,y=y)) + 
      geom_point(color="aquamarine3") + 
      geom_smooth(method='lm',color="aquamarine4") + 
      xlab(input$DemographicsSelector) + 
      ylab(paste("Average Change in", input$MobilitySelector, "Mobility, 3/22-3/29")) 
  })
  
  output$demo_correlation_table<-DT::renderDataTable({
    x <- get_demographic_column(input$DemographicsSelector)
    y <- get_mobility_column(input$MobilitySelector)

    test <- cor.test(x, y)
    
    cor_tab <- cbind(c(test$estimate), c(test$p.value))
    rownames(cor_tab) <- c(input$DemographicsSelector)
    colnames(cor_tab) <- c("Pearson's r","p-value")
    
    DT::datatable(cor_tab, options = list(dom = 't'))
  })
  output$policy_mobility <- renderPlot({
    selected_state_mobility <- state_mobility[which(toupper(state_mobility$STATE) == toupper(input$state_selected)), ]
    selected_state_policies <- state_policies[which(toupper(state_policies$STATE) == toupper(input$state_selected)), ]

    selected_state_of_emergency <- selected_state_policies[1, "STATE.OF.EMERGENCY"]
    selected_stay_at_home <- selected_state_policies[1, "STAY.AT.HOME..SHELTER.IN.PLACE"]
    selected_closed_business <- selected_state_policies[1, "CLOSED.NON.ESSENTIAL.BUSINESSES"]
    
    
    p <- ggplot(data=state_mobility, aes(x = date, y = mobility)) +
      geom_line(color="gray", alpha=0.3, group = state_mobility$STATE) +
      geom_line(data = selected_state_mobility, color="blue", alpha=1)

    if ("State of Emergency" %in% input$selected_policies) {
    }
    if ("Stay at Home" %in% input$selected_policies) {
      p <- p + geom_vline(aes(xintercept=selected_stay_at_home, color = "Stay at Home"), alpha=0.5, show.legend=T)
    }
    if ("Closed Non-essential Businesses" %in% input$selected_policies) {
      p <- p + geom_vline(aes(xintercept=selected_closed_business, color = "Closed Non-essential Businesses"), alpha=0.5, show.legend=T)  
    }
    
    p <- p + 
      scale_color_manual(name = "Policies", values = c("Stay at Home" = "red", "State of Emergency" = "green", "Closed Non-essential Businesses" = "cyan")) +
      scale_x_date(date_breaks = "5 days" , date_labels = "%m/%d") +
      labs(x = "Date", y = "% Mobility Above Baseline") +
      theme(legend.position="bottom")
    p
  })
  
}

shinyApp(ui, server)