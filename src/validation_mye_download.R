suppressPackageStartupMessages({
  require(tidyverse)
  require(sf)
})

if (interactive()){
  .args <- c(
    "data/oa_mid_year_estimates/2020/tile_mye_pop_2020.csv",
    "data/geometry/tiles_12/tiles.shp",
    "output/validation/tile_mye_pop_2020_validation.png"
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

ons_pop <- read_csv(.args[1])
tiles <- st_read(.args[2])

p <- tiles %>% 
  left_join(ons_pop, by="quadkey") %>% 
  drop_na(population) %>% 
  ggplot() + 
  geom_sf()

ggsave(tail(.args, 1), p)