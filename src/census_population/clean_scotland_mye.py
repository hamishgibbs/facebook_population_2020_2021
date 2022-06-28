import os
import sys
import pandas as pd

def main():
    pop = pd.read_excel(sys.argv[1], sheet_name="TabA", skiprows=2)
    pop.drop(index=[0, 1, 2], axis=0, inplace=True) # Drop hidden rows from top.
    pop.reset_index(inplace=True)
    pop.drop(index=[pop.shape[0]-2, pop.shape[0]-1], inplace=True) # drop copyright from the bottom. What is Scotland doing?
    pop.drop(index=[0, 1, 2], axis=0, inplace=True)
    pop.reset_index(inplace=True)
    colname_mapping = {
        "Total population": "population",
        "DataZone2011Code": "area_code"
    }
    pop.rename(columns=colname_mapping, inplace=True)
    pop[["area_code", "population"]].to_csv(sys.argv[-1], index=False)

if __name__ == "__main__":
    main()
