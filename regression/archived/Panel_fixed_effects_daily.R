library(readr)
library(dplyr)
library(janitor)

# reading mobility data
mobility <- read.csv('../viz/data/mobility/county/county-data-long.csv',
                     stringsAsFactors = FALSE)
# converting dates to date objects
mobility <- mobility %>% 
  mutate(date=as.Date(date))
# one-hot encoding day of week variable (leaving out Thursday)
mobility <- mobility %>% mutate(Monday=case_when(day_of_week=='M'~1,
                                                 day_of_week!='M'~0),
                                Tuesday=case_when(day_of_week=='Tu'~1,
                                                  day_of_week!='Tu'~0),
                                Wednesday=case_when(day_of_week=='W'~1,
                                                    day_of_week!='W'~0),
                                Friday=case_when(day_of_week=='F'~1,
                                                 day_of_week!='F'~0),
                                Saturday=case_when(day_of_week=='Sa'~1,
                                                   day_of_week!='Sa'~0),
                                Sunday=case_when(day_of_week=='Su'~1,
                                                 day_of_week!='Su'~0))

# reading ACS data
ACS <- read.csv('../viz/data/demographics/ACS_lasso_small.csv',
                stringsAsFactors = FALSE)

# reading case data
cases <- read.csv('https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv',
                  stringsAsFactors = FALSE)
# converting dates to date objects
cases <- cases %>% 
  mutate(date=as.Date(date))
# adding daily data point for each county (not just those with a case)
cases <- merge(cases,mobility %>% select(fips,date,admin1,admin2),
               by=c('fips','date'),all.y = TRUE) %>% 
  select(-c(county,state)) %>% rename(state=admin1,county=admin2)
cases$cases[is.na(cases$cases)] <- 0
cases$deaths[is.na(cases$deaths)] <- 0
# adding national number of cases and deaths by day
cases <- merge(cases,cases %>% group_by(date) %>% 
                 summarise(cases_natl=sum(cases),deaths_natl=sum(deaths)),
               by='date')

# reading policy data
policy <- read.csv('../viz/data/policies/covid_us_state_policies.csv',
                   stringsAsFactors = FALSE)
policy <- policy %>% 
  janitor::clean_names()

# function to join datasets, set up data for fixed effects model with
#  within estimator, run model
run_within_daily_dotw <- function(mobility_df,ACS_df,cases_df,policy_df,
                            policy_var,bin=TRUE){
  # input: policy_var: column of policy to include in model (only 1),
  #        bin: logical indicating whether policy variable should be
  #             treated as binary (TRUE)
  #        pre_days: number of days before policy to include (all if NULL)
  # output: regression model, data frame used for model, merged data
  #         frame with "raw" data
  
  # keeping only policy of interest and converting to date object
  policy_df_clean <- policy_df %>% 
    select(state,all_of(policy_var)) %>% 
    mutate(policy_date=as.Date(policy_df[,policy_var],
                               format='%m/%d/%Y'))
  # looking only at states with policy in place
  policy_df_clean <- policy_df_clean %>% 
    filter(!is.na(policy_date))
  
  # joining mobility and policy data
  mobility_policy_df <- merge(mobility_df,policy_df_clean,
                              by.x='admin1',by.y='state')
  # number of days since policy
  mobility_policy_df <- mobility_policy_df %>% 
    mutate(days_since = date - policy_date)
  # binary variable indicating whether policy is in effect
  mobility_policy_df <- mobility_policy_df %>% 
    mutate(post_policy=case_when(date > policy_date ~ 1,
                                 date <= policy_date ~ 0))
  # policy variable to be used in model
  if (bin){
    mobility_policy_df <- mobility_policy_df %>% 
      mutate(policy_x=post_policy)
  }
  else{
    mobility_policy_df <- mobility_policy_df %>% 
      mutate(policy_x=sapply(mobility_policy_df$days_since,
                             function(x){
                               ifelse(x<=0,0,x)
                             }))
  }
  
  # adding case data
  mobility_policy_cases_df <- merge(mobility_policy_df,cases_df,
                                    by=c('date','fips'))
  
  # adding ACS data
  merged_df <- merge(mobility_policy_cases_df,ACS_df,
                     by.x='fips',by.y='GEO_ID')
  
  # column names of ACS variables
  ACS_cols <- colnames(ACS)[3:ncol(ACS)]
  
  # adding interaction between policy and ACS variables
  merged_df <- cbind(merged_df,
                     merged_df$policy_x*((merged_df) %>% 
                                           select(all_of(ACS_cols))))
  # changing column name of interaction terms
  ACS_cols_int <- sapply(ACS_cols,function(x){paste0(x,'_int')})
  colnames(merged_df)[(ncol(merged_df)-length(ACS_cols)+1):
                        ncol(merged_df)] <- ACS_cols_int
  
  # column names of day of week variables
  days_cols <- colnames(mobility_df)[(ncol(mobility_df)-5):
                                       ncol(mobility_df)]
  
  # adding interaction between policy and day of week
  merged_df <- cbind(merged_df,
                     merged_df$policy_x*(merged_df %>% 
                                           select(all_of(days_cols))))
  # changing column name of interaction terms
  days_cols_int <- as.character(sapply(days_cols,function(x){
    paste0(x,'_int')}))
  colnames(merged_df)[(ncol(merged_df)-5):
                        ncol(merged_df)] <- days_cols_int
  
  # finding county means across time and joining to dataset
  time_means <- merged_df %>% group_by(fips) %>% 
    summarise(value_mean=mean(value),
              policy_x_mean=mean(policy_x),
              cases_mean=mean(cases),
              deaths_mean=mean(deaths),
              Monday_int_mean=mean(Monday_int),
              Tuesday_int_mean=mean(Tuesday_int),
              Wednesday_int_mean=mean(Wednesday_int),
              Friday_int_mean=mean(Friday_int),
              Saturday_int_mean=mean(Saturday_int),
              Sunday_int_mean=mean(Sunday_int))
  merged_df <- merge(merged_df,time_means,by='fips')
  # adding national means
  merged_df['cases_natl_mean'] <- mean(merged_df$cases_natl)
  merged_df['deaths_natl_mean'] <- mean(merged_df$deaths_natl)
  merged_df <- cbind(merged_df,matrix(
    rep(apply(merged_df %>% select(all_of(days_cols)),2,mean),
        nrow(merged_df)),
    nrow = nrow(merged_df),byrow = TRUE))
  # changing column names of day of week means
  days_cols_mean <- sapply(days_cols,function(x){paste0(x,'_mean')})
  colnames(merged_df)[(ncol(merged_df)-5):ncol(merged_df)] <- sapply(
    days_cols,function(x){paste0(x,'_mean')}
  )
  # adding interaction between policy mean and ACS variables
  merged_df <- cbind(merged_df,merged_df$policy_x_mean*(
    merged_df %>% select(all_of(ACS_cols))
  ))
  # changing column name of interaction terms
  ACS_cols_int_mean <- sapply(ACS_cols_int,function(x){
    paste0(x,'_mean')})
  colnames(merged_df)[(ncol(merged_df)-length(ACS_cols)+1):
                        ncol(merged_df)] <- ACS_cols_int_mean
  
  # difference between actual and mean values
  tildes_df <- merged_df %>% 
    select(c(value,policy_x,cases,deaths,cases_natl,deaths_natl,
             all_of(days_cols),all_of(ACS_cols_int),
             all_of(days_cols_int))) -
    merged_df %>% 
    select(c(value_mean,policy_x_mean,cases_mean,deaths_mean,
             cases_natl_mean,deaths_natl_mean,all_of(days_cols_mean),
             all_of(ACS_cols_int_mean),Monday_int_mean,
             Tuesday_int_mean,Wednesday_int_mean,Friday_int_mean,
             Saturday_int_mean,Sunday_int_mean))
  
  # regression
  fit <- lm(value~.,data = tildes_df)
  
  list(fit,tildes_df,merged_df)
}

out <- run_within_daily_dotw(mobility,ACS,cases,policy,
                             'stay_at_home_shelter_in_place')
fit <- out[[1]]