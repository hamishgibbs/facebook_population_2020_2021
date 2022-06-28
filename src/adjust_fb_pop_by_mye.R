suppressPackageStartupMessages({
  require(tidyverse)
})

if(interactive()){
  .args <-  c("data/Britain_TilePopulation/tile_fb_population.csv",
              "data/Britain_TilePopulation/tile_baseline_mye_pop_proportion.csv",
              "data/Britain_TilePopulation/tile_fb_pop_adjusted_absolute.csv")
} else {
  .args <- commandArgs(trailingOnly = T)
}

fb_pop <- read_csv(.args[1], col_types = cols()) %>% 
  mutate(hour = lubridate::hour(date_time))
baseline_prop <- read_csv(.args[2], col_types = cols())

fb_pop_adj <- fb_pop %>% 
  left_join(baseline_prop %>% select(quadkey, hour, baseline_mye_prop), by=c("quadkey", "hour")) %>% 
  drop_na(baseline_mye_prop) %>% 
  mutate(n_crisis_adj = n_crisis / baseline_mye_prop)

write_csv(fb_pop_adj, tail(.args, 1))