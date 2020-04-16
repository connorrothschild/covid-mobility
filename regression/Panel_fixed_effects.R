library(readr)
library(dplyr)
library(janitor)

# reading mobility data
mobility <- read.csv('../data/mobility/county/county-data-long.csv',
                     stringsAsFactors = FALSE)

# reading ACS data
ACS <- read.csv('../data/demographics/ACS_lasso_small.csv',
                stringsAsFactors = FALSE)
ACS_cols <- colnames(ACS)[3:ncol(ACS)]

# reading case data
cases <- read.csv('https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv',
                  stringsAsFactors = FALSE)

# converting dates to date objects
cases <- cases %>% 
  mutate(date=as.Date(date))

# reading policy data
policy <- read.csv('../data/policies/covid_us_state_policies.csv',
                   stringsAsFactors = FALSE)
policy <- policy %>% 
  janitor::clean_names() %>% 
  select(state,state_of_emergency)

# joining mobility and policy data
mobility_policy <- merge(mobility,policy,by.x='admin1',by.y='state')
# converting to date objects
mobility_policy <- mobility_policy %>% 
  mutate(date=as.Date(date),
         state_of_emergency=as.Date(state_of_emergency,format='%m/%d/%Y'))
# adding variables relating policy date to current date
mobility_policy <- mobility_policy %>% 
  mutate(policy = case_when(date > state_of_emergency ~ 1, 
                            date <= state_of_emergency ~ 0),
         pre7 = case_when((state_of_emergency - date >= 0) & 
                            (state_of_emergency - date < 7) ~ 1,
                          (state_of_emergency - date < 0) |
                            (state_of_emergency - date >= 7) ~ 0))
# keeping only days after seven days before policy
mobility_policy <- mobility_policy %>% 
  filter(policy==1 | pre7==1)

# adding case data
mobility_policy_cases <- merge(mobility_policy,cases,by=c('date','fips'),
                               all.x = TRUE)
# converting NA cases/deaths by county to 0
mobility_policy_cases$cases[is.na(mobility_policy_cases$cases)] <- 0
mobility_policy_cases$deaths[is.na(mobility_policy_cases$deaths)] <- 0
# adding national number of cases/deaths
# adding national number of cases/deaths
cases_national <- cases %>% group_by(date) %>% 
  summarise(cases_nat=sum(cases),deaths_nat=sum(deaths))
mobility_policy_cases <- merge(mobility_policy_cases,cases_national,
                               by='date')

# adding ACS data
df_all <- merge(mobility_policy_cases %>% 
                  select(-c(country_code,admin_level,county,state)),
                ACS,by.x='fips',by.y='GEO_ID') %>% 
  arrange(fips,date)
# lost a few counties in the merge (not in ACS data)

# adding interaction between policy and ACS variables
df_all <- cbind(df_all,
                df_all$policy*(df_all %>% select(all_of(ACS_cols))))
colnames(df_all)[(ncol(df_all)-14):ncol(df_all)] <- sapply(
  ACS_cols,function(x){paste0(x,'_int')}
)

# finding county means across time and joining to dataset
time_means <- df_all %>% group_by(fips) %>% 
  summarise(mobility_mean=mean(value_std),policy_mean=mean(policy),
            cases_mean=mean(cases),deaths_mean=mean(deaths))
df_all <- merge(df_all,time_means,by='fips')
# adding national means
df_all['cases_nat_mean'] <- mean(df_all$cases_nat)
df_all['deaths_nat_mean'] <- mean(df_all$deaths_nat)
# adding interaction between policy mean and ACS variables
df_all <- cbind(df_all,
                df_all$policy_mean*(df_all %>% 
                  select(all_of(ACS_cols))))
colnames(df_all)[(ncol(df_all)-14):ncol(df_all)] <- sapply(
  ACS_cols,function(x){paste0(x,'_int_mean')}
)

# difference between actual and mean values
tilde <- df_all %>% 
  select(c(value_std,policy,cases,deaths,cases_nat,deaths_nat,
           sapply(ACS_cols,function(x){paste0(x,'_int')}))) -
  df_all %>% 
  select(c(mobility_mean,policy_mean,cases_mean,deaths_mean,
           cases_nat_mean,deaths_nat_mean,
           sapply(ACS_cols,function(x){paste0(x,'_int_mean')})))

# regression
fit <- lm(value_std~.,data = tilde)