##################################
###       Team Options         ### 
###     Pull, Prep, Write      ###
##################################

# The following packages will be needed for everything within this file
# and the sourced functions.

if (!require("pacman")) install.packages("pacman")

pacman::p_load(dplyr, jsonlite, tidyr, readr, rvest, taskscheduleR)

library(dplyr); library(jsonlite); library(tidyr)

# Sourcing the following files will run the appropriate functions.
# Before sourcing, however, you will need to specify the appropriate locations
# for your folder structure. Uncomment the code on lines 20 through 24 to run
# everything on your own machine.

# pathToMyFolder = "path/to/files/"
# source(paste(pathToMyFolder, "injuryScrape.R", sep = "))
# source(paste(pathToMyFolder, "masseyComps.R", sep  = "))
# source(paste(pathToMyFolder, "masseyRatings.R", sep  = "))
# source(paste(pathToMyFolder, "predictedWinners.R", sep = "))


source("C:/Users/sberry5/Documents/research/ticketOptions/injuryScrape.R")

source("C:/Users/sberry5/Documents/research/ticketOptions/masseyComps.R")

source("C:/Users/sberry5/Documents/research/ticketOptions/masseyRatings.R")

source("C:/Users/sberry5/Documents/research/ticketOptions/predictedWinners.R")


# First, we will get the options data from CFP-RSVP. The information that we want
# is sitting a json file.

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
  

# Since we are doing this continually, we will append new data into
# the same file.

write.table(x = optionsDat, 
            file = "C:/Users/sberry5/Documents/research/ticketOptions/completeData.csv", append = TRUE, 
            na = "", sep = ",", row.names = FALSE)


# completeData2 %>% 
#   select(eventId:UL_price, Conf:X59, masseyConference:masseyEL, n, computerPick, publicPick) %>% 
#   write.csv(., "tofix.csv", row.names = FALSE)
