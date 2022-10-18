# Library imports ---------------------------------------------------------

library(tidyverse)
library(brms)
library(firatheme)
library(xtable)
library(patchwork)
library(glue)
library(cmdstanr)

setwd("C:/Users/ghina/Desktop/SDS2/SDS2/Project")
mgp = read_rds('./dat/motogp.rds')

# Custom functions --------------------------------------------------------

clean_name <- function(name) paste(str_trim(strsplit(name, ',')[[1]][2]), strsplit(name, ',')[[1]][1])

get_name <- function(x, lb, ub) str_replace_all(str_sub(x, lb, ub), '\\.', ' ')

# Importing data ----------------------------------------------------------

df1 = read.csv('./dat/races.csv')
df2 = read.csv('./dat/weather_condition.csv')

df1 = df1[df1$year > 2015, -c(2, 4, 5, 6, 9, 11, 12, 13, 14, 15)] # remove unused cols 
df1$classified = ifelse(df1$position < 0, 'not classified', 'classified') # add column to filter finished races

df2 = df2[df2$year > 2015, c(1, 2, 5)] # add the weather conditions

df = merge(x = df1, y = df2, by = c("year", "sequence"), all.x = TRUE)
df = df[with(df, order(year, sequence)),]

for(i in 1:dim(df)[1]){
  
  if(df[i, 4] %in% c("Ducati Team", "Mission Winnow Ducati", "Ducati Lenovo Team")) df[i, 4] = 'Ducati'
  if(df[i, 4] %in% c("Movistar Yamaha MotoGP", "Monster Energy Yamaha MotoGP")) df[i, 4] = "Yamaha Factory"
  if(df[i, 4] %in% c("Monster Yamaha Tech 3", "Yamalube Yamaha Factory Racing", "Petronas Yamaha SRT")) df[i, 4] = "Yamaha Petronas"
  if(df[i, 4] %in% c("Avintia Racing", "Reale Avintia Racing", "Hublot Reale Avintia Racing", "Hublot Reale Avintia",
                      "Esponsorama Racing", "SKY VR46 Esponsorama", "Avintia Esponsorama", "SKY VR46 Avintia")) df[i, 4] = "SKY VR46"
  if(df[i, 4] %in% c("OCTO Pramac Yakhnich", "OCTO Pramac Racing", "Alma Pramac Racing")) df[i, 4] = "Pramac Racing"
  if(df[i, 4] %in% c("Aspar Team MotoGP", "Pull & Bear Aspar Team", "Pull&Bear Aspar Team")) df[i, 4] = "Angel Nieto Team"
  if(df[i, 4] %in% c("Aprilia Racing Team Gresini", "Aprilia Factory Racing")) df[i, 4] = "Aprilia Racing Team"
  if(df[i, 4] %in% c("LCR Honda CASTROL", "LCR Honda IDEMITSU")) df[i, 4] = "LCR Honda"
  if(df[i, 4] == "Estrella Galicia 0,0 Marc VDS") df[i, 4] = "EG 0,0 Marc VDS"
  if(df[i, 4] == "Tech 3 KTM Factory Racing") df[i, 4] = "Red Bull KTM Tech 3"
  if(df[i, 4] %in% c("Team HRC", "Honda HRC", "Team Honda HRC", "HRC Honda Team")) df[i, 4] = "Repsol Honda Team"
  
}

row.names(df) <- NULL
names(df)[names(df) == 'track'] <- 'weather'
names(df)[names(df) == 'rider_name'] <- 'rider'
names(df)[names(df) == 'team_name'] <- 'constructor'
df$rider = sapply(df$rider, FUN = clean_name, USE.NAMES = F)

write_rds(df, 'motogp.rds')

# Processing data ---------------------------------------------------------

mgp <- read_rds("./motogp.rds")

# convert to factors
mgp <- mgp %>% mutate(
  constructor = as_factor(constructor),
  rider = as_factor(rider),
  classified  = as_factor(classified),
  weather = as_factor(weather)
)


mgp <-
  df %>%
  group_by(year, sequence) %>%
  filter(classified == "classified") %>% # keep only fnishing races
  mutate(
    position_prop = (n() - position) / (n() - 1),   # POC     
    prop_trans = (position_prop * (n() - 1) + 0.5) / n() # smoothed POC
  ) %>%
  ungroup() %>%
  select(-classified)

write_rds(mgp, "./motogp.rds")

# EDA ---------------------------------------------------------------------

motogp <- read_rds("./dat//motogp.rds")

# ------- finishing positions ------- #

pos = ggplot(mgp, aes(x = factor(position))) +
  geom_bar(fill = 'darkcyan') +
  theme_fira() +
  labs(
    title = "Distribution of finishing positions",
    subtitle = "MotoGP (2016-2021)",
    x = "Finishing position",
    y = "Count"
  )

ggsave("./img/eda.png", width = 12, height = 10)


wet = ggplot(mgp, aes(x = factor(weather))) +
  geom_bar(aes(y = (..count..)/sum(..count..)), fill = c('lightgreen', 'darkgreen')) +
  theme_fira() +
  labs(
    title = "Distribution of weather",
    subtitle = "MotoGP (2016-2021)",
    x = "Finishing position",
    y = "Count"
  )


ggarrange(pos, wet,
          ncol = 2, nrow = 1)

# ------- basic plot ------- #

motogp %>%
  filter(rider %in% c("Andrea Dovizioso", "Marc Marquez", "Jack Miller")) %>%
  ggplot(aes(x = factor(position), fill = rider)) +
  geom_bar(position = position_dodge(preserve = "single")) +
  theme_fira() +
  scale_fill_brewer(palette = "Set1") +
  labs(
    x = "Finishing position",
    y = "Count",
    title = "Different riders finishing positions",
    subtitle = "Conditional on finishing the race",
    fill = ""
  ) +
  theme(legend.position = "top") +
  facet_wrap(~year)

ggsave("./img/finish_rider_names.png", width = 12, height = 9)

# ------- density plot ------- #

motogp %>%
  filter(rider %in% c("Andrea Dovizioso", "Marc Marquez", "Jack Miller")) %>%
  ggplot(aes(x = prop_trans, fill = rider)) +
  geom_density(alpha = 0.5, bw = 0.1) +
  theme_fira() +
  scale_fill_brewer(palette = "Set1") +
  labs(
    x = "Smoothed proportion of outperformed riders",
    y = "Density",
    title = "Different riders results",
    subtitle = "Proportion of riders outperformed",
    fill = ""
  ) +
  theme(legend.position = "top", axis.text.x = element_text(angle = 45, vjust = 0.85)) +
  facet_wrap(~year)

ggsave("./img/finish_rider_names_prop.png", width = 9, height = 6)


# Models ------------------------------------------------------------------

fit_basic <- brm(
  formula = prop_trans ~ 0 + (1 | rider) + (1 | rider:year) + (1 | constructor) + (1 | constructor:year),
  family  = Beta(),
  data    = mgp,
  backend = 'cmdstanr',
  control = list(adapt_delta = 0.9),
  chains  = 4,
  cores   = 4,
  warmup = 1000,
  iter    = 10000, 
  save_pars = save_pars(all = TRUE)
)

summary(fit_basic)
write_rds(fit_basic, "./fit/fit_basic.rds")
fit_basic <- read_rds("./fit/fit_basic.rds")

# weather model
fit_weather <- brm(
  formula = prop_trans ~ 0 + (1 + weather | rider) + (1 | rider:year) + (1 | constructor) + (1 | constructor:year),
  family  = Beta(),
  data    = mgp,
  backend = "cmdstanr",
  control = list(adapt_delta = 0.95),
  chains  = 4,
  cores   = 4,
  warmup  = 1000,
  iter    = 10000,
  save_pars = save_pars(all = TRUE)
)

summary(fit_weather)
write_rds(fit_weather, "./fit/fit_weather.rds")


# Model comparison --------------------------------------------------------

options(mc.cores = 4)

fit_basic = read_rds('./fit/fit_basic.rds') %>% add_criterion('loo', moment_match=TRUE, reloo = TRUE)
fit_weather = read_rds('./fit/fit_weather.rds') %>% add_criterion('loo', moment_match=TRUE, reloo = TRUE)

loo_results <- loo_compare(
  fit_basic,
  fit_weather,
  model_names = c("Basic", "Weather")
)

loo_results = read_rds('./fit/loo_results.rds')
xtable::xtable(loo_results)
write_rds(loo_results, "./fit/loo_results.rds")

