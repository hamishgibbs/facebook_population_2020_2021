suppressPackageStartupMessages({
  require(tidyverse)
  require(sf)
})

# Join Geometry 2 to Geometry 1 by Geometry 1 centroids falling within Geometry 2 polygons
# Specify which columns to retain with RETAIN_COLNAMES

if (interactive()){
  .args <- c(
    "data/geometry/tiles/tiles.shp",
    "data/geometry/built_up_areas/Built-up_Areas_December_2011_Boundaries_V2.shp",
    "data/spatial_lookups/la_to_bua.csv"
  )
  RETAIN_COLNAMES <- "quadkey, bua11cd, bua11nm, st_areasha"
} else {
  .args <- commandArgs(trailingOnly = T)
  RETAIN_COLNAMES <- Sys.getenv("RETAIN_COLNAMES")
}

tiles <- st_read(.args[1]) %>%
  st_centroid()
buas <- st_read(.args[2])
RETAIN_COLNAMES <- str_split(RETAIN_COLNAMES, ", ")[[1]]

tiles <- tiles %>% st_transform(st_crs(buas)) # Transform Geometry 1 CRS to Geometry 2 CRS

tile_bua_lookup <- st_join(tiles, buas) %>%
  st_drop_geometry() %>%
  select(!!RETAIN_COLNAMES)

write_csv(tile_bua_lookup, tail(.args, 1))
