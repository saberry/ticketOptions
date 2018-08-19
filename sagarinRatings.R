#######################
### Sagarin Ratings ###
#######################

sagarinRatings = function() {
  
  sagarinPage = read_html("http://sagarin.com/sports/cfsend.htm")
  
  sagarinRatings = html_nodes(sagarinPage, "pre") %>% 
    html_text %>% 
    `[[`(3)
  
  sagarinRows = stringr::str_extract_all(sagarinRatings, "\\r\\n.*\\r\\n")
  
}