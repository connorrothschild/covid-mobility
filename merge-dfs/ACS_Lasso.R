library(readr)
library(dplyr)
library(glmnet)

# reading ACS data
ACS <- read.csv('../viz/data/demographics/ACS_econ_social.csv',
                stringsAsFactors = FALSE)

# reading mobility data
mobility <- read.csv('../viz/data/mobility/county/pre_post_7days.csv',
                     stringsAsFactors = FALSE)

# only interested in post-policy data in this case
mobility <- mobility %>% 
  filter(pre_post=='Post')

# merging mobility and ACS data
merged <- merge(ACS,mobility %>% select(fips,average_mobility_std),
                by.x='GEO_ID',by.y='fips')
# lost 24 counties in merge

# feature matrix and response variable
X <- as.matrix(merged %>% select(-c(GEO_ID,NAME,average_mobility_std)))
y <- merged$average_mobility_std

# Lasso regression
set.seed(123)
lasso <- cv.glmnet(X,y,alpha = 1,nfolds = 5)
coefs <- as.matrix(lasso$glmnet.fit$beta)[
  ,which(lasso$glmnet.fit$lambda==lasso$lambda.min)]
# variables chosen by Lasso with optimal lambda
vars <- names(coefs)[coefs!=0]
X_lasso <- as.matrix(data.frame(X) %>% select(all_of(vars)))
# writing 66 chosen variables to csv
write.csv(as.data.frame(cbind(merged[,c('GEO_ID','NAME')],X_lasso)),
          '../viz/data/demographics/ACS_lasso_big.csv',
          row.names = FALSE)

# PCA on chosen features to further reduce number of features
pca <- prcomp(X_lasso,center = TRUE,scale. = TRUE)
# 17 principal components account for 71% of the variance
ACS_lasso_pca <- cbind(merged %>% select(GEO_ID,NAME),
                       pca$x[,1:17])
write.csv(ACS_lasso_pca,'../viz/data/demographics/ACS_lasso_pca.csv',
          row.names = FALSE)

# choosing larger-than-optimal lambda to reduce number of variables to 15
coefs_few <- as.matrix(lasso$glmnet.fit$beta)[,which(lasso$nzero==15)]
vars_few <- names(coefs_few)[coefs_few!=0]
# removing columns which are (or should be) perfectly collinear
vars_few <- vars_few[!vars_few %in% c('DP03_0002PE','DP03_0118PE')]
X_lasso_small <- as.matrix(data.frame(X) %>% select(all_of(vars_few)))
# writing 15 chosen variables to csv
write.csv(as.data.frame(cbind(merged[,c('GEO_ID','NAME')],X_lasso_small)),
          '../viz/data/demographics/ACS_lasso_small.csv',
          row.names = FALSE)