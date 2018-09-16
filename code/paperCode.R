if (!require("pacman")) install.packages("pacman")

pacman::p_load(dplyr, ggplot2, stringr, mgcv,
               broom, caret, GGally, readr, knitr)

initialData = readr::read_csv("data/frozen/optionsDat.csv")

previousYearRank = readr::read_csv("data/frozen/massey2017YearEnd.csv")

allHistory = read.csv("data/frozen/allHistory.csv")

previousYearRank = previousYearRank %>% 
  mutate(Team = as.character(Team), 
         Team = gsub("St$", "State", Team))

initialData = initialData %>% 
  mutate(name = gsub("\\.|,", "", name)) %>% 
  left_join(., previousYearRank, by = c("name" = "Team")) %>% 
  group_by(name) %>% 
  arrange(masseyYearEnd)

top25PrevNames = previousYearRank %>% 
  arrange(as.numeric(masseyYearEnd)) %>% 
  head(25) %>% 
  select(Team)

top25InitialPrices = initialData %>% 
  slice(., 1L) %>% 
  dplyr::filter(masseyYearEnd < 26) %>% 
  ungroup() %>% 
  mutate(name = factor(name, levels = .$name)) %>% 
  select(masseyYearEnd, UL_price, LL_price, name) %>% 
  mutate(average_price = (as.numeric(UL_price) + as.numeric(LL_price)) / 2) %>% 
  tidyr::gather(type, value, -name, -masseyYearEnd) %>% 
  arrange(name) %>% 
  ggplot(., aes(name, as.numeric(value), color = type)) +
  geom_point(size = 3, alpha = .5) +
  theme_minimal() +
  scale_color_brewer(palette = "Dark2")

completeData = readr::read_csv("data/frozen/completeData.csv") %>% 
  mutate(day = gsub("\\s.*", "", .$dateTime))

top10Ever = unique(completeData$name[as.numeric(completeData$AP) < 11])

top25Ever = unique(completeData$name[as.numeric(completeData$AP) < 26])

currentRankOrder = completeData %>% 
  group_by(name) %>% 
  arrange(dateTime) %>% 
  slice(n()) %>% 
  select(name, AP) %>% 
  arrange(AP)

endOfDay = completeData %>% 
  mutate(day = gsub("\\s.*", "", .$dateTime)) %>% 
  group_by(name, day) %>% 
  slice(n())

volatile = completeData %>% 
  group_by(name, day) %>%
  slice(n()) %>%
  group_by(name) %>% 
  mutate(lagLL = dplyr::lag(LL_price), 
         lagUL = dplyr::lag(UL_price)) %>% 
  mutate(volatilityLL = ((LL_price / lagLL) - 1), 
         volatilityUL = ((UL_price / lagUL) - 1)) %>% 
  summarize(sdLL = sd(volatilityLL, na.rm = TRUE), 
            sdUL = sd(volatilityUL, na.rm = TRUE), 
            volLL = sdLL * 15.937, 
            volUL = sdUL * 15.937, 
            meanLL = mean(LL_price, na.rm = TRUE), 
            meanUL = mean(UL_price, na.rm = TRUE)) %>% 
  arrange(desc(volLL), desc(volUL))


# Results

## Previous Year-end Rank and Early Prices

top25InitialPrices + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1), 
        axis.title.x = element_blank(), 
        axis.title.y = element_blank(), 
        legend.position = "bottom", 
        legend.title = element_blank())

## Ranking Correlations

completeData %>% 
  select(AP, SAG, MAS, USA, FPI, Mean, Median) %>% 
  na.omit() %>% 
  GGally::ggcorr(., label = TRUE, 
                 low = "#4575b4", mid = "#ffffbf", 
                 high = "#d73027")

## Top 25 Trends

top25TrendsData = completeData %>% 
  mutate(Rank = as.numeric(Rank), 
         dateTime = lubridate::ymd_hms(dateTime), 
         name = factor(name, levels = currentRankOrder$name)) %>% 
  dplyr::filter(name %in% top25Ever) %>% 
  select(dateTime, UL_price, LL_price, name) %>% 
  tidyr::gather(key, value, -name, -dateTime) %>% 
  arrange(name, dateTime)

levels(top25TrendsData$name) = gsub("\\s", "\n", levels(top25TrendsData$name))

ggplot(top25TrendsData, aes(dateTime, as.numeric(value), color = key, group = key)) + 
  geom_path(na.rm = TRUE, linejoin = "mitre") + 
  facet_wrap(~ name) +
  theme_minimal() +
  theme(axis.title.x = element_blank(), 
        axis.title.y = element_blank(), 
        legend.position = "bottom", 
        legend.title = element_blank()) +
  scale_color_brewer(palette = "Dark2")

## Volatility

volatile %>% 
  filter(name %in% top25Ever) %>% 
  mutate(name = factor(name, levels = currentRankOrder$name)) %>% 
  select(volLL, volUL, name) %>% 
  tidyr::gather(key = key, value = value, -name) %>% 
  ggplot(., aes(name, value, color = key)) + 
  geom_point(alpha = .5) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1), 
        axis.title.x = element_blank(), 
        legend.position = "bottom", 
        legend.title = element_blank()) +
  scale_y_continuous(name = "Volatility") +
  scale_color_brewer(palette = "Dark2")


changes = allHistory %>% 
  select(name, variable, value) %>% 
  distinct() %>% 
  group_by(name) %>% 
  summarize(Count = n()) %>% 
  arrange(desc(Count)) %>% 
  as.data.frame() %>% 
  head(25) %>% 
  mutate(name = factor(name, levels = .$name))

ggplot(changes, aes(name, Count)) + 
  geom_point() + 
  scale_x_discrete(breaks = changes$name) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1), 
        axis.title.x = element_blank(), 
        legend.position = "bottom", 
        legend.title = element_blank()) +
  scale_color_brewer(palette = "Dark2")

historyData = allHistory %>% 
  filter(allHistory$name %in% top25Ever) %>%
  mutate(name = factor(name, levels = currentRankOrder$name)) %>% 
  group_by(name, variable) %>% 
  mutate(obs = 1:n())

levels(historyData$name) = gsub("\\s", "\n", levels(historyData$name))

ggplot(historyData, aes(obs, value, color = variable)) + 
  geom_path() +
  facet_wrap(~name) +
  theme_minimal() +
  theme(axis.title.y = element_blank(), 
        axis.title.x = element_blank(), 
        legend.position = "bottom", 
        legend.title = element_blank()) +
  scale_color_brewer(palette = "Dark2")


#### Explaining Volatility

predictors = completeData %>% 
  select(Mean, n, name, dateTime, masseyRecord, masseySoS) %>% 
  mutate(wins = as.numeric(stringr::str_extract(masseyRecord, "^[0-9]+"))) %>% 
  group_by(name) %>% 
  slice(n())

modDatVol = left_join(volatile, predictors, by = "name")

modLLVol = gam(volLL ~ s(Mean) + wins + s(n) + s(masseySoS),
               data = modDatVol)

knitr::kable(tidy(modLLVol))

knitr::kable(tidy(modLLVol, parametric = TRUE))

par(mfrow = c(2, 2))

plot.gam(modLLVol, all.terms = TRUE, se = FALSE)


#### Explaining Current Prices

currentPriceModDat = completeData %>% 
  select(Mean, n, name, dateTime, masseyRecord, masseySoS, UL_price, LL_price) %>% 
  mutate(wins = as.numeric(stringr::str_extract(masseyRecord, "^[0-9]+"))) %>% 
  group_by(name) %>% 
  slice(n())

modLLPrice = gam(LL_price ~ s(Mean) + wins + s(n)+ s(masseySoS),
                 data = currentPriceModDat)

knitr::kable(tidy(modLLPrice))

knitr::kable(tidy(modLLPrice, parametric = TRUE))

par(mfrow = c(2, 2))

plot.gam(modLLPrice, all.terms = TRUE, se = FALSE)

## Model Testing

modDatVol = na.omit(modDatVol)

set.seed(1001)

trainIndex = createDataPartition(modDatVol$volLL, 
                                 p = .50, list = FALSE, times = 1)

trainDatVol = modDatVol[trainIndex, ]

testDatVol  = modDatVol[-trainIndex, ]

trainModVol = train(volLL ~ Mean + wins + n + masseySoS,
                    data = trainDatVol, method = "gam")

testModVol = predict(trainModVol, data = testDatVol)

knitr::kable(postResample(pred = testModVol, obs = testDatVol$volLL))

