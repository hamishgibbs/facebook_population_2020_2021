suppressPackageStartupMessages({
  require(tidyverse)
  require(sf)
})

if (interactive()){
  .args <- c(
    "data/geometry/england_built_up_areas/Built-up_Areas_December_2011_Boundaries_V2.shp",
    "data/geometry/scotland_built_up_areas/Settlements2020_MHW.shp",
    "data/geometry/uk_combined_buas.geojson"
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

england_bua <- st_read(.args[1])
scotland_bua <- st_read(.args[2])

england_bua <- england_bua %>%
  rename(bua_code = bua11cd,
         bua_name = bua11nm)

scotland_bua <- scotland_bua %>%
  rename(bua_code = code,
         bua_name = name)

uk_bua <- lapply(list(england_bua, scotland_bua), st_transform, crs=4326) %>%
  lapply(., subset, select=c("bua_name", "bua_code")) %>%
  do.call(rbind, .) %>%
  mutate(geometry = st_make_valid(geometry))

st_write(uk_bua, tail(.args, 1), delete_dsn=T)
st_write(uk_bua %>% st_simplify(preserveTopology = T, dTolerance = 250),
         gsub(".geojson", "_simplified.geojson", tail(.args, 1)),
         delete_dsn=T)
