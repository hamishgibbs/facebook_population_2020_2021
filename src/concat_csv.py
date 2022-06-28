import sys
import pandas as pd

def main():
    in_files = sys.argv[1:-1]
    combined = pd.concat([pd.read_csv(x) for x in in_files])
    combined.to_csv(sys.argv[-1], index=False)

if __name__ == "__main__":
    main()
