
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
