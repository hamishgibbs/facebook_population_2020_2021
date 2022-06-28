import sys
import pandas as pd
from pyquadkey2 import quadkey
from shapely.geometry import Polygon
import geopandas as gpd

def tile_polygon(qk):

    qk = quadkey.QuadKey(str(qk))

    a1 = qk.to_geo(anchor = 1)
    a2 = qk.to_geo(anchor = 2)
    a3 = qk.to_geo(anchor = 3)
    a4 = qk.to_geo(anchor = 5)

    bottom_l = [a1[1], a1[0]]
    bottom_r = [a4[1], a4[0]]
    top_l = [a3[1], a3[0]]
    top_r = [a2[1], a2[0]]

    return(Polygon([bottom_l, bottom_r, top_r, top_l]))

def read_pop_file_quadkeys_level_12(fn):
    fb_pop = pd.read_csv(fn,
        usecols=["quadkey"],
        dtype={"quadkey": "str"})
    fb_pop["quadkey"] = fb_pop["quadkey"].str[:-1]
    return fb_pop["quadkey"]

def main():
    pop_files = sys.argv[1:-1]
    unique_quadkeys = set()
    [unique_quadkeys.update(read_pop_file_quadkeys_level_12(fn)) for fn in pop_files]
    unique_quadkeys = list(unique_quadkeys)
    polygons = [tile_polygon(x) for x in unique_quadkeys]
    gdf = pd.DataFrame.from_dict(dict(zip(unique_quadkeys, polygons)),
        orient='index').reset_index()
    gdf.columns = ['quadkey','geometry']
    gdf = gpd.GeoDataFrame(gdf, crs=4326)

    gdf.to_file(sys.argv[-1])


if __name__ == "__main__":
    main()
