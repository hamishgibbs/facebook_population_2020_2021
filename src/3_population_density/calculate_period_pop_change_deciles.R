suppressPackageStartupMessages({
  require(tidyverse)
})

if(interactive()){
  .args <-  c("data/config/periods.rds", 
              "data/Britain_TilePopulation/tile_fb_pop_adjusted_absolute.csv", 
              "data/lookups/tile_mye_pop_deciles_2019.csv", 
              "data/period_decile_change_pop_adjusted_absolute.rds")
  FOCUS_HOUR_WINDOW = 16
} else {
  .args <- commandArgs(trailingOnly = T)
  FOCUS_HOUR_WINDOW <- as.numeric(Sys.getenv("FOCUS_HOUR_WINDOW"))
}

periods <- read_rds(.args[1])
fb_pop <- read_csv(.args[2])
tile_to_decile <- read_csv(.args[3]) %>% 
  mutate(quadkey = stringr::str_pad(quadkey, 12, "left", "0"))

period_change <- list()

for (period_name in names(periods)){
  
  period <- periods[[period_name]]
  period_data <- fb_pop %>% 
    filter(hour == !!FOCUS_HOUR_WINDOW,
           date_time >= as.POSIXct(period$period_start),
           date_time <= as.POSIXct(period$period_end)) %>% 
    mutate(period = ifelse(date_time < period$i_date, "Pre", "Post")) %>% 
    group_by(period, quadkey) %>% 
    summarise(n_crisis_adj = mean(n_crisis_adj, na.rm = T), .groups = 'drop') %>% 
    left_join(tile_to_decile, by = c("quadkey")) %>% 
    group_by(period, pop_decile) %>% 
    summarise(n_crisis_adj = sum(n_crisis_adj, na.rm = T), .groups = 'drop') %>% 
    pivot_wider(names_from = period, values_from = n_crisis_adj) %>% 
    mutate(diff = Post - Pre) %>% 
    drop_na(diff) %>% 
    mutate(period = period_name)
  
  period_change[[period_name]] <- period_data
}
  
write_rds(period_change, tail(.args, 1))


