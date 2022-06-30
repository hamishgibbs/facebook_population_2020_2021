suppressPackageStartupMessages({
  require(tidyverse)
})

.args <- commandArgs(trailingOnly = T)

england_mye_pop <- read_csv(.args[1], col_types=cols(quadkey=col_character()))

pop_decile <- england_mye_pop %>%
  arrange(-population) %>%
  mutate(pop_decile = ntile(population, 10)) %>%
  select(-population)

write_csv(pop_decile, tail(.args, 1))
