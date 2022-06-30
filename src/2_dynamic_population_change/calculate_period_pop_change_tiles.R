suppressPackageStartupMessages({
  require(tidyverse)
})

if(interactive()){
  .args <-  c("data/config/periods.rds",
              "data/Britain_TilePopulation/tile_fb_pop_adjusted_absolute.csv",
              "data/period_change_pop_adjusted_absolute.rds")
  FOCUS_HOUR_WINDOW = 16
} else {
  .args <- commandArgs(trailingOnly = T)
  FOCUS_HOUR_WINDOW <- as.numeric(Sys.getenv("FOCUS_HOUR_WINDOW"))
}

periods <- read_rds(.args[1])
fb_pop <- read_csv(.args[2])

period_change <- list()

for (period_name in names(periods)){
  scale_breaks <- c(-110000, -50000, -10000, -5000, -1000, -250, 0, 250, 1000, 5000, 22000)
  period <- periods[[period_name]]
  period_data <- fb_pop %>% 
    filter(hour == !!FOCUS_HOUR_WINDOW,
           date_time >= as.POSIXct(period$period_start),
           date_time <= as.POSIXct(period$period_end)) %>% 
    mutate(period = ifelse(date_time < period$i_date, "Pre", "Post")) %>% 
    group_by(period, quadkey) %>% 
    summarise(n_crisis_adj = mean(n_crisis_adj, na.rm = T), .groups = 'drop') %>% 
    pivot_wider(names_from = period, values_from = n_crisis_adj) %>% 
    mutate(diff = Post - Pre) %>% 
    drop_na(diff) %>% 
    mutate(period = period_name) %>% 
    ggutils::classify_intervals(value="diff", breaks=scale_breaks)
  period_change[[period_name]] <- period_data
}
  
write_rds(period_change, tail(.args, 1))


