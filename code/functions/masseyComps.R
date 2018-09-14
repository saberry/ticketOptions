##########################
### Massey Comparisons ###
##########################

masseyComps = function() {
  
  skipLines = readLines("https://www.masseyratings.com/cf/compare.csv")
  
  allComps = readr::read_csv("https://www.masseyratings.com/cf/compare.csv", 
                             skip = (which(grepl("^Team", skipLines)) - 1))
  
  return(allComps)
  
}

# library(irr)
# 
# iccRatings = allComps %>% 
#   select(ARG:SOR)
# 
# icc(iccRatings, model = "oneway")
# 
# kappam.fleiss(iccRatings)
