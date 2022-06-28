import os
import sys
import pandas as pd

def main():
    year = int(os.environ["POPULATION_YEAR"])
    pop = pd.read_excel(sys.argv[1], sheet_name="Flat")
    pop = pop[pop["Year"] == year]
    colname_mapping = {
        "MYE": "population",
        "Area_Code": "area_code"
    }
    pop.rename(columns=colname_mapping, inplace=True)
    pop[["area_code", "population"]].to_csv(sys.argv[-1], index=False)

if __name__ == "__main__":
    main()
