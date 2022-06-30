suppressPackageStartupMessages({
  require(tidyverse)
  require(ggplot2)
  require(sf)
})

if(interactive()){
  .args <-  c(
    "data/period_change_pop_adjusted_absolute.rds", 
    "data/geometry/tiles_12/tiles.shp",
    "data/geometry/Regions_December_2021_EN_BFC.geojson",
    "output/figs/bua_pop_change.rds",
    "output/figs/period_pop_change_tiles.png"
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

period_change <- read_rds(.args[1])
tiles <- st_read(.args[2])
london <- st_read(.args[3]) %>% 
  filter(RGN21NM == "London")
p_bua <- read_rds(.args[4])

london_bbox <- st_as_sfc(st_bbox(london))
london_qks <- london %>% st_join(tiles) %>% pull(quadkey)

colors <- c('#67001f', '#890029', '#b2182b','#d6604d','#f4a582','#fddbc7', '#E2F9FF', '#d1e5f0','#92c5de','#4393c3')
scale_levs <- levels(period_change[['first_lockdown']]$value)
names(colors) <- scale_levs
scale_fill <- scale_fill_manual(values = colors, breaks = scale_levs,
                                guide = guide_legend(reverse = TRUE))

plot_difference <- function(data, title, subtitle=NULL, 
                            scale_fill, legend.position = c(0.2, 0.8), 
                            lims = list(xlim(-8, 2), ylim(50.4, 58.4)),
                            country_size = 0.1){
  
  if (class(lims) != "list") {
    lims = ggutils::geo_lims(lims)
  }
  
  p <- tiles %>% 
    left_join(data, by = c('quadkey' = 'quadkey')) %>% 
    drop_na(diff) %>% 
    ggplot() + 
    ggutils::plot_basemap('United Kingdom', country_size = country_size, world_fill = '#EFEFEF',
                          country_fill = 'white') + 
    geom_sf(aes(fill = value), size = 0) + 
    scale_fill + 
    theme_void() + 
    lims + 
    labs(fill = 'Population\nchange') + 
    theme(legend.position = legend.position,
          plot.margin = margin(0, 0, 0, 0)) + 
    ggtitle(title, subtitle)
  
  return(p)
  
}

plot_london <- function(period_data, scale_fill){
  
  p <- plot_difference(period_data %>% filter(quadkey %in% london_qks), 
                       title=NULL, 
                       subtitle=NULL, 
                       scale_fill = scale_fill, 
                       legend.position = "none",
                       lims = london,
                       country_size=0) + 
    geom_sf(data = london, 
            fill = "transparent", color="black", size=0.05)
  
  return(p)
  
}

p <- list()

p[["first_lockdown"]] <- plot_difference(period_change[["first_lockdown"]], title="a", subtitle="First lockdown: Mar 23, 2020", scale_fill = scale_fill, legend.position = "none")
p[["summer"]] <- plot_difference(period_change[["summer"]], title="b", subtitle="Summer: July 21, 2020", scale_fill = scale_fill, legend.position = "none")
p[["school"]] <- plot_difference(period_change[["school"]], title="c", subtitle="Return to school: Sept 1, 2020", scale_fill = scale_fill, legend.position = "none")
p[["christmas"]] <- plot_difference(period_change[["christmas"]], title="d", subtitle="Christmas: Dec 25, 2020", scale_fill = scale_fill, legend.position = "none")

legend <- cowplot::get_legend(p[["first_lockdown"]] + theme(legend.position = NULL))

p_london <- list()

p_london[["first_lockdown"]] <- plot_london(period_change[["first_lockdown"]], scale_fill = scale_fill)
p_london[["summer"]] <- plot_london(period_change[["summer"]], scale_fill = scale_fill)
p_london[["school"]] <- plot_london(period_change[["school"]], scale_fill = scale_fill)
p_london[["christmas"]] <- plot_london(period_change[["christmas"]], scale_fill = scale_fill)

p_combined <- list()

for (name in names(p_london)){
  
  p_altered <- p[[name]] + geom_sf(data = london_bbox, fill = "transparent", size = 0.25, color = "black")
  
  p_combined[[name]] <- cowplot::ggdraw(p_altered) + 
    cowplot::draw_plot(p_london[[name]] + theme(panel.border = element_rect(colour = "black", fill=NA, size=0.6)),
                       x = 0.63, y = 0.5, 
                       width = 0.37, height = 0.30)
}

p_map <- cowplot::plot_grid(plotlist = p_combined,
                            ncol = 4)

p_map <- cowplot::plot_grid(ggplot() + theme_void(), p_map, legend,
                            nrow = 1, rel_widths = c(0.06, 0.75, 0.14))

p_bua <- p_bua + ggtitle("e")

p_period_bua <- cowplot::plot_grid(p_map, p_bua, nrow = 2)

ggsave(tail(.args, 1),
       p_period_bua,
       width=12, height=8, units="in")

