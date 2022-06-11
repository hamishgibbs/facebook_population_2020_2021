# script to combine Mid-year population estimates into one file
import sys
import pandas as pd

def main():
    if "2020" in sys.argv[1]:
        year = "2020"
    else:
        year = "2019"

    sheet_name = f"Mid-{year} Persons"
    input_fns = sys.argv[1:-1]

    combined_mye = []
    for fn in input_fns:
        pop = pd.read_excel(fn,
            sheet_name=sheet_name,
            skiprows=4)[["OA11CD", "All Ages"]]
        pop.rename(columns={"All Ages": "population"}, inplace=True)
        combined_mye.append(pop)
    combined_mye = pd.concat(combined_mye)
    assert combined_mye.shape[0] == 181_408 # The number of OAs in England and Wales
    combined_mye.to_csv(sys.argv[-1], index=False)

if __name__ == "__main__":
    main()
