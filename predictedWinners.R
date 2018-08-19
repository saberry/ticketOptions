## Predicted Game Winners #

library(rvest)

initialHTML = read_html("https://www.oddsshark.com/ncaaf/computer-picks")

winners = html_table(initialHTML)

captions = html_nodes(initialHTML, "caption") %>% 
  html_text

names(winners) = captions

https://www.oddsshark.com/ncaaf/computer-picks