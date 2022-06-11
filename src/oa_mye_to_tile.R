# Script to aggregate population estimates to tiles
suppressPackageStartupMessages({
  require(tidyverse)
  require(sf)
})

.args <- commandArgs(trailingOnly = T)

england_oa_in <- st_read(.args[1]) %>%
  select(-FID_1)

tiles <- st_read(.args[2]) %>%
  st_transform(27700)

england_pop <- read_csv(.args[3])

england_oa_tiles <- st_join(england_oa_in, tiles) %>% st_drop_geometry()

england_pop_tiles <- england_oa_tiles %>%
  as_tibble() %>%
  left_join(england_pop, by = c("OA11CD")) %>%
  select(quadkey, population) %>%
  group_by(quadkey) %>%
  summarise(population = sum(population, na.rm = T))

write_csv(england_pop_tiles,
          tail(.args, 1))
