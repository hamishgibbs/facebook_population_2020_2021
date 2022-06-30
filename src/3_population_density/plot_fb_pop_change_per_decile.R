suppressPackageStartupMessages({
  require(tidyverse)
  require(ggplot2)
  require(sf)
})

if(interactive()){
  .args <-  c("data/Britain_TilePopulation/tile_fb_pop_adjusted_absolute.csv",
              "data/Britain_TilePopulation/tile_baseline_mye_pop_proportion.csv",
              "data/period_decile_change_pop_adjusted_absolute.rds",
              "data/lookups/tile_mye_pop_deciles_2019.csv",
              "data/geometry/tiles_12/tiles.shp",
              "data/config/periods.rds",
              "output/figs/decile_pop_change.png")
  FOCUS_HOUR_WINDOW = 16
} else {
  .args <- commandArgs(trailingOnly = T)
  FOCUS_HOUR_WINDOW <- as.numeric(Sys.getenv("FOCUS_HOUR_WINDOW"))
}

fb_pop <- read_csv(.args[1]) %>% 
  filter(date_time <= as.POSIXct("2021-03-10"))
tile_baseline_pop <- read_csv(.args[2])
period_change <- read_rds(.args[3])
tile_to_decile <- read_csv(.args[4], col_types = cols(quadkey=col_character())) %>% 
  mutate(quadkey = stringr::str_pad(quadkey, 12, "left", "0"))
tiles <- st_read(.args[5]) 
periods <- read_rds(.args[6])

label_pop_q <- function(vect){
  
  return (
    factor(as.character(vect), 
           levels = as.character(c(1:10)),
           labels = c("1 (low)", "2", "3", "4", "5", "6", "7", "8", "9", "10 (high)"))
  )
}

get_period_rectangles <- function(ymin = -Inf, date_trans = F){
  
  period_rectangles <- lapply(periods, function(x){
    
    if(date_trans){
      xmin <- as.Date(x$period_start)
      xmax <- as.Date(x$period_end)
    } else {
      xmin <- x$period_start
      xmax <- x$period_end
    }
    
    return(
      annotate("rect", xmin = xmin, 
               xmax = xmax, 
               ymin = ymin, 
               ymax = Inf, 
               alpha = .2) 
    )
  })
  
  return(period_rectangles)
  
}

period_lines <- lapply(periods, function(x){
  return(
    geom_vline(aes(xintercept = x$i_date), size = 0.1, color = "red")
  )
})

period_lines_date <- lapply(periods, function(x){
  return(
    geom_vline(aes(xintercept = as.Date(x$i_date)), size = 0.1, color = "red")
  )
})

bar_data <- do.call(rbind, period_change) %>% 
  mutate(negative = diff < 0) %>% 
  mutate(period = ifelse(period == "first_lockdown", "First lockdown", period),
         period = ifelse(period == "summer", "Summer", period),
         period = ifelse(period == "school", "Return to school", period),
         period = ifelse(period == "christmas", "Christmas", period)) %>% 
  drop_na(pop_decile)
  
bar_data$period <- factor(bar_data$period, levels=c(
  "First lockdown",
  "Summer",
  "Return to school",
  "Christmas"
))

p_bar <- bar_data %>% 
  mutate(pop_decile = label_pop_q(pop_decile)) %>% 
  ggplot() + 
  geom_bar(aes(x = diff, y = pop_decile, fill = negative), stat="identity") + 
  scale_fill_manual(values = c("TRUE"="red", "FALSE"="blue")) + 
  facet_wrap(~period, nrow = 1) +
  theme_classic() + 
  scale_x_continuous(labels = scales::label_comma(scale = 1e-3)) + 
  ylab("Population Decile") + 
  xlab("Population Change (Thousands)") + 
  theme(legend.position = "none",
        strip.background = element_blank()) + 
  ggtitle("b")

map_data <- tiles %>% 
  left_join(tile_to_decile, by = "quadkey") %>% 
  drop_na(pop_decile)

pop_pal <-  c('#e31a1c', '#ff7f00','#fdb462','#a8ddb5','#7bccc4','#4eb3d3','#2b8cbe','#0868ac','#084081', '#081d58')
names(pop_pal) <- c("1 (low)", "2", "3", "4", "5", "6", "7", "8", "9", "10 (high)")

p_map <- map_data %>% 
  mutate(pop_decile = label_pop_q(pop_decile)) %>% 
  ggplot() + 
  geom_sf(aes(fill = pop_decile), size = 0) + 
  scale_fill_manual(values=pop_pal) + 
  ggutils::plot_basemap("United Kingdom", country_size = 0.1) +
  ylim(c(50, 58.5)) + 
  xlim(c(-9, 2)) +
  labs(fill = "Population\nDecile") + 
  theme_void() +
  theme(legend.position = c(0.1, 0.5))

ggsave("output/figs/pop_decile_map.png",
       p_map,
       width=4, height=5.5, units="in")

pop_q_data <- fb_pop %>% 
  filter(hour == !!FOCUS_HOUR_WINDOW) %>% 
  left_join(tile_to_decile, by = c("quadkey")) %>% 
  drop_na(pop_decile, n_crisis_adj) %>% 
  group_by(pop_decile, date_time) %>% 
  summarise(n_crisis_adj = sum(n_crisis_adj, na.rm = T), .groups = "drop")

annot <- tile_baseline_pop %>% 
  filter(hour == !!FOCUS_HOUR_WINDOW) %>% 
  left_join(tile_to_decile, by="quadkey") %>% 
  group_by(pop_decile) %>% 
  summarise(population = sum(population, na.rm = T), .groups = "drop")

p_q_ts <- pop_q_data %>% 
  mutate(pop_decile = label_pop_q(pop_decile)) %>% 
  ggplot() + 
  get_period_rectangles(0) + 
  period_lines + 
  geom_path(aes(x = date_time, y = n_crisis_adj, color = pop_decile), size = 0.3) + 
  scale_color_manual(values=pop_pal) + 
  scale_y_continuous(trans = "log10", labels = scales::unit_format(unit = "M", scale = 1e-6)) + 
  theme_classic() + 
  theme(axis.title.x = element_blank(),
        axis.text.x = element_text(margin =  margin(t = 0, r = 0, b = 0.5, l = 0, unit = 'cm'))) + 
  ylab("Population (log scale)") + 
  ggtitle("a") + 
  guides(color="none")

p <- suppressWarnings(cowplot::plot_grid(p_q_ts, p_bar, nrow = 2, rel_heights = c(0.4, 0.6)))

p_q_ts_norm <- pop_q_data %>% 
  left_join(annot, by = c("pop_decile")) %>% 
  mutate(n_crisis_adj_norm = (n_crisis_adj / population) * 100) %>% 
  mutate(pop_decile = forcats::fct_rev(label_pop_q(pop_decile)),
         date_time = as.Date(date_time)) %>% 
  ggplot() + 
  geom_path(aes(x = date_time, y = n_crisis_adj_norm, color=pop_decile), size = 0.2) + 
  scale_color_manual(values=pop_pal) + 
  geom_hline(aes(yintercept = 100), linetype = "dashed", size = 0.1) + 
  get_period_rectangles(-Inf, T) + 
  period_lines_date + 
  facet_wrap(~pop_decile, scales = "free_y", nrow = 2) + 
  theme_classic() + 
  ylab("Population relative to baseline (%)") + 
  theme(axis.title.x = element_blank(),
        axis.text.x = element_text(size = 7),
        axis.text.y = element_text(margin =  margin(t = 0, r = 0, b = 0, l = 0.5, unit = 'cm')),
        strip.background = element_blank()) + 
  ggtitle("c") + 
  guides(color="none")


p_row <- suppressWarnings(cowplot::plot_grid(p_q_ts, p_bar, nrow = 1))
p <- cowplot::plot_grid(p_row, p_q_ts_norm + scale_x_date(date_breaks = "3 month") + 
                          theme(axis.text.x = element_text(angle = -35, vjust = 0.5, hjust=0,
                                                           size = 8)), 
                        ncol = 1)

ggsave(tail(.args, 1),
       p,
       width=10, height=6, units="in")

