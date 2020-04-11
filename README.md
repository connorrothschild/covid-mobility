## Introduction

The COVID-19 virus has had an unprecedented effect on the extent to which Americans move around the country. Recommendations by local, state and federal governments have urged citizens to stay home, practice social distancing, and limit travel.

However, the ability to stay home depends on various inequalities between communities. For example, the [New York Times](https://www.nytimes.com/2020/04/05/opinion/coronavirus-social-distancing.html) has explored the relationship between socioeconomic factors and mobility and concluded that those with higher socioeconomic status were able to socially distance earlier than those with lower socioeconomic status.

Given those results, questions arise such as:

- *What other characteristics are predictors of the ability for a community to socially distance?* 
- *Taking into account a certain county’s characteristics, can we make robust predictions about future mobility?*
- *Are ‘stay-at-home orders’ and similar laws effective at reducing the distance citizens travel? How do their effectiveness differ by implementation and stringency?*

## Data and Methods

In order to answer these questions, we sought data regarding county characteristics related to mobility during COVID-19, as well as a host of demographic and socioeconomic variables.

  Mobility data was taken from Google’s COVID-19 Community Mobility Reports. These reports provide the daily percentage change in mobility at the county level relative to a baseline established prior to the spread of the coronavirus. Specifically, the baseline is the median value of mobility (which incorporates both number of visits and length of stay) from January 3, 2020 to February 6, 2020. A separate baseline is calculated for each day of the week. Furthermore, the change in mobility is divided into six categories: workplace, retail and recreation, grocery and pharmacy, parks, transit stations, and residential. In our initial analyses, we are considering each category separately and averaging across the last seven days of available data (March 23 to March 29).

We also included data from the American Community Survey (ACS) 2018 5-year survey. The ACS contains data profiles of social, economic, and demographic data for each county in the United States. To explore the relationship between workplace mobility and some basic county demographic characteristics, we employed five main ACS variables: median household income, mean commute time, percent employed in the service jobs, percent employed in sales and office jobs, and percent employed in transport and production jobs. These variables gave us insight into how COVID-19 has particularly affected mobility to the workplace.

Finally, we pull data regarding state policies that encourage or mandate social distancing, such as stay-at-home orders. [This data](https://docs.google.com/spreadsheets/d/1zu9qEWI8PsOI_i8nI_S29HDGHlIp2lfVMsGxpQ5tvAQ/edit) will allow us to explore the effectiveness of stay-at-home orders and similar regulations. By exploring trends in mobility before and after the implementation of such laws, we can determine *what kind* of social distancing laws work, and which don’t.

We also created visualizations to explore the distribution of mobility throughout the country relative to the baseline.

![final-states](./README-files/final-states.jpg)![final-county](./README-files/final-county.jpg)

We’ve also created an [interactive version](https://connorrothschild.github.io/covid-mobility/viz/) of this map, which allows us to explore these trends temporally. The visualization allows the user to select a given date to explore mobility at a given time, and the tooltip that appears on hover allows users to explore mobility for a given county:

[![map-slider](/Users/connorrothschild/Desktop/Projects/Other/covid-mobility/README-files/map-slider.gif)](https://connorrothschild.github.io/covid-mobility/viz/)



## Conclusions





## Impact

Our research will help us understand the effectiveness of stay-at-home orders at reducing travel, the effectiveness of social distancing on reducing transmission, and the various factors that may influence one’s ability to ‘distance.’ If we have a better understanding of when and why people socially distance, that lawmakers can address and account for these issues when creating policies. For example, if we know that communities without access to grocery stores are much less likely to socially distance, then laws might want to address this rather than ignore it.

Understanding communities’ disparate ability to socially distance is crucial to understand which communities are most vulnerable to the virus. Such insights may be able to inform a policy response, so that more resources can be allocated to protecting these communities. The insights we gather from this analysis could inform broader discussions of equity, the unequal impact of seemingly indiscriminate viruses, and socioeconomic inequality more broadly. 

## Future Plans

We intend to build a regression model which predicts a county’s change in mobility (relative to the baseline) based on various demographic and socioeconomic variables. Because the ACS data provides hundreds of variables, many of which are highly correlated, careful feature extraction and dimensionality reduction will be crucial to creating a robust model. Methods such as principal component analysis and Lasso regression will be combined with expert knowledge from previous studies to obtain a smaller set of potential features. Cross-validation can then be used to determine the best model. In addition to making predictions, a model such as random forest will also provide feature importances, quantifying the impact that each feature has on mobility. 

Once such a model has been created, the effect of government regulations on mobility can be assessed. For example, the difference between expected and actual change in mobility can be compared across counties with varying regulations. Having accounted for the demographic and socioeconomic characteristics of each county, these comparisons are less likely to be affected by confounding variables and will hopefully allow lawmakers to determine the appropriate course of action. 