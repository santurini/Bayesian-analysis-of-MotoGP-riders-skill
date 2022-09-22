# Bayesian analysis to infer MotoGP riders skill

In this repository it has been implemented a Bayesian model that is able to quantify and
discern, in a sports racing context, the skill of the rider from the advantage given by
the constructor. 

To be able to do that we will use a multilevel Beta regression that
models the individual race success as the proportion of outperformed competitors, as
described in [van Kesteren and Bergkamp, 2022](https://arxiv.org/pdf/2203.08489.pdf).

## The Data

The model was applied to the MotoGP 2016-2021 seasons data that were scraped from
the official [MotoGP](https://www.motogp.com/en/world-standing/2022/MotoGP/Championship) web page and available at the following [link](https://observablehq.com/@piratus/motogp-results-database) as csv files.

This are the first five records of the dataset:
|Year|Sequence|Rider           |Constructor           |Position|Weather|POC|POC smoothed|
|:------|:------|:----------------------------|:---------------------------|:------|:------|:------|:------|
| 2016 | 1 | Jorge Lorenzo | Yamaha Factory | 1 | Dry | 1.00 | 0.97 |
| 2016 | 1 | Andrea Dovizioso | Ducati | 2 | Dry | 0.93 | 0.90 |
| 2016 | 1 | Marc Marquez | Repsol Honda Team | 3 | Dry | 0.86 | 0.83 |
| 2016 | 1 | Valentino Rossi | Yamaha Factory | 4 | Dry | 0.79 | 0.77 |
| 2016 | 1 | Dani Pedrosa | Repsol Honda Team | 5 | Dry | 0.71 | 0.70 |




