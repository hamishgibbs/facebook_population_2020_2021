import sys
import pandas as pd

def pop_tile_13_to_tile_12(fb_pop):

    fb_pop["quadkey"] = fb_pop["quadkey"].str[:-1] # convert to tile 12

    return fb_pop.groupby(
        ["quadkey", "date_time"],
        as_index=False
        ).agg({"n_crisis": "sum"})


def main():
    usecols = ["quadkey", "date_time", "n_crisis"]
    dtype = {"quadkey": "str", "n_crisis": "float"}
    na_values = ["\\N"]

    input_fns = sys.argv[1:-1]
    daytime_pop = []

    for fn in input_fns:

        fb_pop = pd.read_csv(
            fn,
            usecols=usecols,
            dtype=dtype,
            na_values=na_values)

        fb_pop.dropna(subset="n_crisis", inplace=True)

        fb_pop["quadkey"] = fb_pop["quadkey"].str.pad(13, "left", "0") # pad out to 13 places with a 0

        daytime_pop.append(pop_tile_13_to_tile_12(fb_pop))

    pd.concat(daytime_pop).to_csv(sys.argv[-1], index=False)



if __name__ == "__main__":
    main()
