# Script to aggregate population estimates to tiles
suppressPackageStartupMessages({
  require(tidyverse)
  require(sf)
})

if (interactive()){
  .args <- c(
    "data/mid_year_estimates/2019/england_wales_mye_population_2019.csv",
    "data/lookups/england_wales_oa_to_tile.csv",
    "data/mid_year_estimates/2019/england_wales_mye_pop_tile_2019.csv"
  )
  GEOMETRY_NAME <- "OA11CD"
} else {
  .args <- commandArgs(trailingOnly = T)
  GEOMETRY_NAME <- Sys.getenv("GEOMETRY_NAME")
}

mye_pop <- read_csv(.args[1])
geom_tile_lookup <- read_csv(.args[2])

tile_pop <- mye_pop %>% 
  left_join(geom_tile_lookup, by = c("area_code" = GEOMETRY_NAME)) %>% 
  group_by(quadkey) %>% 
  summarise(population = sum(population, na.rm=T))

write_csv(tile_pop, tail(.args, 1))
