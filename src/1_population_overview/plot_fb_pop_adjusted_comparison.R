# Script to compare baseline and census populations

# Load libraries
suppressPackageStartupMessages({
  require(tidyverse)
  require(ggplot2)
  require(sf)
  require(ggpubr)
})

if(interactive()){
  .args <-  c("data/Britain_TilePopulation/tile_baseline_mye_pop_proportion.csv",
              "data/geometry/tiles_12/tiles.shp",
              "data/Britain_TilePopulation/tile_fb_pop_adjusted_absolute.csv",
              "data/config/period_lines.rds",
              "data/config/period_rectangles.rds",
      "output/figs/fb_mye_population_adjustment.png")
  FOCUS_HOUR_WINDOW = 16
} else {
  .args <- commandArgs(trailingOnly = T)
  FOCUS_HOUR_WINDOW <- as.numeric(Sys.getenv("FOCUS_HOUR_WINDOW"))
}

tile_pop <- read_csv(.args[1])

tiles <- st_read(.args[2]) %>%
  st_transform(27700)

fb_pop <- read_csv(.args[3]) %>% 
  filter(date_time <= as.POSIXct("2021-03-10"))

period_lines <- read_rds(.args[4])
period_rectangles <- read_rds(.args[5])

name_hours <- function(x){

  x <- x %>%
    mutate(hour = as.character(hour),
         hour = ifelse(hour == '0', '00:00-08:00', hour),
         hour = ifelse(hour == '8', '08:00-16:00', hour),
         hour = ifelse(hour == '16', '16:00-00:00', hour))

  return(x)

}

hour_pal <- c('00:00-08:00' = 'darkblue',
              '08:00-16:00' = 'orange',
              '16:00-00:00' = 'darkred')

base_pops <- tile_pop %>%
  group_by(hour) %>%
  summarise(n_baseline = sum(n_baseline, na.rm = T), .groups = 'drop') %>%
  name_hours

scale_limits <- c(
  min(tile_pop$baseline_mye_prop * 100, na.rm = T),
  max(tile_pop$baseline_mye_prop * 100, na.rm = T)
)

plot_percentage <- function(hour_sel, title, legend.position){
  
  p <- tile_pop %>% 
    left_join(tiles %>% st_transform(4326), by = "quadkey") %>% 
    drop_na(baseline_mye_prop) %>%
    filter(hour == hour_sel) %>% 
    name_hours %>%
    st_as_sf() %>% 
    ggplot() +
    ggutils::plot_basemap('United Kingdom', country_size = 0.1) +
    geom_sf(aes(fill = baseline_mye_prop * 100), size = 0) +
    #colorspace::scale_fill_continuous_sequential("Mint", trans="log10",
    #                                             limits = scale_limits) +
    scale_fill_viridis_c(trans="log10", limits = scale_limits) + 
    theme_void() +
    labs(fill = "Facebook\nUser %", title = title) +
    theme(legend.position = legend.position,
          plot.background = element_rect(fill="white", size=0)) + 
    ylim(c(50, 58.5)) +
    xlim(c(-9, 2))
  
  return(p)
  
}

p_0 <- plot_percentage(0, "a", "none")
p_8 <- plot_percentage(8, "b", "none")
p_16 <- plot_percentage(16, "c", "none")
legend <- cowplot::get_legend(p_0 + theme(legend.position = "right"))

p_percentage <- cowplot::plot_grid(p_0, p_8, p_16, legend, nrow = 1, rel_widths = c(0.3, 0.3, 0.3, 0.1))

ggsave("output/figs/fb_mye_hour_proportion_maps.png",
       p_percentage,
       width=10, height=4, units = "in")

p_n_crisis <- fb_pop %>%
  group_by(date_time, hour) %>%
  summarise(n_crisis = sum(n_crisis, na.rm = T), .groups = 'drop') %>%
  name_hours %>%
  ggplot() +
  period_rectangles + 
  period_lines + 
  geom_line(aes(x = date_time, y = n_crisis, color = hour), size = 0.3, alpha = 0.8) +
  geom_hline(data = base_pops, aes(yintercept = n_baseline, color = hour), linetype = 'dashed', size = 0.5) +
  scale_color_manual(values = hour_pal) +
  scale_y_continuous(labels = scales::unit_format(unit = "M", scale = 1e-6, accuracy = 0.1)) + 
  annotate("text", x = as.POSIXct("2020-02-15 00:00"), y = 6500000, label = "Baseline Period", size = 3) +
  annotate("segment", 
           x = as.POSIXct("2020-01-20 00:00"), 
           xend = as.POSIXct("2020-03-09 00:00"), 
           y = 6300000, yend = 6300000, colour = "black", size = 0.5) +
  theme_classic() +
  labs(color = 'Time Window') +
  ylab('Number of users') +
  theme(axis.title.x = element_blank(),
        plot.margin = margin(0, 0, 0, 0),
        legend.position = "none",
        axis.text.y = element_text(margin = margin(t = 0, r = 0, b = 0, l = 0.5, unit = 'cm'))) +
  xlim(c(as.POSIXct("2020-01-20 00:00"), max(fb_pop$date_time))) +
  ggtitle('b')

p_dens <- tile_pop %>%
  name_hours() %>%
  ggplot() +
  geom_density(aes(x = baseline_mye_prop * 100, color = as.character(hour))) +
  scale_color_manual(values = hour_pal) +
  scale_x_continuous(trans="log10") +
  theme_classic() +
  xlab("Percentage Facebook Users") +
  ylab("Density") +
  theme(legend.position = "none",
        axis.title.y = element_text(margin = margin(t = 0, r = 20, b = 0, l = 0))) +
  labs(color = "Time Window") +
  ggtitle('c')

uk <- rnaturalearth::ne_states(country = 'United Kingdom', returnclass = 'sf')

p_map <-tiles %>%
  st_transform(4326) %>%
  left_join(tile_pop %>% filter(hour == !!FOCUS_HOUR_WINDOW), by ='quadkey') %>%
  drop_na(population) %>%
  ggplot() +
  ggutils::plot_basemap('United Kingdom', country_size = 0.1) +
  geom_sf(aes(fill = population), size = 0) +
  scale_fill_viridis_c(trans="log10", label = scales::comma) + 
  labs(fill = 'Population', title = "a", subtitle = "Baseline Period") +
  theme_void() +
  theme(legend.position = c(0.85, 0.8),
        plot.margin = margin(0, 0, 0, 0),
        plot.background = element_rect(fill="white", size=0)) +
  ylim(c(50, 58.5)) +
  xlim(c(-9, 2))

time_legend <- cowplot::get_legend(p_n_crisis + theme(legend.position = "right"))

p_comp <- cowplot::plot_grid(p_n_crisis, p_dens, nrow = 2, rel_heights = c(0.6, 0.4))

p_comp_leg <- cowplot::plot_grid(p_comp, time_legend, rel_widths = c(0.8, 0.2))

p <- cowplot::plot_grid(p_map, p_comp_leg, ncol = 2, rel_widths = c(0.4, 0.6))

ggsave(tail(.args, 1),
       p,
       width=11, height=6, units = "in")

p_rel <- tile_pop %>% 
  filter(hour == !!FOCUS_HOUR_WINDOW) %>% 
  ggplot() + 
  geom_point(aes(x = population, y = n_baseline), size = 0.05, alpha = 0.5) + 
  scale_y_continuous(trans = "log10", labels = scales::unit_format(unit = "k", scale = 1e-3, accuracy = 0.01)) + 
  scale_x_continuous(trans = "log10", labels = scales::unit_format(unit = "k", scale = 1e-3, accuracy = 0.01)) + 
  theme_classic() + 
  labs(y = "Facebook users", x = "Census population")


ggsave("output/figs/pop_facebook_census.png",
       p_rel,
       width=8, height=4, units = "in")

p_var <- fb_pop %>%
  group_by(date_time, hour) %>%
  summarise(n_crisis = sum(n_crisis, na.rm = T), 
            .groups = 'drop') %>%
  mutate(week = lubridate::floor_date(date_time, "week")) %>% 
  group_by(week, hour) %>% 
  summarise(variance = var(n_crisis),
            n = length(n_crisis),
            n_crisis = sum(n_crisis, na.rm= T), 
            .groups="drop") %>% 
  name_hours() %>% 
  ggplot() + 
  geom_point(aes(x = week, y = variance, color = hour), size = 0.2) + 
  scale_color_manual(values = hour_pal) + 
  theme_classic() + 
  labs(y = "Variance", x = NULL, color = "Period")

ggsave("output/figs/time_period_variance.png",
       p_var,
       width=8, height=4, units = "in")
