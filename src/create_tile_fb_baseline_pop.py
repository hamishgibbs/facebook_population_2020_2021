import os
import sys
import pandas as pd

def main():
    dtype = {"quadkey": "str"}
    pop = pd.read_csv(sys.argv[1], dtype=dtype, parse_dates=["date_time"])
    pop["hour"] = pop['date_time'].dt.hour

    pop_median_baseline = pop.groupby(["quadkey", "hour"], as_index=False).agg({"n_baseline": "median"})

    pop_median_baseline.to_csv(sys.argv[-1], index=False)

if __name__ == "__main__":
    main()
