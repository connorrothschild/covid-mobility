library(readr)
library(dplyr)

# reading ACS data
ACS_econ <- read.csv('../viz/data/demographics/ACS_ECONOMIC_2018.csv',
                     stringsAsFactors = FALSE)
cols_econ <- ACS_econ[1,]
ACS_econ <- ACS_econ[-1,]
ACS_econ$GEO_ID <- substr(ACS_econ$GEO_ID,10,14)

ACS_social <- read.csv('../viz/data/demographics/ACS_SOCIAL_2018.csv',
                       stringsAsFactors = FALSE)
cols_social <- ACS_social[1,]
ACS_social <- ACS_social[-1,]
ACS_social$GEO_ID <- substr(ACS_social$GEO_ID,10,14)

# new data frames with no raw estimates or MOE 
cols_econ_type <- c('O','O',as.character(sapply(
  colnames(ACS_econ)[3:ncol(ACS_econ)],function(x){
    n <- nchar(x)
    m <- ifelse(substr(x,n-1,n-1)=='P',n-1,n)
    substr(x,m,n)
  }
)))
ACS_econ_p <- ACS_econ[,cols_econ_type %in% c('O','PE')]

cols_social_type <- c('O','O',as.character(sapply(
  colnames(ACS_social)[3:ncol(ACS_social)],function(x){
    n <- nchar(x)
    m <- ifelse(substr(x,n-1,n-1)=='P',n-1,n)
    substr(x,m,n)
  }
)))
ACS_social_p <- ACS_social[,cols_social_type %in% c('O','PE')]

# converting to numeric
ACS_econ_p <- cbind(
  ACS_econ_p[,1:2],
  as.matrix(sapply(ACS_econ_p[,3:ncol(ACS_econ_p)],as.numeric)))
ACS_social_p <- cbind(
  ACS_social_p[,1:2],
  as.matrix(sapply(ACS_social_p[,3:ncol(ACS_social_p)],as.numeric)))

# removing "bad" columns (number not in 0-100 or all NAs)
cols_econ_good <- c(TRUE,TRUE,apply(
  ACS_econ_p[,3:ncol(ACS_econ_p)],2,
  function(x){
    ifelse(
      min(x,na.rm = TRUE)<0 | max(x,na.rm = TRUE)>100 | mean(is.na(x))==1,
      FALSE,TRUE)
  }))
ACS_econ_p <- ACS_econ_p[,cols_econ_good]
ACS_econ_p <- na.omit(ACS_econ_p)

cols_social_good <- c(TRUE,TRUE,apply(
  ACS_social_p[,3:ncol(ACS_social_p)],2,
  function(x){
    ifelse(
      min(x,na.rm = TRUE)<0 | max(x,na.rm = TRUE)>100 | mean(is.na(x))==1,
      FALSE,TRUE)
  }))
ACS_social_p <- ACS_social_p[,cols_social_good]
ACS_social_p <- na.omit(ACS_social_p)

# merging econ and social data frames
ACS_all_p <- merge(ACS_econ_p,ACS_social_p,by=c('GEO_ID','NAME'))
# adding total population, per capita income, mean travel time to work
ACS_all <- merge(ACS_all_p,merge(
  ACS_econ %>% select(GEO_ID,NAME,DP03_0088E,DP03_0025E),
  ACS_social %>% select(GEO_ID,NAME,DP05_0033E),by=c('GEO_ID','NAME')),
  by=c('GEO_ID','NAME'))

write.csv(ACS_all,'../viz/data/ACS_econ_social.csv',row.names = FALSE)