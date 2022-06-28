suppressPackageStartupMessages({
  require(tidyverse)
  require(sf)
})

# Scotland produces mid year estimates in Data Zones. We need populations in Output areas.
# Left join DZ to OA
# Count number of OA in each DZ
# Divide Population of overlapping Data Zone by number of OAs within that DZ

if (interactive()){
  .args <- c(
    "data/mid_year_estimates/2019/scotland_dz_mye_population_2019.csv",
    "data/lookups/scotland_oa_to_dz.csv",
    "data/mid_year_estimates/2019/scotland_oa_mye_population_2019.csv"
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

dz_pop <- read_csv(.args[1])
oa_dz_lookup <- read_csv(.args[2])

oa_population <- oa_dz_lookup %>% 
  left_join(dz_pop, by = c("DataZone" = "area_code")) %>% 
  group_by(DataZone) %>% 
  mutate(n_oas_per_dz = length(unique(code))) %>% 
  ungroup() %>% 
  mutate(population = population / n_oas_per_dz) %>% 
  select(-DataZone, -n_oas_per_dz) %>% 
  rename(area_code = code)

write_csv(oa_population, tail(.args, 1))
