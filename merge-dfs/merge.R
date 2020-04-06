library(tidyverse)

## list filepaths
filenames = list.files(path="../data/", full.names=TRUE)

## lapply https://towardsdatascience.com/using-r-to-merge-the-csv-files-in-code-point-open-into-one-massive-file-933b1808106
all <- lapply(filenames, function(i){
  
  ## read in each tsv
  i <- read.table(i,
             header = TRUE,
             sep = "\t",
             fill = TRUE)
  
  ## mutate regions to be character
  i <- i %>%
    mutate(Region = as.character(Region))

  ## grab the state for each grouping. This will be the first row (and the next 5 rows)
  state <- i[[1]][[1]]

  ## append state to be its own column for each grouping
  i <- i %>%
    mutate(State = state) %>%
    select(Region, State, Category, everything())
  
})

## rbind together
merged <- do.call(rbind.data.frame, all)

## write
write.csv(merged, "../final.csv")
