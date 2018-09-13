#####################
### Injury Scrape ###
#####################

injuryScrape = function() {
  
  library(rvest)
  
  injuryPage = read_html("http://www.donbest.com/ncaaf/injuries/")
  
  teamNames = html_nodes(injuryPage, "td.statistics_table_header") %>% 
    html_text()
  
  columnNames = html_nodes(injuryPage, "th.statistics_cellrightborder") %>% 
    html_text() %>% 
    unique()
  
  test = html_table(injuryPage, fill = TRUE) %>% 
    `[[`(2)
  
  test = test[-1, ] %>% 
    select(X1:X5)
  
  names(test) = columnNames
  
  test$team = test$Status
  
  test$team[!(test$Date %in% teamNames)] = ""
  
  test$team[which(test$team == "" & test$Date != "")] = NA
  
  test = tidyr::fill(test, team, .direction = "down") %>% 
    dplyr::filter(Date != "Date", Date != "", 
           grepl("^[A-Z]", .$Date) != TRUE) %>% 
    group_by(team) %>% 
    summarize(n = n())
  
  return(test)
  
}
