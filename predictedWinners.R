## Predicted Game Winners #



predictedWinners = function(x) {
  
  library(rvest)
  
  initialHTML = read_html("https://www.oddsshark.com/ncaaf/computer-picks")
  
  winners = html_table(initialHTML)
  
  winnerShape = lapply(winners, function(x) select(x, ATS))
  
  winnerShape = lapply(winnerShape, function(x) data.frame(computerPick = x[2,], 
                                                           publicPick = x[3,]))
  
  winnerShape = data.table::rbindlist(winnerShape)
  
  captions = html_nodes(initialHTML, "caption") %>% 
    html_text
  
  winnerShape$game = captions
  
  winnerShape$computerPick = gsub("\\s.*", "", winnerShape$computerPick) 
  
  winnerShape$publicPick = gsub("\\s.*", "", winnerShape$publicPick)
  
  winnerShape$team1 = stringr::str_extract(winnerShape$game, "\\D+(?= Matchup)")
  
  winnerShape$team1 = sub("\\s", "", winnerShape$team1)
  
  winnerShape$team1Whole = stringr::str_extract(winnerShape$team1, "(?<=\\s).*")
  
  winnerShape$team1Abbv = stringr::str_extract(winnerShape$team1, "^\\S+(?=\\s[A-Z][a-z]+)")
  
  winnerShape$team2 = stringr::str_extract(winnerShape$game, "(?<=Matchup ).*")
  
  winnerShape$team2Whole = stringr::str_extract(winnerShape$team2, "(?<=\\s).*")
  
  winnerShape$team2Abbv = stringr::str_extract(winnerShape$team2, "^\\S+(?=\\s[A-Z][a-z]+)")
  
  computerPicks = c(winnerShape$team1Whole[winnerShape$computerPick == winnerShape$team1Abbv],
                    winnerShape$team2Whole[winnerShape$computerPick == winnerShape$team2Abbv])
  
  publicPicks = c(winnerShape$team1Whole[winnerShape$publicPick == winnerShape$team1Abbv],
                  winnerShape$team2Whole[winnerShape$publicPick == winnerShape$team2Abbv])
  
  picks = list(computerPicks = computerPicks, 
               publicPicks = publicPicks)
  
  return(picks)
}
