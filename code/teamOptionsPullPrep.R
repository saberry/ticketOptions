##################################
###       Team Options         ### 
###     Pull, Prep, Write      ###
##################################

# The following packages will be needed for everything within this file
# and the sourced functions.

if (!require("pacman")) install.packages("pacman")

pacman::p_load(dplyr, jsonlite, tidyr, readr, rvest, taskscheduleR, data.table)

# All of the functions for this file are sourced from the functions folder. 
# If you provide the sourceFunction with a character vector for the path on your
# machine (e.g., "C:/Users/yourName/Documents/work/"), you will be able to run
# sourceFunction and bring the functions in all at once.

sourceFunction = function(path = NULL) {
  if(is.null(path)) {
    source("C:/Users/sberry5/Documents/research/ticketOptions/code/functions/injuryScrape.R")
    
    source("C:/Users/sberry5/Documents/research/ticketOptions/code/functions/masseyComps.R")
    
    source("C:/Users/sberry5/Documents/research/ticketOptions/code/functions/masseyRatings.R")
    
    source("C:/Users/sberry5/Documents/research/ticketOptions/code/functions/predictedWinners.R")
  } else {
    source(paste(path, "injuryScrape.R", sep = ""))
    
    source(paste(path, "masseyComps.R", sep  = ""))
    
    source(paste(path, "masseyRatings.R", sep  = ""))
    
    source(paste(path, "predictedWinners.R", sep = ""))
  }
}

sourceFunction()

# First, we will get the options data from CFP-RSVP. The information that we want
# is sitting in a json file.

optionsDat = jsonlite::read_json("https://api.dibitnow.com/api/v1/eventPerformers/getEventPerformers?eventId=1", 
                                 simplifyVector = TRUE)

# To keep track of date and time for each pull, we will add Sys.time. 

optionsDat$dateTime = Sys.time()

# One of the columns, teamTiers, has a nested list structure. We need to spread
# it out, collapse it down, and then bind the individual data frames.

spreadData = lapply(1:nrow(optionsDat), function(x) {
  
  res = optionsDat$eventPerformerExperiences[[x]] %>% 
    select(eventPerformerId, 
           experienceId, experienceShortName, 
           initialPrice, maxPurchaseQuantity, price, 
           lastModifiedDateTime) %>% 
    tidyr::gather(., key = key, value = value, 
                  -experienceShortName) %>% 
    reshape::cast(., value ~ experienceShortName + key) %>% 
    select(-value) %>% 
    tidyr::gather(.) %>% 
    na.omit(.) %>% 
    tidyr::spread(., key = key, value = value) %>% 
    mutate_at(vars(-contains("lastModifiedDateTime")), as.numeric) %>%
    mutate_at(vars(contains("lastModifiedDateTime")),
              lubridate::as_datetime)
  
  return(res)
}) %>% 
  data.table::rbindlist(., fill = TRUE)

# After spreading that column out into separate columns, we need to column bind
# them back into the original data.

optionsDat = cbind(optionsDat, spreadData) %>% 
  select(-eventPerformerCategory, -eventPerformerExperiences, 
         -priceTrend)

optionsDat = optionsDat %>% 
  mutate(name = gsub("\\.|,", "", name))

# Now, we can use our sourced functions and finally join everything together.

injury = injuryScrape()

masseyCompsDat = masseyComps()

masseyCompsDat = masseyCompsDat %>% 
  mutate(Team = as.character(Team), 
         Team = gsub("St$", "State", Team))

masseyRatingsDat = masseyRatings()

masseyRatingsDat = masseyRatingsDat %>% 
  mutate(Team = as.character(Team), 
         Team = gsub("St$", "State", Team))

winners = predictedWinners()

optionsDat = optionsDat %>% 
  left_join(., injury, by = c("name" = "team")) %>% 
  mutate(computerPick = ifelse(.$name %in% winners$computerPicks, 1, 0), 
         publicPick = ifelse(.$name %in% winners$publicPicks, 1, 0)) %>% 
  left_join(., masseyRatingsDat, by = c("name" = "Team")) %>% 
  left_join(., masseyCompsDat, by = c("name" = "Team"))


# Before doing anything else, we want to put this data into our runningTab data.

writeTableInput = function(path = NULL) {
  if(is.null(path)) {
    write.table(x = optionsDat, 
                file = "C:/Users/sberry5/Documents/research/ticketOptions/data/runningTab.csv", append = TRUE, 
                na = "", sep = ",", row.names = FALSE)
  } else {
    write.table(x = optionsDat, 
                file = paste(path, "data/runningTab.csv", sep = ""), append = TRUE, 
                na = "", sep = ",", row.names = FALSE)
  }
}

# The writeTableInput function behaves the same way as sourceFunctions; just
# supply the appropriate path and it will go.

writeTableInput()

  
# We want to replace the old past table with the new one, so we will bring in all
# of the past data, bind, and rewrite.

pastData = readr::read_csv("C:/Users/sberry5/Documents/research/ticketOptions/data/completeData.csv")

optionsDat = data.table::rbindlist(list(pastData, optionsDat), fill = TRUE)

writeCSVInput = function(path = NULL) {
  if(is.null(path)) {
    write.csv(optionsDat, "C:/Users/sberry5/Documents/research/ticketOptions/data/completeData.csv")
  } else {
    write.csv(optionsDat, file = paste(path, "data/completeData.csv", sep = ""))
  }
}

writeCSVInput()
