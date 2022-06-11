require(tidyverse)
require(sf)

if (interactive()){
  .args <- c("data/oa_mid_year_estimates/2020/tile_mye_pop_2020.csv",
             "data/lookups/tile_mye_pop_deciles_2019.csv",
             "data/Britain_TilePopulation/tile_fb_daytime_pop.csv",
             "data/geometry/tiles_12/tiles.shp")
} else {
  .args <- commandArgs(trailingOnly = T)
}


mye_2020 <- read_csv(.args[1])
pop_deciles <- read_csv(.args[2])
fb_pop <- read_csv(.args[3]) %>% 
  mutate(date_time = as.Date(date_time))
tiles <- st_read(.args[4])

tiles %>% 
  left_join(pop_deciles, by = "quadkey") %>% 
  drop_na(pop_decile) %>% 
  ggplot() + 
  geom_sf(aes(fill = as.character(pop_decile)), size=0)

# so the total FB population stays approx. the same but all of it leaves England & Wales? Directly on a certain day?

mye_2020
pop_deciles
fb_pop

mye_2020 %>% 
  left_join(pop_deciles, by = c("quadkey")) %>% 
  group_by(pop_decile) %>% 
  summarise(population = sum(population))

p <- fb_pop %>% 
  left_join(pop_deciles, by = c("quadkey")) %>% 
  drop_na(pop_decile) %>% 
  group_by(date_time) %>% 
  summarise(n_crisis = sum(n_crisis)) %>% 
  ggplot() + 
  geom_path(aes(x = date_time, y = n_crisis))
plotly::ggplotly(p)

# 2020-09-22
fb_pop %>% 
  filter(date_time >= as.Date("2020-09-21") & date_time <= as.Date("2020-09-22")) %>% 
  filter(quadkey == "031112321312")

fb_pop %>% 
  left_join(pop_deciles, by = c("quadkey")) %>% 
  mutate(pop_decile = is.na(pop_decile)) %>% 
  group_by(date_time, pop_decile) %>% 
  summarise(n = n()) %>% 
  filter(!pop_decile & n < 2000)
  ggplot() + 
  geom_path(aes(x = date_time, y = n, color= pop_decile))
  
# then, which quadkeys are present in 2020-09-22 that are missing in 2020-09-21
working_qks <- fb_pop %>% filter(date_time == as.Date("2020-09-21")) %>% pull(quadkey)
problem_qks <- fb_pop %>% filter(date_time == as.Date("2020-09-22")) %>% pull(quadkey)

setdiff(working_qks, problem_qks)
setdiff(problem_qks, working_qks)


fb_pop %>% 
  group_by(date_time) %>% 
  summarise(quadkey = length(unique(quadkey))) %>% ggplot() + 
  geom_path(aes(x = date_time, y = quadkey))
  # there is an approximately constant number of quadkeys in the data
  # there is an approximately constant total number of people in the data

# What does this mean? 
# It means that for a set period of time - most (80%) of the data is being omitted because it doesn't line up with the population deciles

fb_pop %>% 
  left_join(pop_deciles, by = c("quadkey")) %>% 
  drop_na(pop_decile) %>% 
  group_by(date_time, pop_decile) %>% 
  summarise(n_crisis = sum(n_crisis)) %>% 
  ggplot() + 
  geom_path(aes(x = date_time, y = n_crisis, color=pop_decile, group=pop_decile))
# I don't think it is daylight savings time

