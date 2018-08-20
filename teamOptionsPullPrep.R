##################################
### Team Options Pull and Prep ###
##################################

library(dplyr); library(jsonlite); library(tidyr)

source("injuryScrape.R")

source("masseyComps.R")

source("masseyRatings.R")

source("predictedWinners.R")

# Thankfully, we have this really nice json file!

# optionsDat = jsonlite::read_json("https://api.cfp-rsvp.com/api/teams/getTeams?eventId=2", 
#                            simplifyVector = TRUE)

optionsDat = jsonlite::read_json("https://api.dibitnow.com/api/v1/eventPerformers/getEventPerformers?eventId=1", 
                                 simplifyVector = TRUE)

# To keep track of date and time, we will add Sys.time. 

optionsDat$dateTime = Sys.time()

# One of the columns, teamTiers, has a nested list structure. We need to spread
# it out, collapse it down, and then bind the individual data frames.

# spreadData = lapply(1:nrow(optionsDat), function(x) {
#   
#   res = optionsDat$teamTiers[[x]] %>% 
#     reshape::melt(.) %>% 
#     reshape::cast(., value ~ tierShortName + variable) %>% 
#     select(-value) %>% 
#     summarize_all(sum, na.rm = TRUE)
#   
#   return(res)
# }) %>% 
#   data.table::rbindlist(., fill = TRUE)

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



# After spread that column out into separate columns, we need to column bind
# them back into the original data.

optionsDat = cbind(optionsDat, spreadData) %>% 
  select(-eventPerformerCategory, -eventPerformerExperiences, 
         -priceTrend)

# Since we are doing this continually, we will append new data into
# the same file.

injury = injuryScrape()

masseyCompsDat = masseyComps()

masseyRatingsDat = masseyRatings()

winners = predictedWinners()

optionsDat = optionsDat %>% 
  left_join(., masseyCompsDat, by = c("name" = "Team")) %>% 
  left_join(., masseyRatingsDat, by = c("name" = "Team")) %>% 
  left_join(., injury, by = c("name" = "team")) %>% 
  mutate(computerPick = ifelse(.$name %in% winners$computerPicks, 1, 0), 
         publicPick = ifelse(.$name %in% winners$publicPicks, 1, 0))

write.table(x = optionsDat, 
            file = "C:/Users/berry2006/Documents/projects/teamOptionPricing/teamOptionPricing/optionsDatNew.csv", append = TRUE, 
            na = "", sep = ",", row.names = FALSE)


# Everything below here was testing js stuff -- none of it worked! #

# read_html("https://www.cfp-rsvp.com/home?allTeams=1") %>% 
#   html_nodes("app-root")
#   
# ct = v8()
# 
# read_html(ct$eval(test))
# 
# 
# read_html("https://www.cfp-rsvp.com/team?id=135") %>% 
#   html_nodes(xpath = "/*[@id='allTeams']")
# 
# 
# url <- "https://www.cfp-rsvp.com/home?allTeams=1"
# 
# writeLines(sprintf("var page = require('webpage').create();
# page.open('%s', function () {
#                    console.log(page.content); //page source
#                    phantom.exit();
#                    });", url), con="scrape.js")
# 
# system("C:\Users\sberry5\phantomjs-2.1.1-windows\bin\phantomjs.exe scrape.js > scrape.html")
# 
# readLines("https://www.cfp-rsvp.com/home?allTeams=1")
# 
# 
# link <- 'https://food.list.co.uk/place/22191-brewhemia-edinburgh/'
# #Read the html page content and extract all javascript codes that are inside a list
# emailjs <- read_html(link) %>% html_nodes('li') %>% html_nodes('script') %>% html_text()
# # Create a new v8 context