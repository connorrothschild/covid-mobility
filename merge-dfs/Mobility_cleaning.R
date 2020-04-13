library(readr)
library(dplyr)

# reading mobility data
mobility <- read.csv('../data/county-data-wide.csv',row.names = 1,
                     stringsAsFactors=FALSE)

# 'Illinois' is spelled 'inots'
mobility$State[mobility$State=='inots'] <- 'Illinois'
# 'Iowa' is spelled 'lowa'
mobility$State[mobility$State=='lowa'] <- 'Iowa'
mobility$Region[mobility$Region=='lowa County'] <- 'Iowa County'
# 'Hawaii' is spelled 'Haweill'
mobility$State[mobility$State=='Haweill'] <- 'Hawaii'
# 'Rhode Island' is spelled 'Rhode |sland'
mobility$State[mobility$State=='Rhode |sland'] <- 'Rhode Island'
# Virginia cities don't have 'city'
mobility$Region[mobility$State=='Virginia'] <- sapply(
  mobility$Region[mobility$State=='Virginia'],function(x){
    ifelse(length(strsplit(x,' ')[[1]])>=2 & 
             strsplit(x,' ')[[1]][length(strsplit(x,' ')[[1]])]=='County',
           x,paste0(x,' city'))
  })

# checking there are only 6 rows for each fips
View(mobility %>% group_by(fips) %>% summarise(count=n()) %>% 
       filter(count>6))
# 5 fips codes are repeated:
#   24005 (Baltimore/Baltimore County (MD))
#   51059 (Fairfax/Fairfax County (VA))
#   51067 (Franklin/Franklin County (VA))
#   51159 (Richmond/Richmond County (VA))
#   51161 (Roanoke/Roanoke County (VA))
fips_many <- c(24005,51059,51067,51159,51161)
# will look at these fips codes in ACS data to determine which to keep

# reading ACS data
ACS <- read.csv('ACS_ECONOMIC_2018.csv',stringsAsFactors=FALSE)
ACS <- ACS[-1,]
# getting fips codes in same format
ACS$GEO_ID <- as.numeric(substr(ACS$GEO_ID,10,14))
View(ACS %>% filter(GEO_ID %in% fips_many) %>% select(GEO_ID,NAME))
# the ones with "county" are the ones that are correct

# Baltimore city: 24510
# Fairfax city: 51600
# Franklin city: 51620
# Richmond city: 51760
# Roanoke city: 51770
# fixing these fips codes in mobility data
mobility$fips[mobility$Region=='Baltimore' & 
                mobility$State=='Maryland'] <- 24510 
mobility$fips[mobility$Region=='Fairfax' & 
                mobility$State=='Virginia'] <- 51600
mobility$fips[mobility$Region=='Franklin' &
                mobility$State=='Virginia'] <- 51620
mobility$fips[mobility$Region=='Richmond' &
                mobility$State=='Virginia'] <- 51760
mobility$fips[mobility$Region=='Roanoke' &
                mobility$State=='Virginia'] <- 51770

# looking for counties with no fips code
View(mobility %>% filter(is.na(fips)) %>% group_by(State,Region) %>% 
       summarise(count=n()))
# 355 of them; will get their fips code from ACS data

# putting county name in same format as that of ACS data
mobility <- mobility %>% 
  mutate(county_state = mapply(function(county,state){
    paste0(county,', ',state)
  },mobility$Region,mobility$State))
# joining mobility and ACS data by county name
merged <- merge(mobility,ACS,by.x='county_state',by.y='NAME',all.x=TRUE)
# replacing NAs by fips code from ACS data
merged$fips[is.na(merged$fips)] <- merged$GEO_ID[is.na(merged$fips)]
mobility <- merged %>% select(colnames(mobility))
View(mobility %>% filter(is.na(fips)) %>% group_by(State,Region) %>% 
       summarise(count=n()))
# there are still 32 counties with no fips code
# many in Alaska have weird names: borough, municipality, etc.
# some have data in Region column
# have to deal with these on a case-by-case basis so will simply remove them for now
mobility <- mobility %>% select(-county_state) %>% 
  filter(!is.na(fips))
write.csv(mobility,'../data/mobility_cleaned.csv',row.names=FALSE)
