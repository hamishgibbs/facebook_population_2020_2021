
PYTHON_INTERPRETER = python3
R_INTERPRETER = /usr/local/bin/Rscript

.PHONY: default

default: \
	${PWD}/output/figs/fb_mye_2020_comparison.png \
	${PWD}/output/figs/fb_mye_population_adjustment.png \
	validation \
	${PWD}/output/figs/period_pop_change_tiles.png \
	${PWD}/output/figs/decile_pop_change.png \
	${PWD}/output/figs/case_rate_difference_bua.png

validation: \
	${PWD}/output/validation/tile_mye_pop_2020_validation.png \
	${PWD}/output/validation/tile_mye_pop_2019_validation.png \
	${PWD}/output/validation/tile_baseline_pop_validation.png \
	${PWD}/output/validation/tile_fb_mye_proportion_validation.png

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

# --- Create national census geography lookups ---

${PWD}/data/geometry/tiles_12/tiles.shp: ${PWD}/src/unique_tile_shapes.py \
		${PWD}/data/Britain_TilePopulation/raw/*.csv
	$(PYTHON_INTERPRETER) $^ $@

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
	$(PYTHON_INTERPRETER) $^ $@

${PWD}/data/Britain_TilePopulation/tile_baseline_mye_pop_proportion.csv: ${PWD}/src/calculate_baseline_mye_proportion.R \
		${PWD}/data/Britain_TilePopulation/tile_baseline_fb_population.csv \
		${PWD}/data/mid_year_estimates/tile_mye_pop_2019.csv
	$(R_INTERPRETER) $^ $@


${PWD}/data/Britain_TilePopulation/tile_fb_population.csv: ${PWD}/src/combine_fb_pop_to_tile_12.py \
		${PWD}/data/Britain_TilePopulation/raw/*.csv
	$(PYTHON_INTERPRETER) $^ $@

# --- Adjust FB population given MYE ---

${PWD}/data/Britain_TilePopulation/tile_fb_pop_adjusted_absolute.csv: ${PWD}/src/adjust_fb_pop_by_mye.R \
	${PWD}/data/Britain_TilePopulation/tile_fb_population.csv \
	${PWD}/data/Britain_TilePopulation/tile_baseline_mye_pop_proportion.csv
	$(R_INTERPRETER) $^ $@

# --- Calculate population change around key dates ---

# these 2 shouldn't be in data

${PWD}/data/period_change_pop_adjusted_absolute.rds: ${PWD}/src/2_dynamic_population_change/calculate_period_pop_change_tiles.R \
		${PWD}/data/config/periods.rds \
		${PWD}/data/Britain_TilePopulation/tile_fb_pop_adjusted_absolute.csv
	export FOCUS_HOUR_WINDOW="16" && \
	$(R_INTERPRETER) $^ $@

${PWD}/data/period_decile_change_pop_adjusted_absolute.rds: ${PWD}/src/3_population_density/calculate_period_pop_change_deciles.R \
		${PWD}/data/config/periods.rds \
		${PWD}/data/Britain_TilePopulation/tile_fb_pop_adjusted_absolute.csv \
		${PWD}/data/lookups/tile_mye_pop_deciles_2019.csv
	export FOCUS_HOUR_WINDOW="16" && \
	$(R_INTERPRETER) $^ $@

# --- Validation plots ---

${PWD}/output/validation/tile_mye_pop_2019_validation.png: ${PWD}/src/validation/univariate_tile_validation.R \
		${PWD}/data/mid_year_estimates/tile_mye_pop_2019.csv \
		${PWD}/data/geometry/tiles_12/tiles.shp
	export FILL_COLNAME="population" && \
	$(R_INTERPRETER) $^ $@

${PWD}/output/validation/tile_mye_pop_2020_validation.png: ${PWD}/src/validation/univariate_tile_validation.R \
		${PWD}/data/mid_year_estimates/tile_mye_pop_2020.csv \
		${PWD}/data/geometry/tiles_12/tiles.shp
	export FILL_COLNAME="population" && \
	$(R_INTERPRETER) $^ $@

${PWD}/output/validation/tile_baseline_pop_validation.png: ${PWD}/src/validation/univariate_tile_validation_by_hour.R \
		${PWD}/data/Britain_TilePopulation/tile_baseline_fb_population.csv \
		${PWD}/data/geometry/tiles_12/tiles.shp
	export FILL_COLNAME="n_baseline" && \
	$(R_INTERPRETER) $^ $@

${PWD}/output/validation/tile_fb_mye_proportion_validation.png: ${PWD}/src/validation/univariate_tile_validation_by_hour.R \
		${PWD}/data/Britain_TilePopulation/tile_baseline_mye_pop_proportion.csv \
		${PWD}/data/geometry/tiles_12/tiles.shp
	export FILL_COLNAME="baseline_mye_prop" && \
	$(R_INTERPRETER) $^ $@

# --- Publication plots ---

${PWD}/output/figs/fb_mye_2020_comparison.png: ${PWD}/src/plot_comparison_fb_mye_pop_proportional.R \
		${PWD}/data/mid_year_estimates/tile_mye_pop_2020.csv \
		${PWD}/data/lookups/tile_mye_pop_deciles_2019.csv \
		${PWD}/data/Britain_TilePopulation/tile_fb_pop_adjusted_absolute.csv \
		${PWD}/data/geometry/tiles_12/tiles.shp
	export FOCUS_HOUR_WINDOW="16" && \
	export PLOT_CUTOFF_DATE="2021-03-31" && \
	$(R_INTERPRETER) $^ $@

${PWD}/output/figs/fb_mye_population_adjustment.png: ${PWD}/src/1_population_overview/plot_fb_pop_adjusted_comparison.R \
		${PWD}/data/Britain_TilePopulation/tile_baseline_mye_pop_proportion.csv \
		${PWD}/data/geometry/tiles_12/tiles.shp \
		${PWD}/data/Britain_TilePopulation/tile_fb_pop_adjusted_absolute.csv \
		${PWD}/data/config/period_lines.rds \
		${PWD}/data/config/period_rectangles_inf.rds
	export FOCUS_HOUR_WINDOW="16" && \
	export PLOT_CUTOFF_DATE="2021-03-31" && \
	$(R_INTERPRETER) $^ $@

${PWD}/output/figs/bua_pop_change.rds: ${PWD}/src/2_dynamic_population_change/plot_bua_pop_change.R \
		${PWD}/data/Britain_TilePopulation/tile_fb_pop_adjusted_absolute.csv \
		${PWD}/data/Britain_TilePopulation/tile_baseline_mye_pop_proportion.csv \
		${PWD}/data/lookups/tile_to_bua.csv \
		${PWD}/data/config/period_lines.rds \
		${PWD}/data/config/period_rectangles_inf.rds
	export FOCUS_HOUR_WINDOW="16" && \
	$(R_INTERPRETER) $^ $@

${PWD}/output/figs/period_pop_change_tiles.png: ${PWD}/src/2_dynamic_population_change/plot_period_pop_change.R \
		${PWD}/data/period_change_pop_adjusted_absolute.rds \
		${PWD}/data/geometry/tiles_12/tiles.shp \
		${PWD}/data/geometry/Regions_December_2021_EN_BFC.geojson \
		${PWD}/output/figs/bua_pop_change.rds
	$(R_INTERPRETER) $^ $@

${PWD}/output/figs/decile_pop_change.png: ${PWD}/src/3_population_density/plot_fb_pop_change_per_decile.R \
		${PWD}/data/Britain_TilePopulation/tile_fb_pop_adjusted_absolute.csv \
		${PWD}/data/Britain_TilePopulation/tile_baseline_mye_pop_proportion.csv \
		${PWD}/data/period_decile_change_pop_adjusted_absolute.rds \
		${PWD}/data/lookups/tile_mye_pop_deciles_2019.csv \
		${PWD}/data/geometry/tiles_12/tiles.shp \
		${PWD}/data/config/periods.rds
	export FOCUS_HOUR_WINDOW="16" && \
	export PLOT_CUTOFF_DATE="2021-03-31" && \
	$(R_INTERPRETER) $^ $@

${PWD}/output/figs/case_rate_difference_bua.png: ${PWD}/src/4_disease_impact/cases_pop_comparison.R \
		${PWD}/data/Britain_TilePopulation/tile_fb_pop_adjusted_absolute.csv \
		${PWD}/data/Britain_TilePopulation/tile_baseline_mye_pop_proportion.csv \
		${PWD}/data/cases/cases_bua.csv \
		${PWD}/data/lookups/tile_to_bua.csv \
		${PWD}/data/config/period_lines.rds \
		${PWD}/data/config/period_rectangles_inf.rds
	export FOCUS_HOUR_WINDOW="16" && \
	export PLOT_CUTOFF_DATE="2021-03-31" && \
	$(R_INTERPRETER) $^ $@
