suppressPackageStartupMessages({
  require(tidyverse)
  require(ggplot2)
  require(sf)
})

if(interactive()){
  .args <-  c("data/Britain_TilePopulation/tile_fb_pop_adjusted_absolute.csv",
              "data/Britain_TilePopulation/tile_baseline_mye_pop_proportion.csv",
              "data/cases/cases_bua.csv",
              "data/lookups/tile_to_bua.csv",
              "data/config/period_lines.rds", 
              "data/config/period_rectangles_inf.rds", 
              "output/figs/case_rate_difference_bua.png")
  FOCUS_HOUR_WINDOW = 16
  PLOT_CUTOFF_DATE <- as.Date("2021-03-31")
} else {
  .args <- commandArgs(trailingOnly = T)
  FOCUS_HOUR_WINDOW <- as.numeric(Sys.getenv("FOCUS_HOUR_WINDOW"))
  PLOT_CUTOFF_DATE <- as.Date(Sys.getenv("PLOT_CUTOFF_DATE"))
}

fb_pop <- read_csv(.args[1], col_types = cols()) %>% 
  filter(date_time <= as.POSIXct(PLOT_CUTOFF_DATE))

tile_pop <- read_csv(.args[2], col_types = cols())

cases_bua <- read_csv(.args[3], col_types = cols()) %>% 
  rename(bua_name = name, bua_code = code) %>% 
  filter(date <= as.Date(PLOT_CUTOFF_DATE))

tile_bua <- read_csv(.args[4], col_types = cols())

period_lines <- read_rds(.args[5])
period_rectangles <- read_rds(.args[6])

bua_static_pop <- tile_bua %>% 
  left_join(tile_pop, by = 'quadkey') %>% 
  filter(hour == FOCUS_HOUR_WINDOW) %>% 
  group_by(bua_name) %>% 
  summarise(population = sum(population, na.rm = T), .groups = 'drop')

bua_dynamic_pop <- fb_pop %>% 
  filter(quadkey %in% tile_bua$quadkey) %>% 
  filter(hour == FOCUS_HOUR_WINDOW) %>% 
  left_join(tile_bua, by = 'quadkey') %>% 
  mutate(date = as.Date(date_time)) %>% 
  group_by(bua_name, date) %>% 
  summarise(n_crisis_adj = sum(n_crisis_adj, na.rm = T), .groups = 'drop')

p_data <- cases_bua %>% 
  left_join(bua_static_pop, by = 'bua_name') %>% 
  left_join(bua_dynamic_pop, by = c('date', 'bua_name')) %>% 
  drop_na(n_crisis_adj) %>% 
  mutate(rate_static = (cases / population) * 100000,
         rate_dynamic = (cases / n_crisis_adj) * 100000,
         rate_difference = ((rate_dynamic - rate_static) / rate_static) * 100)

p_data$bua_name <- factor(p_data$bua_name, levels = bua_static_pop %>% arrange(-population) %>% pull(bua_name))

first_lockdown <- as.Date('2020-03-23')
second_lockdown <- as.Date('2020-10-31')
tier_4 <- as.Date('2020-12-19')

high_pop_names <- c(
  "Greater London BUA",
  "West Midlands BUA",
  "Greater Manchester BUA",
  "West Yorkshire BUA",
  "Liverpool BUA",
  "Tyneside BUA"
)

p_bua_cases <- p_data %>% 
  filter(bua_name %in% high_pop_names) %>% 
  mutate(date = as.POSIXct(date)) %>% 
  ggplot() + 
  period_lines +
  period_rectangles +
  geom_hline(aes(yintercept = 0), size = 0.3, color = "red") + 
  geom_path(aes(x = date, y = rate_difference), size = 0.3) + 
  facet_wrap(~bua_name, scales = 'free_y', ncol = 3) + 
  theme_classic() + 
  ylab('Cases rate difference (%)') + 
  theme(axis.title.x = element_blank())

ggsave(tail(.args, 1),
       p_bua_cases,
       width=10, height=5, units="in")
