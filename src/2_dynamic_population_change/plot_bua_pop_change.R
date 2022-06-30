suppressPackageStartupMessages({
  require(tidyverse)
  require(ggplot2)
  require(sf)
})

if(interactive()){
  .args <-  c(
    "data/Britain_TilePopulation/tile_fb_pop_adjusted_absolute.csv", 
    "data/Britain_TilePopulation/tile_baseline_mye_pop_proportion.csv",
    "data/lookups/tile_to_bua.csv", 
    "data/config/period_lines.rds", 
    "data/config/period_rectangles_inf.rds", 
    "output/figs/bua_pop_change.rds"
  )
  FOCUS_HOUR_WINDOW = 16
} else {
  .args <- commandArgs(trailingOnly = T)
  FOCUS_HOUR_WINDOW <- as.numeric(Sys.getenv("FOCUS_HOUR_WINDOW"))
}

fb_pop <- read_csv(.args[1]) %>% 
  filter(date_time <= as.POSIXct("2021-03-10"))
baseline_pop <- read_csv(.args[2])
tile_to_bua <- read_csv(.args[3])
period_lines <- read_rds(.args[4])
period_rectangles <- read_rds(.args[5])

bua_baseline_oa_pop <- baseline_pop %>% 
  left_join(tile_to_bua, by = c('quadkey' = 'quadkey')) %>% 
  drop_na(bua_code) %>% 
  filter(hour == !!FOCUS_HOUR_WINDOW) %>% 
  group_by(bua_name) %>% 
  summarise(population = sum(population, na.rm = T), .groups = 'drop') %>% 
  arrange(-population)

bua_pop_dynamic <- fb_pop %>% 
  filter(hour == !!FOCUS_HOUR_WINDOW) %>% 
  left_join(tile_to_bua, by = c('quadkey' = 'quadkey')) %>% 
  drop_na(bua_name) %>% 
  group_by(date_time, bua_name) %>% 
  summarise(n_crisis_adj = sum(n_crisis_adj, na.rm = T), .groups = 'drop') %>% 
  left_join(bua_baseline_oa_pop, by = 'bua_name') %>% 
  drop_na(population) %>% 
  pivot_longer(!c(date_time, bua_name), names_to = 'type', values_to = 'value') %>% 
  mutate(type = ifelse(type == 'population', 'Static\nPopulation', 'Dynamic\nPopulation'),
         bua_name = factor(bua_name, levels = c(bua_baseline_oa_pop$bua_name)))

plot_buas <- function(bua_names){
  
  p <-  bua_pop_dynamic %>% 
    filter(bua_name %in% bua_names) %>% 
    ggplot() + 
    period_rectangles +
    period_lines +
    geom_path(aes(x = date_time, y = value, linetype = type), size = 0.21) + 
    facet_wrap(~bua_name, scales = 'free') + 
    scale_y_continuous(labels = scales::unit_format(unit = "M", scale = 1e-6, accuracy = 0.01)) + 
    theme_classic() + 
    theme(legend.title = element_blank(),
          axis.title.x = element_blank(),
          strip.background=element_rect(colour="white", 
                                        fill="white")) + 
    ylab('Population')
  
  return(p)
  
}

p_top_buas <- plot_buas(bua_baseline_oa_pop$bua_name[1:6])
p_all_buas <- plot_buas(bua_baseline_oa_pop$bua_name[1:20])

ggsave("output/figs/bua_population_change_all.png",
       p_all_buas,
       width=17, height=9, units="in")

write_rds(p_top_buas, tail(.args, 1))

p_data_perc <- bua_pop_dynamic %>% 
  filter(type == "Dynamic\nPopulation",
         bua_name %in% bua_baseline_oa_pop$bua_name[1:20]) %>% 
  left_join(bua_baseline_oa_pop, by = "bua_name") %>% 
  mutate(value_perc = ((value - population) / population),
         bua_name = factor(bua_name, levels = bua_baseline_oa_pop$bua_name))
  
p_perc_all_buas <- p_data_perc %>% 
  ggplot() + 
  period_rectangles +
  period_lines +
  geom_path(aes(x = date_time, y = value_perc), size = 0.21) + 
  facet_wrap(~bua_name, scales = 'free') + 
  scale_y_continuous(labels = scales:::percent) + 
  theme_classic() + 
  theme(legend.title = element_blank(),
        axis.title.x = element_blank(),
        strip.background=element_rect(colour="white", 
                                      fill="white")) + 
  ylab('Population')

ggsave("output/figs/bua_population_change_perc_all.png",
       p_perc_all_buas,
       width=17, height=9, units="in")
