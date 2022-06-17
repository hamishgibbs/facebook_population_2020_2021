import os
import sys
import pandas as pd

def main():
    dtype = {"quadkey": "str"}
    mob = pd.read_csv(sys.argv[1], dtype=dtype, parse_dates=["date_time"])
    time_window = int(os.environ["TIME_WINDOW_HOUR"])

    mob_period_subset = mob[mob['date_time'].dt.hour == time_window]
    mob_median_baseline = mob_period_subset.groupby("quadkey", as_index=False).agg({"n_baseline": "median"})

    mob_median_baseline.to_csv(sys.argv[-1], index=False)




if __name__ == "__main__":
    main()
