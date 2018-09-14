######################
### Data Wrangling ###
######################

# The following operations were conducted on the complete data
# so that columns were re-aligned. Given the position of 
# the Massey variables within the original data, new
# Massey variables caused disruptions in alignment of 
# existing columns. To that end, each pull needed to be
# broken apart, renamed where appropriate, and bound
# back together.

library(dplyr)

completeData = readr::read_csv("completeData_Deprecated.csv")

completeData = completeData %>% 
  mutate(marker = ifelse(eventId == "eventId", seq(1:nrow(.)), NA)) %>% 
  tidyr::fill(., marker, .direction = "down")

markerNames = sort(unique(completeData$marker))

refresh = lapply(markerNames, function(x) {
  
  # browser()
  newDat = completeData %>% 
    dplyr::filter(marker == x) %>% 
    select(-marker)
  
  for(i in 1:length(newDat)) {
    if(is.na(newDat[1, i])) {
     newDat[1, i] = names(newDat)[i] 
    }
  }
  
  
  names(newDat) = newDat[1, ]
  
  newDat = newDat[-1, ]
  
  return(newDat)
  
})

refresh = bind_rows(refresh)

write.csv(refresh, "refreshed.csv", row.names = FALSE)
