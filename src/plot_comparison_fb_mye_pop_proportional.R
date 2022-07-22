require(tidyverse)
require(sf)

if (interactive()){
  .args <- c("data/mid_year_estimates/tile_mye_pop_2020.csv",
             "data/lookups/tile_mye_pop_deciles_2019.csv",
             "data/Britain_TilePopulation/tile_fb_pop_adjusted_absolute.csv",
             "data/geometry/tiles_12/tiles.shp",
             "output/figs/fb_mye_2020_comparison.png")
  FOCUS_HOUR_WINDOW <- 16
  PLOT_CUTOFF_DATE <- as.Date("2021-03-31")
} else {
  .args <- commandArgs(trailingOnly = T)
  FOCUS_HOUR_WINDOW <- as.numeric(Sys.getenv("FOCUS_HOUR_WINDOW"))
  PLOT_CUTOFF_DATE <- as.Date(Sys.getenv("PLOT_CUTOFF_DATE"))
}

# ADD cutoff date "2021-03-10" PLOT_CUTOFF_DATE to this and others
# add census date annotation
# add decile color palette

mye_2020 <- read_csv(.args[1]) %>%
  mutate(quadkey = stringr::str_pad(quadkey, 12, "left", "0"))
pop_deciles_2019 <- read_csv(.args[2]) %>%
  mutate(quadkey = stringr::str_pad(quadkey, 12, "left", "0"))
fb_pop <- read_csv(.args[3]) %>%
  mutate(date_time = as.Date(date_time)) %>%
  filter(hour == !!FOCUS_HOUR_WINDOW)
tiles <- st_read(.args[4])

label_pop_decile <- function(data){
  return (
    data %>%
      mutate(pop_decile = factor(pop_decile, levels = as.character(10:1),
                                 labels = c("10 (Highest)", 9:2, "1 (Lowest)")))
  )
}

pop_pal <-  c('#e31a1c', '#ff7f00','#fdb462','#a8ddb5','#7bccc4','#4eb3d3','#2b8cbe','#0868ac','#084081', '#081d58')
names(pop_pal) <- c("1 (Lowest)", "2", "3", "4", "5", "6", "7", "8", "9", "10 (Highest)")

mye_2020_decile_proportional <- mye_2020 %>%
  left_join(pop_deciles_2019, by = c("quadkey")) %>%
  group_by(pop_decile) %>%
  summarise(population = sum(population), .groups="drop") %>%
  mutate(pop_proportion = population / sum(population)) %>%
  label_pop_decile()

p_fb_mye_comparison_proportional <- fb_pop %>%
  filter(date_time < PLOT_CUTOFF_DATE) %>%
  left_join(pop_deciles_2019, by = c("quadkey")) %>%
  drop_na(pop_decile) %>%
  group_by(date_time, pop_decile) %>%
  summarise(n_crisis = sum(n_crisis), .groups="drop") %>% # daily fb pop per decile
  group_by(date_time) %>%
  mutate(n_crisis_proportion = n_crisis / sum(n_crisis)) %>% # daily proportional fb pop
  label_pop_decile() %>%
  ggplot() +
  geom_path(aes(x = date_time, y = n_crisis_proportion, color=pop_decile, group=pop_decile), size=0.3) +
  scale_fill_manual(values=pop_pal) + 
  geom_vline(aes(xintercept=as.Date("2020-06-30")), size=0.3) +
  geom_hline(data = mye_2020_decile_proportional, aes(color=pop_decile, yintercept=pop_proportion),
             linetype="dashed") +
  geom_label(aes(x = as.Date("2020-06-30"), y = 1, label="Mid-2020 Estimate Date"), size = 3) +
  scale_y_continuous(trans="log10") +
  theme_classic() +
  labs(color="Population\nDecile", x=NULL, y="Population Proportion", title="b")

# put label on top, put line of red pts showing census date

ggsave(tail(.args, 1), p_fb_mye_comparison_proportional,
       width=10, height=5, units = 'in')

fb_pop_mye_2020_diff <- tiles %>%
  left_join(mye_2020, by = "quadkey") %>%
  left_join(fb_pop %>% filter(date_time == as.Date("2020-06-30")), by = "quadkey") %>%
  drop_na(population, n_crisis_adj) %>%
  mutate(diff = n_crisis_adj - population)

breaks <- ggutils::inclusive_class_breaks(fb_pop_mye_2020_diff$diff,
                                style="quantile", 6)
breaks <- c(-250000, -100000, -10000, -1000, 0, 1000, 3000)

fb_pop_mye_2020_diff <- fb_pop_mye_2020_diff %>%
  ggutils::classify_intervals("diff", breaks)

pal <- c('#b2182b','#d6604d','#f4a582','#fddbc7', '#92c5de', '#4393c3')
names(pal) <- levels(fb_pop_mye_2020_diff$value)

p_map <- fb_pop_mye_2020_diff %>%
  ggplot() +
  ggutils::plot_basemap("United Kingdom") +
  geom_sf(aes(fill = value), size=0) +
  ggutils::geo_lims(fb_pop_mye_2020_diff) +
  scale_fill_manual(values = pal, guide = guide_legend(reverse = TRUE)) +
  theme_void() +
  theme(legend.position = c(0.93, 0.8)) +
  ylim(c(50, 58.5)) +
  xlim(c(-9, 2)) +
  labs(fill=NULL, title="a")

p_comparison_facet <- p_fb_mye_comparison_proportional +
  facet_wrap(~pop_decile, scales="free_y") +
  labs(title = "b") +
  theme(legend.position = "none")

p <- cowplot::plot_grid(p_map, p_fb_mye_comparison_proportional, ncol=2, rel_widths = c(0.4, 0.6))

ggsave(tail(.args, 1),
       p,
       width=13, height=6, units="in")

total_pop_2020_mye <- fb_pop_mye_2020_diff$population %>% sum()
total_pop_2020_fb <- fb_pop_mye_2020_diff$n_crisis_adj %>% sum()
total_pop_diff <- (total_pop_2020_mye - total_pop_2020_fb)
total_pop_diff_perc <- total_pop_diff / total_pop_2020_mye

scales::comma(total_pop_diff)
scales::percent(total_pop_diff_perc)

top_decile_diff <- fb_pop_mye_2020_diff %>%
  left_join(pop_deciles_2019, by="quadkey") %>%
  filter(pop_decile == 10)

total_pop_2020_mye <- top_decile_diff$population %>% sum()
total_pop_2020_fb <- top_decile_diff$n_crisis_adj %>% sum()
total_pop_diff <- (total_pop_2020_mye - total_pop_2020_fb)
total_pop_diff_perc <- total_pop_diff / total_pop_2020_mye

scales::comma(total_pop_diff)
scales::percent(total_pop_diff_perc)
