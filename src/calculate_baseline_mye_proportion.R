suppressPackageStartupMessages({
  require(tidyverse)
})

if(interactive()){
  .args <-  c("data/Britain_TilePopulation/tile_baseline_fb_population.csv",
              "data/mid_year_estimates/tile_mye_pop_2019.csv",
              "data/Britain_TilePopulation/tile_baseline_mye_pop_proportion.csv")
} else {
  .args <- commandArgs(trailingOnly = T)
}

fb_baseline_pop <- read_csv(.args[1], col_types = cols())
mye_2019 <- read_csv(.args[2], col_types = cols(quadkey=col_character())) %>% 
  mutate(quadkey = stringr::str_pad(quadkey, width=12, side="left", pad="0"))

mye_baseline_proportion <- fb_baseline_pop %>% 
  left_join(mye_2019, by="quadkey") %>% 
  drop_na(population) %>% 
  mutate(baseline_mye_prop = n_baseline / population)

write_csv(mye_baseline_proportion, tail(.args, 1))

