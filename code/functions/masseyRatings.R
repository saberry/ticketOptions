######################
### Massey Ratings ###
######################

masseyRatings = function() {
  
  library(jsonlite)
  
  masseyPage = fromJSON("https://www.masseyratings.com/ratejson.php?s=300937&sub=11604", 
                        flatten = FALSE)
  
  columnNames = masseyPage$CI$title
  
  ratingsTable = matrix(unlist(masseyPage$DI), nrow = length(masseyPage$DI), 
                        ncol = length(unlist(masseyPage$DI[[1]])), 
                        byrow = TRUE) %>% 
    data.frame()
  
  ratingsTable = select(ratingsTable, 
                        -X2, -X3, 
                        -X5, -X6)
  
  columnNames[which(is.na(columnNames))] = c("Conference", "ConfRecord", 
                                             "ConfRating", "ConfPower", 
                                             "ConfOff", "ConfDef", 
                                             "ConfSoS", "ConfSSF", 
                                             "ConfEW", "ConfEL")
  
  columnNames = paste("massey", columnNames, sep = "")
  
  columnNames[columnNames == "masseyTeam"] = "Team"
  
  names(ratingsTable) = columnNames
  
  return(ratingsTable)
  
}