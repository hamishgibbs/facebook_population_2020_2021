suppressPackageStartupMessages({
  require(tidyverse)
  require(sf)
})

if (interactive()){
  .args <- c(
    "data/Britain_TilePopulation/tile_baseline_fb_population.csv",
    "data/geometry/tiles_12/tiles.shp",
    "output/validation/tile_mye_pop_2020_validation.png"
  )
  FILL_COLNAME <- "n_baseline"
} else {
  .args <- commandArgs(trailingOnly = T)
  FILL_COLNAME <- Sys.getenv("FILL_COLNAME")
}

input_population <- read_csv(.args[1]) %>%
  mutate(quadkey = stringr::str_pad(quadkey, 12, "left", "0"))
tiles <- st_read(.args[2])

p <- tiles %>%
  left_join(input_population, by="quadkey") %>%
  drop_na(!!FILL_COLNAME) %>%
  ggplot() +
  geom_sf(aes(fill = !!sym(FILL_COLNAME)), size=0) +
  scale_fill_viridis_c(trans="log10") +
  facet_wrap(~hour) +
  theme_void() +
  theme(plot.background = element_rect(fill="white", size=0))

ggsave(tail(.args, 1), p)
