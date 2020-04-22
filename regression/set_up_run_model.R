library(readr)
library(dplyr)
library(janitor)

# reading mobility data
mobility <- read.csv('../viz/data/mobility/county/county-data-long.csv',
                     stringsAsFactors = FALSE)
# converting dates to date objects
mobility <- mobility %>% 
  mutate(date=as.Date(date))

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
# converting to log scale
cases <- cases %>% 
  mutate(cases=case_when(cases==0~-1,cases>0~log(cases)),
         deaths=case_when(deaths==0~-1,deaths>0~log(deaths)),
         cases_natl=case_when(cases_natl==0~-1,
                              cases_natl>0~log(cases_natl)),
         deaths_natl=case_when(deaths_natl==0~-1,
                               deaths_natl>0~log(deaths_natl)))

# reading policy data
policy <- read.csv('../viz/data/policies/covid_us_state_policies.csv',
                   stringsAsFactors = FALSE)
policy <- policy %>% 
  janitor::clean_names()

# same as other function but with weekly rather than daily data
run_weekly <- function(mobility_df,ACS_df,cases_df,policy_df,
                       policy_var,bin=TRUE,no_max=TRUE){
  # input: policy_var: column of policy to include in model (only 1),
  #        bin: logical indicating whether policy variable should be
  #             treated as binary (TRUE)
  #        no_county: logical indicating whether county-level
  #                   cases/deaths should be included
  # output: regression model, data frame used for model, merged data
  #         with "raw" data
  
  # keeping only policy of interest and converting to date object
  policy_df_clean <- policy_df %>% 
    select(state,all_of(policy_var)) %>% 
    mutate(policy_date=as.Date(policy_df[,policy_var],
                               format='%m/%d/%Y'))
  # filling in policy date as latest day of data for those with no policy
  policy_df_clean <- policy_df_clean %>% 
    mutate(no_policy=case_when(!is.na(policy_date)~0,
                               is.na(policy_date)~1))
  policy_df_clean$policy_date[
    is.na(policy_df_clean$policy_date)] <- as.Date('2020-04-21')
  
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
              max_deaths_mean=mean(max_deaths),
              min_cases_natl_mean=mean(min_cases_natl),
              max_cases_natl_mean=mean(max_cases_natl),
              min_deaths_natl_mean=mean(min_deaths_natl),
              max_deaths_natl_mean=mean(max_deaths_natl))
  merged_df <- merge(merged_df,time_means,by='fips')
  
  # adding interaction between policy mean and ACS variables
  ACS_df_int_means <- cbind(merged_df$fips,merged_df$policy_x_mean*(
    merged_df %>% select(all_of(ACS_cols))))
  merged_df <- cbind(merged_df,ACS_df_int_means[,-1])
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
  
  # removing county-level number of cases/deaths if so desired
  if (no_max){
    tildes_df <- tildes_df %>% 
      select(-c(max_cases,max_deaths,max_cases_natl,max_deaths_natl))
  }
  
  # regression
  fit <- lm(mean_value~.,data = tildes_df)
  
  list(fit,tildes_df,merged_df,time_means,ACS_df_int_means)
}

out_weekly <- run_weekly(mobility,ACS,cases,policy,
                         'stay_at_home_shelter_in_place')
fit_weekly <- out_weekly[[1]]
tildes_weekly <- out_weekly[[2]]
merged_all_weekly <- out_weekly[[3]]
time_means_weekly <- out_weekly[[4]] %>% 
  select(-c(mean_value_mean,max_cases_mean,max_deaths_mean,
            max_cases_natl_mean,max_deaths_natl_mean))
ACS_means_weekly <- out_weekly[[5]] %>% 
  rename(fips=`merged_df$fips`)

# data with updated number of cases
cases_new <- read.csv('https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv',
                      stringsAsFactors = FALSE)
# converting dates to date object
cases_new <- cases_new %>% 
  mutate(date=as.Date(date))
# adding national number of cases and deaths by day
cases_new <- merge(cases_new,cases_new %>% group_by(date) %>% 
                     summarise(cases_natl=sum(cases),
                               deaths_natl=sum(deaths)),
                   by='date')
# converting to log scale
cases_new <- cases_new %>% 
  mutate(cases=case_when(cases==0~-1,cases>0~log(cases)),
         deaths=case_when(deaths==0~-1,deaths>0~log(deaths)),
         cases_natl=case_when(cases_natl==0~-1,
                              cases_natl>0~log(cases_natl)),
         deaths_natl=case_when(deaths_natl==0~-1,
                               deaths_natl>0~log(deaths_natl)))
# keeping only last day of data
cases_new <- cases_new %>% 
  filter(date=='2020-04-20' & !is.na(fips))
# adding policy and ACS data (all 0 because assuming no policy)
preds_df <- cbind(policy_x=0,cases_new %>% 
                    select(fips,cases,deaths,cases_natl,deaths_natl),
                  matrix(rep(0,13*nrow(cases_new)),ncol = 13))
colnames(preds_df)[7:19] <- colnames(tildes_weekly)[7:19]
# merging with case means
preds_df_merged <- merge(preds_df,time_means_weekly,by='fips')
# merging with ACS means
preds_df_merged <- merge(preds_df_merged,ACS_means_weekly,by='fips')
# keeping only one row per county (all rows are the same within counties)
preds_df_merged <- preds_df_merged[!duplicated(preds_df_merged$fips),]
# data frame with differences
preds_df_tildes <- cbind(preds_df_merged$fips,
                         preds_df_merged[,2:19]-preds_df_merged[,20:37])
colnames(preds_df_tildes) <- c('fips',colnames(tildes_weekly)[
  2:ncol(tildes_weekly)])

# making predictions
preds <- cbind(fips=preds_df_tildes$fips,
               pred=predict(fit_weekly,
                            newdata = preds_df_tildes %>% select(-fips)))
write.csv(preds,'predictions.csv',row.names = FALSE)

# retroactive predictions
preds_df_old <- merged_all_weekly
# assuming no policy
preds_df_old$policy_x <- 0
ACS_cols <- colnames(ACS_means_weekly)[2:ncol(ACS_means_weekly)]
preds_df_old[,sapply(ACS_cols,function(x){paste0(x,'_int')})] <- 0
preds_df_old_tildes <- preds_df_old %>% 
  select(policy_x,min_cases,min_deaths,min_cases_natl,min_deaths_natl,
         all_of(sapply(ACS_cols,function(x){
           paste0(x,'_int')
         }))) -
  preds_df_old %>% 
  select(policy_x_mean,min_cases_mean,min_deaths_mean,min_cases_natl,
         min_deaths_natl_mean,all_of(sapply(ACS_cols,function(x){
           paste0(x,'_int_mean')
         })))
preds_old <- cbind(fips=preds_df_old$fips,
                   week=preds_df_old$week,
                   pred=predict(
                     fit_weekly,newdata = preds_df_old_tildes))
write.csv(data.frame(preds_old) %>% filter(week>=0),'predictions_retro.csv',
          row.names = FALSE)
