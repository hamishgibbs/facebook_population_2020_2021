
PYTHON_INTERPRETER = python3
R_INTERPRETER = /usr/local/bin/Rscript

.PHONY: default

default: \
	${PWD}/output/figs/fb_mye_2020_comparison.png \
	${PWD}/output/validation/tile_mye_pop_2020_validation.png \
	${PWD}/output/validation/tile_mye_pop_2019_validation.png \
	${PWD}/data/Britain_TilePopulation/tile_baseline_mye_pop_proportion.csv

# --- Clean national MYE population data ---

${PWD}/data/mid_year_estimates/2019/england_wales_mye_population_2019.csv: ${PWD}/src/census_population/combine_oa_mye.py \
	${PWD}/data/mid_year_estimates/2019/england_wales_raw/*.xlsx
	$(PYTHON_INTERPRETER) $^ $@

${PWD}/data/mid_year_estimates/2020/england_wales_mye_population_2020.csv: ${PWD}/src/census_population/combine_oa_mye.py \
	${PWD}/data/mid_year_estimates/2020/england_wales_raw/*.xlsx
	$(PYTHON_INTERPRETER) $^ $@

${PWD}/data/mid_year_estimates/2019/ni_mye_population_2019.csv: ${PWD}/src/census_population/clean_ni_mye.py \
	${PWD}/data/mid_year_estimates/2019/ni_raw/SAPE19_SA_Totals.xlsx
	export POPULATION_YEAR="2019" && \
	$(PYTHON_INTERPRETER) $^ $@

${PWD}/data/mid_year_estimates/2020/ni_mye_population_2020.csv: ${PWD}/src/census_population/clean_ni_mye.py \
	${PWD}/data/mid_year_estimates/2020/ni_raw/SAPE20_SA_Totals.xlsx
	export POPULATION_YEAR="2020" && \
	$(PYTHON_INTERPRETER) $^ $@

${PWD}/data/mid_year_estimates/2019/scotland_dz_mye_population_2019.csv: ${PWD}/src/census_population/clean_scotland_mye.py \
	${PWD}/data/mid_year_estimates/2019/scotland_raw/sape-19-all-tabs-and-figs.xlsx
	$(PYTHON_INTERPRETER) $^ $@

${PWD}/data/mid_year_estimates/2020/scotland_dz_mye_population_2020.csv: ${PWD}/src/census_population/clean_scotland_mye.py \
	${PWD}/data/mid_year_estimates/2020/scotland_raw/sape-20-all-tabs-and-figs.xlsx
	$(PYTHON_INTERPRETER) $^ $@

${PWD}/data/mid_year_estimates/2019/scotland_oa_mye_population_2019.csv: ${PWD}/src/census_population/scotland_dz_pop_to_oa.R \
	${PWD}/data/mid_year_estimates/2019/scotland_dz_mye_population_2019.csv \
	${PWD}/data/lookups/scotland_oa_to_dz.csv
	$(R_INTERPRETER) $^ $@

${PWD}/data/mid_year_estimates/2020/scotland_oa_mye_population_2020.csv: ${PWD}/src/census_population/scotland_dz_pop_to_oa.R \
	${PWD}/data/mid_year_estimates/2020/scotland_dz_mye_population_2020.csv \
	${PWD}/data/lookups/scotland_oa_to_dz.csv
	$(R_INTERPRETER) $^ $@

${PWD}/data/mid_year_estimates/2019/uk_mye_population_2019.csv: ${PWD}/src/concat_csv.py \
		${PWD}/data/mid_year_estimates/2019/england_wales_mye_population_2019.csv \
		${PWD}/data/mid_year_estimates/2019/ni_mye_population_2019.csv \
		${PWD}/data/mid_year_estimates/2019/scotland_dz_mye_population_2019.csv
	$(PYTHON_INTERPRETER) $^ $@

${PWD}/data/mid_year_estimates/2020/uk_mye_population_2020.csv: ${PWD}/src/concat_csv.py \
		${PWD}/data/mid_year_estimates/2020/england_wales_mye_population_2020.csv \
		${PWD}/data/mid_year_estimates/2020/ni_mye_population_2020.csv \
		${PWD}/data/mid_year_estimates/2020/scotland_dz_mye_population_2020.csv
	$(PYTHON_INTERPRETER) $^ $@

# --- Create national census geography lookups ---

${PWD}/data/lookups/ni_small_area_to_tile.csv: ${PWD}/src/geometry_centroid_lookup.R \
		${PWD}/data/geometry/ni_small_areas/SA2011.shp \
		${PWD}/data/geometry/tiles_12/tiles.shp
	export RETAIN_COLNAMES="quadkey, SA2011" && \
	$(R_INTERPRETER) $^ $@

${PWD}/data/lookups/england_wales_oa_to_tile.csv: ${PWD}/src/geometry_centroid_lookup.R \
		${PWD}/data/geometry/oa_geometry/engwal_oa_bng.shp \
		${PWD}/data/geometry/tiles_12/tiles.shp
	export RETAIN_COLNAMES="quadkey, OA11CD" && \
	$(R_INTERPRETER) $^ $@

${PWD}/data/lookups/scotland_oa_to_dz.csv: ${PWD}/src/geometry_centroid_lookup.R \
		${PWD}/data/geometry/scotland_oas_2011/OutputArea2011_PWC.shp \
		${PWD}/data/geometry/scotland_data_zones_2011/SG_DataZone_Bdry_2011.shp
	export RETAIN_COLNAMES="code, DataZone" && \
	$(R_INTERPRETER) $^ $@

${PWD}/data/lookups/scotland_oa_to_tile.csv: ${PWD}/src/geometry_centroid_lookup.R \
		${PWD}/data/geometry/scotland_oas_2011/OutputArea2011_PWC.shp \
		${PWD}/data/geometry/tiles_12/tiles.shp
	export RETAIN_COLNAMES="quadkey, code" && \
	$(R_INTERPRETER) $^ $@

${PWD}/data/geometry/eng_scot_built_up_areas/eng_scot_buas.geojson: ${PWD}/src/combine_uk_buas.R \
		${PWD}/data/geometry/england_built_up_areas/Built-up_Areas_December_2011_Boundaries_V2.shp \
		${PWD}/data/geometry/scotland_built_up_areas/Settlements2020_MHW.shp
	$(R_INTERPRETER) $^ $@

${PWD}/data/lookups/tile_to_bua.csv: ${PWD}/src/geometry_centroid_lookup.R \
		${PWD}/data/geometry/tiles_12/tiles.shp \
		${PWD}/data/geometry/eng_scot_built_up_areas/eng_scot_buas.geojson
	export RETAIN_COLNAMES="quadkey, bua_code, bua_name" && \
	$(R_INTERPRETER) $^ $@

# --- Aggregate MYE to tiles ---

${PWD}/data/mid_year_estimates/2019/scotland_tile_mye_population_2019.csv: ${PWD}/src/census_population/mye_to_tile.R \
		${PWD}/data/mid_year_estimates/2019/scotland_oa_mye_population_2019.csv \
		${PWD}/data/lookups/scotland_oa_to_tile.csv
	export GEOMETRY_NAME="code" && \
	$(R_INTERPRETER) $^ $@

${PWD}/data/mid_year_estimates/2020/scotland_tile_mye_population_2020.csv: ${PWD}/src/census_population/mye_to_tile.R \
		${PWD}/data/mid_year_estimates/2020/scotland_oa_mye_population_2020.csv \
		${PWD}/data/lookups/scotland_oa_to_tile.csv
	export GEOMETRY_NAME="code" && \
	$(R_INTERPRETER) $^ $@

${PWD}/data/mid_year_estimates/2019/england_wales_tile_mye_population_2019.csv: ${PWD}/src/census_population/mye_to_tile.R \
		${PWD}/data/mid_year_estimates/2019/england_wales_mye_population_2019.csv \
		${PWD}/data/lookups/england_wales_oa_to_tile.csv
	export GEOMETRY_NAME="OA11CD" && \
	$(R_INTERPRETER) $^ $@

${PWD}/data/mid_year_estimates/2020/england_wales_tile_mye_population_2020.csv: ${PWD}/src/census_population/mye_to_tile.R \
		${PWD}/data/mid_year_estimates/2020/england_wales_mye_population_2020.csv \
		${PWD}/data/lookups/england_wales_oa_to_tile.csv
	export GEOMETRY_NAME="OA11CD" && \
	$(R_INTERPRETER) $^ $@

${PWD}/data/mid_year_estimates/2019/ni_tile_mye_population_2019.csv: ${PWD}/src/census_population/mye_to_tile.R \
		${PWD}/data/mid_year_estimates/2019/ni_mye_population_2019.csv \
		${PWD}/data/lookups/ni_small_area_to_tile.csv
	export GEOMETRY_NAME="SA2011" && \
	$(R_INTERPRETER) $^ $@

${PWD}/data/mid_year_estimates/2020/ni_tile_mye_population_2020.csv: ${PWD}/src/census_population/mye_to_tile.R \
		${PWD}/data/mid_year_estimates/2020/ni_mye_population_2020.csv \
		${PWD}/data/lookups/ni_small_area_to_tile.csv
	export GEOMETRY_NAME="SA2011" && \
	$(R_INTERPRETER) $^ $@

${PWD}/data/mid_year_estimates/tile_mye_pop_2019.csv: ${PWD}/src/concat_csv.py \
		${PWD}/data/mid_year_estimates/2019/scotland_tile_mye_population_2019.csv \
		${PWD}/data/mid_year_estimates/2019/england_wales_tile_mye_population_2019.csv \
		${PWD}/data/mid_year_estimates/2019/ni_tile_mye_population_2019.csv
	$(PYTHON_INTERPRETER) $^ $@

${PWD}/data/mid_year_estimates/tile_mye_pop_2020.csv: ${PWD}/src/concat_csv.py \
		${PWD}/data/mid_year_estimates/2020/scotland_tile_mye_population_2020.csv \
		${PWD}/data/mid_year_estimates/2020/england_wales_tile_mye_population_2020.csv \
		${PWD}/data/mid_year_estimates/2020/ni_tile_mye_population_2020.csv
	$(PYTHON_INTERPRETER) $^ $@

${PWD}/data/lookups/tile_mye_pop_deciles_2019.csv: ${PWD}/src/tile_mye_to_deciles.R \
	${PWD}/data/mid_year_estimates/tile_mye_pop_2019.csv
	$(R_INTERPRETER) $^ $@

# --- Aggregate FB population (for a specific time window) ---

${PWD}/data/Britain_TilePopulation/tile_baseline_fb_population.csv: ${PWD}/src/create_tile_fb_baseline_pop.py \
		${PWD}/data/Britain_TilePopulation/tile_fb_population.csv
	export TIME_WINDOW_HOUR='8' && \
	$(PYTHON_INTERPRETER) $^ $@

${PWD}/data/Britain_TilePopulation/tile_baseline_mye_pop_proportion.csv: ${PWD}/src/calculate_baseline_mye_proportion.R \
		${PWD}/data/Britain_TilePopulation/tile_baseline_fb_population.csv \
		${PWD}/data/mid_year_estimates/tile_mye_pop_2019.csv
	$(R_INTERPRETER) $^ $@


${PWD}/data/Britain_TilePopulation/tile_fb_population.csv: ${PWD}/src/combine_fb_pop_to_tile_12.py \
		${PWD}/data/Britain_TilePopulation/raw/*_0800.csv
	$(PYTHON_INTERPRETER) $^ $@

# --- Adjust FB population given MYE ---

${PWD}/data/Britain_TilePopulation/tile_fb_pop_adjusted_absolute.csv: ${PWD}/src/adjust_fb_pop_by_mye.R \
	${PWD}/data/Britain_TilePopulation/tile_fb_population.csv \
	${PWD}/data/Britain_TilePopulation/tile_baseline_mye_pop_proportion.csv 
	$(PYTHON_INTERPRETER) $^ $@

# --- Validation plots ---

${PWD}/output/validation/tile_mye_pop_2019_validation.png: ${PWD}/src/validation_mye_download.R \
		${PWD}/data/mid_year_estimates/tile_mye_pop_2019.csv \
		${PWD}/data/geometry/tiles_12/tiles.shp
	$(R_INTERPRETER) $^ $@

${PWD}/output/validation/tile_mye_pop_2020_validation.png: ${PWD}/src/validation_mye_download.R \
		${PWD}/data/mid_year_estimates/tile_mye_pop_2020.csv \
		${PWD}/data/geometry/tiles_12/tiles.shp
	$(R_INTERPRETER) $^ $@

# --- Publication plots ---

${PWD}/output/figs/fb_mye_2020_comparison.png: ${PWD}/src/plot_comparison_fb_mye_pop_proportional.R \
	${PWD}/data/mid_year_estimates/tile_mye_pop_2020.csv \
  ${PWD}/data/lookups/tile_mye_pop_deciles_2019.csv \
  ${PWD}/data/Britain_TilePopulation/tile_fb_population.csv
	$(R_INTERPRETER) $^ $@


#Figure 1a Baseline population for each tile (generalised or not)
#Figure 1b Raw population of FB users over time
#Figure 1c Comparison of baseline FB population to census population per tile per time window
#Figure 2a-d Existing code - make one panel per file
#Figure 2e population change in top 6 BUAs
#Figure 3. Population displacement (repeat existing with relative population)
#Figure 4a. Population change by pop decile
#Figure 4b. Population change either side of key dates
#Figure 4c. Population change by pop decile
#Figure 5. Comparison to Census population estimates
