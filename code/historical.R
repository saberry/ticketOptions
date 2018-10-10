#####################################
### Historical JSON From CFP-RSVP ###
#####################################

performerID = readr::read_csv("data/completeData.csv")

ids = sort(unique(performerID$id))

rm(performerID)

allHistory = lapply(ids, function(x) {
  
  Sys.sleep(.1)
  
  pageID = paste("https://api.dibitnow.com/api/v1/eventPerformers/getEventPerformer?eventPerformerId=", 
                 x, sep = "") 
  
  out = jsonlite::read_json(pageID, simplifyVector = TRUE)
  
  lowerLevelChange = out$priceTrend$lowerLevelPriceChanges
  
  names(lowerLevelChange) = c("lowerLevelPrice", "dateTicks")
  
  lowerLevelChange$name = out$name
  
  lowerLevelChange = reshape2::melt(lowerLevelChange, 
                                    id.vars = c("name", "dateTicks"))
  
  upperLevelChange = out$priceTrend$upperLevelPriceChanges
  
  names(upperLevelChange) = c("upperLevelPrice", "dateTicks")
  
  upperLevelChange$name = out$name
  
  upperLevelChange = reshape2::melt(upperLevelChange, 
                                    id.vars = c("name", "dateTicks"))
  
  out = dplyr::bind_rows(lowerLevelChange, upperLevelChange)
  
  return(out)
})

allHistory = data.table::rbindlist(allHistory)

write.csv(allHistory, "data/allHistory.csv", row.names = FALSE)