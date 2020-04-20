library(readr)
library(dplyr)
library(janitor)

# reading mobility data
mobility <- read.csv('../data/mobility/county/county-data-long.csv',
                     stringsAsFactors = FALSE)
# converting dates to date objects
mobility <- mobility %>% 
  mutate(date=as.Date(date))

# reading ACS data
ACS <- read.csv('../data/demographics/ACS_lasso_small.csv',
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
policy <- read.csv('../data/policies/covid_us_state_policies.csv',
                   stringsAsFactors = FALSE)
policy <- policy %>% 
  janitor::clean_names()

# function to join datasets, set up data for fixed effects model with
#  within estimator, run model
run_within_daily<- function(mobility_df,ACS_df,cases_df,policy_df,
                             policy_var,bin=TRUE,pre_days=NULL){
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
  
  # joining mobility and policy data
  mobility_policy_df <- merge(mobility_df,policy_df_clean,
                              by.x='admin1',by.y='state')
  # number of days since policy
  mobility_policy_df <- mobility_policy_df %>% 
    mutate(days_since = date - policy_date)
  # keeping only days of interest
  if (!is.null(pre_days)){
    mobility_policy_df <- mobility_policy_df %>% 
      mutate(include=sapply(mobility_policy_df$days_since,
                            function(x){
                              ifelse(x > -pre_days,1,0)
                            }))
    mobility_policy_df <- mobility_policy_df %>% 
      filter(include==1) %>% select(-include)
  }
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
                     merged_df$policy_x*(merged_df) %>% 
                       select(all_of(ACS_cols)))
  # changing column name of interaction terms
  ACS_cols_int <- sapply(ACS_cols,function(x){paste0(x,'_int')})
  colnames(merged_df)[(ncol(merged_df)-length(ACS_cols)+1):
                        ncol(merged_df)] <- ACS_cols_int
  
  # finding county means across time and joining to dataset
  time_means <- merged_df %>% group_by(fips) %>% 
    summarise(value_std_mean=mean(value_std),
              policy_x_mean=mean(policy_x),
              cases_mean=mean(cases),
              deaths_mean=mean(deaths))
  merged_df <- merge(merged_df,time_means,by='fips')
  # adding national means
  merged_df['cases_natl_mean'] <- mean(merged_df$cases_natl)
  merged_df['deaths_natl_mean'] <- mean(merged_df$deaths_natl)
  # adding interaction between policy mean and ACS variables
  merged_df <- cbind(merged_df,merged_df$policy_x_mean*(
    merged_df %>% select(all_of(ACS_cols))
  ))
  # changing column name of interaction terms
  ACS_cols_int_mean <- sapply(ACS_cols_int,function(x){paste0(x,'_mean')})
  colnames(merged_df)[(ncol(merged_df)-length(ACS_cols)+1):
                        ncol(merged_df)] <- ACS_cols_int_mean
  
  # difference between actual and mean values
  tildes_df <- merged_df %>% 
    select(c(value_std,policy_x,cases,deaths,cases_natl,deaths_natl,
             all_of(ACS_cols_int))) -
    merged_df %>% 
    select(c(value_std_mean,policy_x_mean,cases_mean,deaths_mean,
             cases_natl_mean,deaths_natl_mean,all_of(ACS_cols_int_mean)))

  # regression
  fit <- lm(value_std~.,data = tildes_df)
  
  list(fit,tildes_df,merged_df)
}

out <- run_within_daily(mobility,ACS,cases,policy,
                        'stay_at_home_shelter_in_place',pre_days=7)
fit <- out[[1]]
tildes <- out[[2]]
merged_all <- out[[3]]

pred_labels <- c('stay_at_home','n_cases_county',
                   'n_deaths_county','n_cases_natl','n_deaths_natl',
                   'pct_employed','pct_not_labor_force',
                   'pct_work_transport','pct_industry_finance',
                   'pct_industry_rec','pct_self_employed',
                   'pct_public_health_coverage','pct_health_coverage',
                   'pct_poverty','pct_hispanic_other','pct_age_10_14',
                   'pct_age_20_24','per_capita_income')
tab_model(fit,pred.labels = pred_labels,show.ci = FALSE,
          show.ci50 = FALSE,digits = 6,show.intercept = FALSE)

# same as other function but with weekly rather than daily data
run_within_weekly <- function(mobility_df,ACS_df,cases_df,policy_df,
                             policy_var,bin=TRUE){
  # input: policy_var: column of policy to include in model (only 1),
  #        bin: logical indicating whether policy variable should be
  #             treated as binary (TRUE)
  # output: regression model, data frame used for model, merged data
  #         with "raw" data
  
  # keeping only policy of interest and converting to date object
  policy_df_clean <- policy_df %>% 
    select(state,all_of(policy_var)) %>% 
    mutate(policy_date=as.Date(policy_df[,policy_var],
                               format='%m/%d/%Y'))
  
  # joining mobility and policy data
  mobility_policy_df <- merge(mobility_df,policy_df_clean,
                              by.x='admin1',by.y='state')
  # number of days since policy
  mobility_policy_df <- mobility_policy_df %>% 
    mutate(days_since = date - policy_date)
  # adding week number
  mobility_policy_df <- mobility_policy_df %>% 
    mutate(week = floor((days_since-1)/7))
  
  
  # adding case data
  mobility_policy_cases_df <- merge(mobility_policy_df,cases_df,
                                    by=c('date','fips'))
  # grouping by week
  grouped_df <- mobility_policy_cases_df %>% 
    group_by(fips,week) %>% 
    summarise(n_days=n(),mean_value=mean(value),min_cases=min(cases),
              max_cases=max(cases),min_deaths=min(deaths),
              max_deaths=max(deaths),min_cases_natl=min(cases_natl),
              max_cases_natl=max(cases_natl),
              min_deaths_natl=min(deaths_natl),
              max_deaths_natl=max(deaths_natl))
  # keeping only full weeks
  grouped_df <- grouped_df %>% 
    filter(n_days==7)
  
  # policy variable to be used in model
  if (bin){
    grouped_df['policy_x'] <- sapply(grouped_df$week,function(x){
      ifelse(x<0,0,1)
    })
  }
  else{
    grouped_df['policy_x'] <- sapply(grouped_df$week,function(x){
      ifelse(x<0,0,x+1)
    })
  }
  
  # adding ACS data
  merged_df <- merge(grouped_df,ACS_df,
                     by.x='fips',by.y='GEO_ID')
  
  # column names of ACS variables
  ACS_cols <- colnames(ACS)[3:ncol(ACS)]
  
  # adding interaction between policy and ACS variables
  merged_df <- cbind(merged_df,
                     merged_df$policy_x*(merged_df) %>% 
                       select(all_of(ACS_cols)))
  # changing column name of interaction terms
  ACS_cols_int <- sapply(ACS_cols,function(x){paste0(x,'_int')})
  colnames(merged_df)[(ncol(merged_df)-length(ACS_cols)+1):
                        ncol(merged_df)] <- ACS_cols_int
  
  # finding county means across time and joining to dataset
  time_means <- merged_df %>% group_by(fips) %>% 
    summarise(mean_value_mean=mean(mean_value),
              policy_x_mean=mean(policy_x),
              min_cases_mean=mean(min_cases),
              max_cases_mean=mean(max_cases),
              min_deaths_mean=mean(min_deaths),
              max_deaths_mean=mean(max_deaths))
  merged_df <- merge(merged_df,time_means,by='fips')
  # adding national means
  merged_df['min_cases_natl_mean'] <- mean(merged_df$min_cases_natl)
  merged_df['max_cases_natl_mean'] <- mean(merged_df$max_cases_natl)
  merged_df['min_deaths_natl_mean'] <- mean(merged_df$min_deaths_natl)
  merged_df['max_deaths_natl_mean'] <- mean(merged_df$max_deaths_natl)
  # adding interaction between policy mean and ACS variables
  merged_df <- cbind(merged_df,merged_df$policy_x_mean*(
    merged_df %>% select(all_of(ACS_cols))
  ))
  # changing column name of interaction terms
  ACS_cols_int_mean <- sapply(ACS_cols_int,function(x){paste0(x,'_mean')})
  colnames(merged_df)[(ncol(merged_df)-length(ACS_cols)+1):
                        ncol(merged_df)] <- ACS_cols_int_mean
  
  # difference between actual and mean values
  tildes_df <- merged_df %>% 
    select(c(mean_value,policy_x,min_cases,max_cases,min_deaths,
             max_deaths,min_cases_natl,max_cases_natl,min_deaths_natl,
             max_deaths_natl,all_of(ACS_cols_int))) -
    merged_df %>% 
    select(c(mean_value_mean,policy_x_mean,min_cases_mean,max_cases_mean,
             min_deaths_mean,max_deaths_mean,min_cases_natl_mean,
             max_cases_natl_mean,min_deaths_natl_mean,
             max_deaths_natl_mean,all_of(ACS_cols_int_mean)))
  
  # regression
  fit <- lm(mean_value~.,data = tildes_df)
  
  list(fit,tildes_df,merged_df)
}

out_weekly <- run_within_weekly(mobility,ACS,cases,policy,
                                'stay_at_home_shelter_in_place')
fit_weekly <- out_weekly[[1]]
tildes_weekly <- out_weekly[[2]]
merged_all_weekly <- out_weekly[[3]]