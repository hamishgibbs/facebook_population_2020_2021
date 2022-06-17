
PYTHON_INTERPRETER = python3
R_INTERPRETER = /usr/local/bin/Rscript

.PHONY: default

default: \
	${PWD}/data/oa_mid_year_estimates/2020/oa_mye_population_2020.csv \
	${PWD}/data/oa_mid_year_estimates/2019/oa_mye_population_2019.csv \
	${PWD}/data/oa_mid_year_estimates/2020/tile_mye_pop_2020.csv \
	${PWD}/data/oa_mid_year_estimates/2019/tile_mye_pop_2019.csv \
	${PWD}/data/lookups/tile_mye_pop_deciles_2019.csv \
	${PWD}/data/Britain_TilePopulation/tile_fb_daytime_pop.csv \
	${PWD}/output/figs/fb_mye_2020_comparison.png

${PWD}/data/oa_mid_year_estimates/2020/oa_mye_population_2020.csv: ${PWD}/src/combine_oa_mye.py \
	${PWD}/data/oa_mid_year_estimates/2020/raw/*.xlsx
	$(PYTHON_INTERPRETER) $^ $@

${PWD}/data/oa_mid_year_estimates/2019/oa_mye_population_2019.csv: ${PWD}/src/combine_oa_mye.py \
	${PWD}/data/oa_mid_year_estimates/2019/raw/*.xlsx
	$(PYTHON_INTERPRETER) $^ $@

${PWD}/data/oa_mid_year_estimates/2020/tile_mye_pop_2020.csv: ${PWD}/src/oa_mye_to_tile.R \
	${PWD}/data/geometry/oa_geometry/engwal_oa_bng.shp \
	${PWD}/data/geometry/tiles_12/tiles.shp \
	${PWD}/data/oa_mid_year_estimates/2020/oa_mye_population_2020.csv
	$(R_INTERPRETER) $^ $@

${PWD}/data/oa_mid_year_estimates/2019/tile_mye_pop_2019.csv: ${PWD}/src/oa_mye_to_tile.R \
	${PWD}/data/geometry/oa_geometry/engwal_oa_bng.shp \
	${PWD}/data/geometry/tiles_12/tiles.shp \
	${PWD}/data/oa_mid_year_estimates/2019/oa_mye_population_2019.csv
	$(R_INTERPRETER) $^ $@

${PWD}/data/lookups/tile_mye_pop_deciles_2019.csv: ${PWD}/src/tile_mye_to_deciles.R \
	${PWD}/data/oa_mid_year_estimates/2019/tile_mye_pop_2019.csv
	$(R_INTERPRETER) $^ $@

${PWD}/data/Britain_TilePopulation/tile_fb_daytime_pop.csv: ${PWD}/src/tile_12_daytime_fb_pop.py \
	${PWD}/data/Britain_TilePopulation/raw/*_0800.csv
	$(PYTHON_INTERPRETER) $^ $@

${PWD}/output/figs/fb_mye_2020_comparison.png: ${PWD}/src/plot_comparison_fb_mye_pop_proportional.R \
	${PWD}/data/oa_mid_year_estimates/2020/tile_mye_pop_2020.csv \
  ${PWD}/data/lookups/tile_mye_pop_deciles_2019.csv \
  ${PWD}/data/Britain_TilePopulation/tile_fb_daytime_pop.csv
	$(R_INTERPRETER) $^ $@

tile_fb_population_resolution_12.csv
reference_dates.csv
tile_to_bua_lookup.csv
tile_baseline_fb_population.csv
tile_ons_population_decile_lookup.csv
tile_ons_population_{year}.csv
tile_population_date_subtraction_{date}.csv
tile_population_displacement.csv
ons_population_quantile_population_date_subtraction_{date}.csv

Figure 1a Baseline population for each tile (generalised or not)
Figure 1b Raw population of FB users over time
Figure 1c Comparison of baseline FB population to census population per tile per time window
Figure 2a-d Existing code - make one panel per file
Figure 2e population change in top 6 BUAs
Figure 3. Population displacement (repeat existing with relative population)
Figure 4a. Population change by pop decile
Figure 4b. Population change either side of key dates
Figure 4c. Population change by pop decile
Figure 5. Comparison to Census population estimates
