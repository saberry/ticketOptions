########################################
### Data Version and Reconcilliation ###
########################################

library(dplyr)

# Given the various computer and data source changes, we have a few data files
# that need checked and bound together.

originalData = readr::read_csv("optionsDat.csv")

# Since the api changed, we need to select key variables, 
# so that we can get them bound to subsequent files.

originalData = originalData %>% 
  select(name, dateTime, initialPrice, price, LL_maxPurchaseQuantity, LL_price, 
         UL_maxPurchaseQuantity, UL_price)


updatedData = readr::read_csv("optionsDatNew.csv")

updateV2Data = readr::read_csv("optionsDatV2.csv")

finalData = bind_rows(updateV2Data, updatedData, originalData)

finalData = finalData %>% 
  mutate(name = gsub("\\.|,", "", name))

write.csv(finalData, "completeData.csv", row.names = FALSE)
