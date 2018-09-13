completeData = completeData %>% 
  mutate(marker = ifelse(eventId == "eventId", seq(1:nrow(.)), NA)) %>% 
  tidyr::fill(., marker, .direction = "down")


markerNames = sort(unique(completeData$marker))

refresh = lapply(markerNames, function(x) {
  newDat = completeData %>% 
    dplyr::filter(marker == x)
  
  names(newDat) = newDat[1, ]
  
  newDat = newDat[-1, ]
  
  return(newDat)
  
})

refresh = data.table::rbindlist(refresh, fill = TRUE)
