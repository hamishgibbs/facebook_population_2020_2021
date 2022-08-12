# facebook_population_2020_2021

Code supporting the paper "Population disruption: estimating changes in population distribution of the UK during the COVID-19 pandemic", Gibbs et al.

## Data Availability

The terms of use of data from the Facebook Data for Good Program prohibit unauthorised distribution. Data is available from the Facebook Data for Good Partner Program by application.

Boundary data for UK administrative geographies is available from the UK Government [Open Geography Portal](https://geoportal.statistics.gov.uk/). Administrative Datasets used in this study:

* Local Authority Districts (2019)
* Built-up Areas (2011)
* Middle-layer Super Output Areas (2011)

Tile boundaries were extracted using the [pyquadkey2](https://pypi.org/project/pyquadkey2/) library.

## Dependencies

This project was written in `R (3.6.3)` and relies on the following R packages:

* `tidyverse (1.3.0)`
* `ggplot2 (3.3.3)`
* `sf (0.9.6)`
* `ggpubr (0.2.5)`
* `deSolve (1.28)`
* `data.table (1.13.2)`
* `here (0.1)`
* `dplyr (1.0.2)`

## Contributions

Have questions or find an issue with this code? Please [open an issue](https://github.com/hamishgibbs/facebook_population_2020_2021/issues/new/choose).

