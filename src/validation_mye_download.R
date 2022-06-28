suppressPackageStartupMessages({
  require(tidyverse)
  require(sf)
})

if (interactive()){
  .args <- c(
    "data/mid_year_estimates/tile_mye_pop_2020.csv",
    "data/geometry/tiles_12/tiles.shp",
    "output/validation/tile_mye_pop_2020_validation.png"
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

ons_pop <- read_csv(.args[1]) %>% 
  mutate(quadkey = stringr::str_pad(quadkey, 12, "left", "0"))
tiles <- st_read(.args[2])

uk_pop <- scales::comma(sum(ons_pop$population))

p <- tiles %>% 
  left_join(ons_pop, by="quadkey") %>% 
  drop_na(population) %>% 
  ggplot() + 
  geom_sf(aes(fill = population), size=0) + 
  scale_fill_viridis_c(trans="log10") + 
  theme_void() + 
  theme(plot.background = element_rect(fill="white", size=0)) + 
  labs(title=paste("Total population: ", uk_pop))

ggsave(tail(.args, 1), p)