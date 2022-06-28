require(tidyverse)
require(sf)

if (interactive()){
  .args <- c("data/mid_year_estimates/tile_mye_pop_2020.csv",
             "data/lookups/tile_mye_pop_deciles_2019.csv",
             "data/Britain_TilePopulation/tile_fb_daytime_pop.csv",
             "output/figs/fb_mye_2020_comparison.png")
} else {
  .args <- commandArgs(trailingOnly = T)
}

mye_2020 <- read_csv(.args[1]) %>%
  mutate(quadkey = stringr::str_pad(quadkey, 12, "left", "0"))
pop_deciles <- read_csv(.args[2]) %>%
  mutate(quadkey = stringr::str_pad(quadkey, 12, "left", "0"))
fb_pop <- read_csv(.args[3]) %>%
  mutate(date_time = as.Date(date_time))

label_pop_decile <- function(data){
  return (
    data %>%
      mutate(pop_decile = factor(pop_decile, levels = as.character(10:1),
                                 labels = c("10 (Highest)", 9:2, "1 (Lowest)")))
  )
}

mye_2020_decile_proportional <- mye_2020 %>%
  left_join(pop_deciles, by = c("quadkey")) %>%
  group_by(pop_decile) %>%
  summarise(population = sum(population), .groups="drop") %>%
  mutate(pop_proportion = population / sum(population)) %>%
  label_pop_decile()

p_fb_mye_comparison_proportional <- fb_pop %>%
  filter(date_time < as.Date("2020-12-31")) %>%
  left_join(pop_deciles, by = c("quadkey")) %>%
  drop_na(pop_decile) %>%
  group_by(date_time, pop_decile) %>%
  summarise(n_crisis = sum(n_crisis), .groups="drop") %>% # daily fb pop per decile
  group_by(date_time) %>%
  mutate(n_crisis_proportion = n_crisis / sum(n_crisis)) %>% # daily proportional fb pop
  label_pop_decile() %>%
  ggplot() +
  geom_path(aes(x = date_time, y = n_crisis_proportion, color=pop_decile, group=pop_decile), size=0.3) + 
  geom_vline(aes(xintercept=as.Date("2020-06-30")), linetype="dashed") +
  geom_hline(data = mye_2020_decile_proportional, aes(color=pop_decile, yintercept=pop_proportion),
             linetype="dashed") +
  geom_label(aes(x = as.Date("2020-06-30"), y = 0.3, label="ONS Mid-Year Estimate Date")) +
  scale_y_continuous(trans="log10") +
  theme_classic() +
  labs(color="Population\nDecile", x=NULL, y="Population Proportion")

ggsave(tail(.args, 1), p_fb_mye_comparison_proportional,
       width=10, height=5, units = 'in')

# there seems to be redistribution
