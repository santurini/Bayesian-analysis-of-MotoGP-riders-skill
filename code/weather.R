# Library imports ---------------------------------------------------------

library(tidyverse)
library(brms)
library(firatheme)
library(xtable)
library(patchwork)
library(glue)
library(bayesplot)
library(cmdstanr)

setwd("C:/Users/ghina/Desktop/SDS2/SDS2/Project")
mgp = read_rds('./dat/motogp.rds')

# Custom functions --------------------------------------------------------

clean_name <- function(name) paste(str_trim(strsplit(name, ',')[[1]][2]), strsplit(name, ',')[[1]][1])

get_name <- function(x, lb, ub) str_replace_all(str_sub(x, lb, ub), '\\.', ' ')

# Check -------------------------------------------------------------------

fit_weather <- read_rds("./fit/fit_weather.rds")

# ------- MCMC mixing ------- #

pars = c("sd_constructor__Intercept", "sd_constructor:year__Intercept",
         "sd_rider__Intercept", "sd_rider:year__Intercept", "phi")

par(mfrow = c(5, 1))
for(param in pars) trace_plot(param)

rstudioapi::savePlotAsImage("./img_weather/chains.png",width=800,height=1000)

# ------- Running means ------- #

par(mfrow = c(5, 1))
for(param in pars) running_means(param)

rstudioapi::savePlotAsImage("./img_weather/running_means.png",width=800,height=1000)


# ------- Rhat ------- #

rhats <- rhat(fit_weather)
any(rhats[!is.nan(rhats)] > 1.01) # all the chains are converging

mcmc_rhat_hist(rhats, binwidth = 0.000005) + yaxis_text(hjust = 0)+
  labs(
    title = "Rhats"
  ) + theme_light(base_size = 18)

ggsave("./img_weather/diagnostic.png", width = 14, height = 8)

# ------- 2019 posterior predictive check ------- #
# create drivers & constructors in 2019

pred_tab <-
  mgp %>%
  filter(year == 2019) %>%
  group_by(rider, constructor, year) %>% filter(n() > 5) %>%
  select(rider, constructor, year) %>%
  ungroup() %>%
  distinct() %>%
  mutate(weather = "Wet")

# predict proportion of outperformed drivers
pp_tab <- posterior_predict(fit_weather, pred_tab)

# yrep
pred_tab_long <-
  pred_tab %>%
  bind_cols(t(pp_tab) %>% as_tibble(.name_repair = "minimal") %>% set_names(1:36000)) %>%
  pivot_longer(
    cols      = c(-rider, -constructor, -year, -weather),
    names_to  = "sample",
    values_to = "prop_trans"
  ) %>%
  mutate(origin = "simulated")

# y
true_tab_long <-
  mgp %>%
  filter(year == 2019) %>%
  group_by(rider, constructor, year) %>% filter(n() > 5) %>%
  select(rider, constructor, year, weather, prop_trans) %>%
  ungroup() %>%
  mutate(origin = "observed")

ordered_levels <-
  true_tab_long %>%
  group_by(rider) %>%
  summarise(prop = mean(prop_trans)) %>%
  arrange(-prop) %>%
  pull(rider) %>%
  as.character()


bind_rows(pred_tab_long, true_tab_long) %>%
  ggplot(aes(x = prop_trans, fill = origin)) +
  geom_density(alpha = 0.8, bw = .07) +
  facet_wrap(~factor(rider, levels = ordered_levels), scales = "free") +
  xlim(0, 1) +
  theme_fira() +
  scale_fill_fira() +
  theme(legend.position = "top") +
  labs(
    title = "2019 season posterior predictive check",
    x = "Proportion of outperformed drivers",
    y = "",
    fill = ""
  )

ggsave("./img_weather/prop_2019_wet.png", width = 15, height = 12, bg = "white")



# ------- PPC on rank scale ------- #

# finish position distribution to weight observations by
n_races <- length(unique(paste0(mgp$year, "_", mgp$sequence)))
position_table <- table(mgp$position) / n_races
reweigh <- function(rank_sample) {
  # function to resample the ranks based on their value
  sample(rank_sample, prob = position_table[rank_sample], replace = TRUE)
}

pp_ranks <-
  apply(pp_tab, 1, function(x) rank(-x)) %>%
  apply(1, reweigh) %>%
  t() %>%
  as_tibble(.name_repair = "unique") %>%
  mutate(across(.fns = as.integer)) %>%
  set_names(1:36000)

# yrep
pred_rank_long <-
  pred_tab %>%
  bind_cols(pp_ranks) %>%
  pivot_longer(
    cols      = c(-rider, -constructor, -year, -weather),
    names_to  = "sample",
    values_to = "position"
  ) %>%
  mutate(origin = "simulated")

# y
true_rank_long <-
  mgp %>%
  filter(year == 2019) %>%
  group_by(rider, constructor, year) %>% filter(n() > 5) %>%
  select(rider, constructor, year, weather, position) %>%
  mutate(origin = "observed")


bind_rows(pred_rank_long, true_rank_long) %>%
  filter(is.na(sample) | sample %in% sample(36000, 22)) %>%
  ggplot(aes(x = factor(position), fill = origin)) +
  geom_bar(position = position_dodge(preserve = "single")) +
  facet_wrap(~factor(rider, levels = ordered_levels)) +
  theme_fira() +
  scale_fill_fira() +
  theme(legend.position = "top") +
  labs(
    title = "2019 season posterior predictive check",
    x = "Position",
    y = "",
    fill = ""
  )

ggsave("./img_weather/pp_check_rank_2019.png", width = 18, height = 14, bg = "white")


# Inference ---------------------------------------------------------------

# ------- Inference about rider skill ------- #

rider_focus <- c("Fabio Quartararo", "Marc Marquez", "Valentino Rossi", 
                 "Andrea Dovizioso", "Maverick Viñales", "Jorge Lorenzo")

# extract coefficient for rider skill and skill:year
rider_mean <- as_draws_df(fit_weather, variable = "r_rider\\[.+Intercept]", regex = TRUE) %>% select(-.chain, -.iteration)
rider_form <- as_draws_df(fit_weather, variable = "r_rider:year\\[.+Intercept]", regex = TRUE) %>% select(-.chain,-.iteration)

for(i in 1:length(names(rider_mean))-1) names(rider_mean)[i] = get_name(names(rider_mean)[i], 9, -12)
for(i in 1:length(names(rider_form))-1) names(rider_form)[i] = get_name(names(rider_form)[i], 14, -12)

# create tibbles to store information
rider_mean_long <-
  rider_mean  %>%
  pivot_longer(-.draw, names_to = "rider", values_to = "Skill") %>%
  mutate(rider = as_factor(rider))

rider_form_long <-
  rider_form %>%
  pivot_longer(-.draw, names_to = c("rider", "year"), values_to = "Form", names_sep = '_') %>%
  mutate(rider = as_factor(rider), year = as.integer(year))

rider_samples <-
  left_join(rider_form_long, rider_mean_long, by = c("rider", ".draw")) %>%
  mutate(skill_yr = Form + Skill)

rider_skill_summary <-
  rider_samples %>%
  group_by(rider, year) %>%
  summarise(
    est = mean(skill_yr),
    lower = quantile(skill_yr, 0.055),
    upper = quantile(skill_yr, 0.945),
  )


# plot skill per season
plt_skill_trajectory <-
  rider_skill_summary %>%
  ungroup() %>%
  filter(rider %in% rider_focus) %>%
  mutate(rider = fct_reorder(rider, -est)) %>%
  ggplot(aes(x = year, y = est, ymin = lower, ymax = upper)) +
  geom_ribbon(aes(fill = rider), alpha = .2) +
  geom_line(aes(colour = rider)) +
  geom_point(aes(colour = rider)) +
  scale_fill_fira(guide = "none") +
  scale_colour_fira(guide = "none") +
  theme_fira() +
  facet_wrap(~rider) +
  labs(x = "Season", y = "Skill (log odds ratio)", title = "MotoGP rider skill trajectories",
       subtitle = "2016-2021 rider skill,\naccounting for yearly constructor advantage.")


ggsave("./img_weather/plt_skill_trajectories.png", plot = plt_skill_trajectory, width = 12, height = 9, bg = "white")

# plot only for 2021

riders_2021 <- c("Maverick Viñales", "Johann Zarco", "Francesco Bagnaia", "Joan Mir", "Fabio Quartararo", "Alex Rins", "Aleix Espargaro", "Pol Espargaro",
                 "Jack Miller", "Enea Bastianini", "Valentino Rossi", "Miguel Oliveira", "Brad Binder", "Jorge Martin", "Luca Marini",
                 "Iker Lecuona", "Franco Morbidelli", "Lorenzo Savadori", "Takaaki Nakagami", "Danilo Petrucci", "Marc Marquez", "Alex Marquez")

plt_rider_skill_2021 <-
  rider_skill_summary %>%
  ungroup() %>%
  filter(year == 2021, rider %in% riders_2021) %>%
  mutate(rider = fct_reorder(rider, est)) %>%
  ggplot(aes(y = rider, x = est, xmin = lower, xmax = upper)) +
  geom_pointrange(colour = firaCols[3]) +
  theme_fira() +
  labs(title = "2021 MotoGP rider skill",
       subtitle = "Accounting for yearly constructor advantage.",
       x = "Skill (log odds ratio)",
       y = "rider")

ggsave("./img_weather/plt_skill_2021.png", plot = plt_rider_skill_2021, width = 9, height = 9, bg = "white")


# ------- Inference about constructor advantage ------- #

constructors_focus <- c("Repsol Honda Team", "Ducati", "Team SUZUKI ECSTAR", "Yamaha Factory", "Aprilia Racing Team")

constructor_mean <- as_draws_df(fit_weather, variable = "r_constructor\\[.+Intercept]", regex = TRUE) %>% select(-.chain, -.iteration)
constructor_form <- as_draws_df(fit_weather, variable = "r_constructor:year\\[.+Intercept]", regex = TRUE) %>% select(-.chain,-.iteration)

for(i in 1:length(names(constructor_mean))-1) names(constructor_mean)[i] = get_name(names(constructor_mean)[i], 15, -12)
for(i in 1:length(names(constructor_form))-1) names(constructor_form)[i] = get_name(names(constructor_form)[i], 20, -12)

constructor_mean_long <-
  constructor_mean  %>%
  pivot_longer(-.draw, names_to = "constructor", values_to = "Advantage") %>%
  mutate(constructor = as_factor(constructor))

constructor_form_long <-
  constructor_form %>%
  pivot_longer(-.draw, names_to = c("constructor", "year"), values_to = "Form", names_sep = '_') %>%
  mutate(constructor = as_factor(constructor), year = as.integer(year))

constructor_samples <-
  left_join(constructor_form_long, constructor_mean_long, by = c("constructor", ".draw")) %>%
  mutate(advantage_yr = Form + Advantage)

constructor_advantage_summary <-
  constructor_samples %>%
  group_by(constructor, year) %>%
  summarise(
    est = mean(advantage_yr),
    lower = quantile(advantage_yr, 0.055),
    upper = quantile(advantage_yr, 0.945),
  )

plt_advantage_trajectory <-
  constructor_advantage_summary %>%
  ungroup() %>%
  filter(constructor %in% constructors_focus) %>%
  mutate(constructor = fct_relevel(constructor, "Repsol Honda Team", "Ducati", "Team SUZUKI ECSTAR", "Yamaha Factory", "Aprilia Racing Team")) %>%
  ggplot(aes(x = year, y = est, ymin = lower, ymax = upper)) +
  geom_ribbon(aes(fill = constructor), alpha = .2) +
  geom_line(aes(colour = constructor)) +
  geom_point(aes(colour = constructor)) +
  scale_fill_fira(guide = "none") +
  scale_colour_fira(guide = "none") +
  theme_fira() +
  facet_wrap(~constructor) +
  labs(x = "Season", y = "Advantage (log odds ratio)", title = "MotoGP constructor advantage trajectories",
       subtitle = "2016-2021 constructor advantage,\naccounting for yearly rider skill.")

ggsave("./img_weather/plt_advantage_trajectory.png", plot = plt_advantage_trajectory, width = 12, height = 9, bg = "white")


constructors_2021 <- c("Repsol Honda Team", "Ducati", "Team SUZUKI ECSTAR", "Yamaha Factory", "Aprilia Racing Team", "Yamaha Petronas", 
                       "Red Bull KTM Tech 3", "Red Bull KTM Factory Racing", "SKY VR46", "LCR Honda", "Pramac Racing")

constructor_mean_summary <-
  constructor_mean_long %>%
  group_by(constructor) %>%
  summarise(
    est = mean(Advantage),
    lower = quantile(Advantage, 0.055),
    upper = quantile(Advantage, 0.945),
  )

plt_advantage_avg <-
  constructor_mean_summary %>%
  ungroup() %>%
  filter(constructor %in% constructors_2021) %>%
  mutate(constructor = fct_reorder(constructor, est)) %>%
  ggplot(aes(y = constructor, x = est, xmin = lower, xmax = upper)) +
  geom_pointrange(colour = firaCols[1]) +
  theme_fira() +
  labs(title = "Average constructor advantage",
       subtitle = "Accounting for yearly rider skill and constructor form.",
       x = "Advantage (log odds ratio)",
       y = "Constructor")

ggsave("./img_weather/plt_advantage_avg.png", plot = plt_advantage_avg, width = 9, height = 6, bg = "white")



# ------- rider versus constructor contributions ------- #

# random effects standard deviation summary

sfit <- summary(fit_weather, prob = 0.89)

ranef_summary <- rbind(
  "constructor" = sfit$random$constructor,
  "constructor form" = sfit$random$`constructor:year`,
  "rider intercept" = sfit$random$rider[1,],
  "rider slope" = sfit$random$rider[2,],
  "rider form" = sfit$random$`rider:year`
)[, 1:4]

xtable::xtable(round(ranef_summary, 2))

vars = rbind('bike dry var' = colSums(ranef_summary[1:2,]^2)/colSums(ranef_summary[-4,]^2),
             'rider dry var' = colSums(ranef_summary[c(3,5),]^2)/colSums(ranef_summary[-4,]^2),                                                          
             'bike wet var' = colSums(ranef_summary[1:2,]^2)/colSums(ranef_summary^2),
             'rider wet var' = colSums(ranef_summary[3:5,]^2)/colSums(ranef_summary^2))

xtable::xtable(vars)

sim <- data.frame(x$`1`$sd_rider__Intercept, x$`1`$sd_constructor__Intercept, 
                  x$`1`$`sd_constructor:year__Intercept`, x$`1`$`sd_rider:year__Intercept`)
colnames(sim) <- c('rider','constr.','rider form', 'constr. form')
round(cor(sim), 3)


# ------- Overall performance in 2021 ------- #

grid_2021 <-
  mgp %>%
  filter(year == 2021) %>%
  select(rider, constructor, year, weather) %>%
  distinct() %>%
  arrange(constructor)

pp_2021 <- posterior_predict(fit_weather, grid_2021)

pp_2021_summary <-
  pp_2021 %>%
  as_tibble(.name_repair = "minimal") %>%
  set_names(grid_2021$rider) %>%
  pivot_longer(everything(), names_to = "rider") %>%
  group_by(rider) %>%
  summarise(est = mean(value), lower = quantile(value, 0.045), upper = quantile(value, 0.955)) %>%
  left_join(grid_2021) %>%
  select(rider, constructor, performance = est, lower, upper) %>%
  arrange(-performance)

xtable::xtable(pp_2021_summary, digits = 3)

pp_2021_summary %>%
  ungroup() %>%
  filter(rider %in% riders_2021) %>%
  mutate(rider = fct_reorder(rider, performance)) %>%
  ggplot(aes(y = rider, x = performance, xmin = lower, xmax = upper)) +
  geom_pointrange(colour = firaCols[1]) +
  theme_fira() +
  labs(title = "Overall rider performance 2021",
       subtitle = "Accounting for rider skill and constructor form.",
       x = "Performance",
       y = "Rider")


ggsave("./img_weather/plt_performance_2021.png", width = 6, height = 9, bg = "white")


# Counter factual example --------------------------------------------------

# in a wet race in 2018, how likely is it that Dovizioso in a Honda beats Marquez in a Ducati?

dovizioso_yamaha <- posterior_predict(fit_weather, tibble(
  year = 2018,
  constructor = "Yamaha Factory",
  rider = "Andrea Dovizioso",
  weather = 'Wet'
))

marquez_EG <- posterior_predict(fit_weather, tibble(
  year = 2018,
  constructor = "EG 0,0 Marc VDS",
  rider = "Marc Marquez",
  weather = 'Wet'
))

delta <- marquez_EG - dovizioso_yamaha

ggplot(tibble(d = delta), aes(x = d)) +
  geom_density(fill = firaCols[4], alpha = 0.8) +
  geom_vline(xintercept = mean(delta)) +
  theme_fira() +
  labs(
    title = "Counterfactual prediction",
    subtitle = "Marquez in Marc VDS versus Dovizioso in Yamaha",
    x = "Marquez-VDS advantage",
    y = "Density"
  )

ggsave("./img_weather/plt_counterfactual.png", width = 9, height = 5, bg = "white")




