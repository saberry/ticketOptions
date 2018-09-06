############################
### Massey Previous Year ###
############################

library(jsonlite)

masseyPage = fromJSON("https://www.masseyratings.com/teamjson.php?t=11604&s=295489", 
                      flatten = FALSE)

columnNames = masseyPage$CI$title

ratingsTable = matrix(unlist(masseyPage$DI), nrow = length(masseyPage$DI), 
                      ncol = length(unlist(masseyPage$DI[[1]])), 
                      byrow = TRUE) %>% 
  data.frame()

ratingsTable = select(ratingsTable, 
                      X1, X2)

names(ratingsTable) = c("masseyYearEnd", "Team")

write.csv(ratingsTable, "massey2017YearEnd.csv", row.names = FALSE)
