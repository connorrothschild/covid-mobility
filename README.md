

# Mobility and Predictors of Movement During COVID-19

### Team Stay-at-Home: Connor Rothschild, Rebecca Francis, Mario Paciuc, and Kyran Adams

## [**NOTE: Find our finished product as a Shiny application, found here.**](https://kyranadams.shinyapps.io/covid-mobility/)

## **Introduction**

The COVID-19 virus has had an unprecedented effect on the extent to which Americans move around the country. Recommendations by local, state and federal governments have urged citizens to stay home, practice social distancing, and limit travel.

However, the ability to stay home depends on various inequalities between communities. For example, the [New York Times](https://www.nytimes.com/2020/04/05/opinion/coronavirus-social-distancing.html) has explored the relationship between socioeconomic factors and mobility and concluded that those with higher socioeconomic status were able to socially distance earlier than those with lower socioeconomic status. 

Despite the wide implementation of these regulations limiting mobility, we know little about the effectiveness of stay-at-home orders and similar laws. As of this writing, [95% of citizens are under stay-at-home orders](https://www.businessinsider.com/us-map-stay-at-home-orders-lockdowns-2020-3), but researchers have not yet done a rigorous analysis to explore if such orders are effective at reducing travel.

In approaching these issues, we asked the following questions:

- How has mobility changed during the era of COVID-19?
- What characteristics are predictors of a community’s ability to socially distance?

- Taking into account a certain county’s characteristics, can we make robust predictions about future mobility?
- Are ‘stay-at-home orders’ and similar laws effective at reducing the distance citizens travel? How do their effectiveness differ by implementation and stringency?



## **Data**

Mobility data was taken from the [Descartes Labs COVID 19](https://github.com/descarteslabs/DL-COVID-19) GitHub repository. The dataset used ([DL-us-m50_index.csv](https://github.com/descarteslabs/DL-COVID-19/blob/master/DL-us-m50_index.csv)) provides daily mobility (dating back to March 1) at the county level relative to a county-specific baseline established before the spread of the coronavirus. The dataset was then modified so that each value represents a percent change from the baseline. Data of the daily number of coronavirus cases and deaths was taken from the New York Times. We also included data from the American Community Survey (ACS) 2018 5-year survey for social, economic, and demographic data for each county in the United States.  Finally, we pulled data regarding state policies that encourage or mandate social distancing, such as stay-at-home orders.[ This data](https://docs.google.com/spreadsheets/d/1zu9qEWI8PsOI_i8nI_S29HDGHlIp2lfVMsGxpQ5tvAQ/edit) allowed us to explore the effectiveness of stay-at-home orders and similar regulations. 



## **Process**

Our project is the result of contributions at every step of the data science pipeline, from data cleaning, to exploratory visualization, to regression and analysis. Our week 1 contributions, which can be found in our [week 1 README here](https://github.com/connorrothschild/covid-mobility/blob/master/README-files/README-Week1.md), focused almost exclusively on exploratory data analysis. We explored which socioeconomic and demographic factors might influence a community’s ability to ‘social distance.’ 

We then invested a great deal of time in conducting more rigorous analyses of the trends we found in week 1. We researched various tools for causal inference to determine a) the factors that limit stay-at-home orders effectiveness and b) the effectiveness of stay-at-home orders more generally. We built a fixed effects model with the within estimator, allowing us to model mobility as a function of policy, socioeconomic variables, and the prevalence of the virus. 

Because mobility and the number of cases are likely to be highly confounded, a fixed effects model is appropriate, as it controls for omitted variable bias by removing factors that stay constant through time.

 Since then, we have dedicated our time to visualizing both our insights and our process. We have done so through an interactive Shiny dashboard which allows the user to explore how mobility has changed since the onset of COVID-19, how this trend has unfolded in an individual county, and how this trend relates to various demographic and socioeconomic factors. The dashboard is mobile-responsive, intuitive, and employs various techniques to present readable, effective, and ethical visualizations.



## **Tools** 

 Our team is interdisciplinary and benefits from a wide variety of tools and skill sets. We primarily utilized R for merging, cleaning, and analyzing data. We created interactive data visualizations (which can be accessed [here](https://connorrothschild.github.io/covid-mobility/viz/), [here](https://connorrothschild.github.io/covid-mobility/viz/line-chart), and [here](https://connorrothschild.github.io/covid-mobility/viz/predictions/)) using JavaScript, HTML and CSS. Our final output, which captures our thought process chronologically, is an app built in R Shiny. This R Shiny dashboard includes two visualizations made using the JavaScript library D3.js, highlighting the interdisciplinary nature of our work.



## **Takeaways**

 Our model shows that the rapidly increasing number of coronavirus cases throughout the country contributes significantly to a reduction in mobility. The impact that stay-at-home orders have on mobility varies across counties. For example, our model shows that stay-at-home orders are more effective in counties with a higher proportion of people in their low twenties. On the other hand, counties with higher poverty rates are less likely to reduce their mobility as a result of a stay-at-home order. Overall, however, counties seem to benefit from stay-at-home orders: if all orders were retracted, we would expect to see an increase in mobility in 87% of counties. Lawmakers in multiple states are considering relaxing their regulations, and our model allows us to envision how such action would change how people behave. 





## **Installation Instructions**

The app is hosted on the website: https://kyranadams.shinyapps.io/covid-mobility/ 

Code can be found on GitHub: https://github.com/connorrothschild/covid-mobility

Please post [issues on GitHub](https://github.com/connorrothschild/covid-mobility/issues/).

To run this app locally on your machine, download R or RStudio and run the following commands once to set up the environment:

```R
install.packages(c("shinydashboard", "shiny", "highcharter", "ggplot2", "plotly", "dplyr", "data.table", "DT", "tidyr", "ggrepel", "shinycssloaders", "shinythemes", "SwimmeR"))
```

You may now run the shiny app with just one command in R:

``` R
shiny::runGitHub("covid-mobility", "connorrothschild", subdir="viz")
```



## **The Team**

**Connor Rothschild**

In addition to the early stages of data cleaning, I built out the interactive visualizations using D3.js, HTML, and CSS.

**Mario Paciuc**

I tested various iterations of the fixed effects model and tuned it to improve its accuracy. 

**Rebecca Francis**

I worked on processing the demographic data and produced the descriptive demographic and case graphs.

**Kyran Adams**

I produced the initial R Shiny application and various interactive data visualizations using plotly and ggplot.



Again, you can find our final output [here](https://kyranadams.shinyapps.io/covid-mobility/). Thank you!