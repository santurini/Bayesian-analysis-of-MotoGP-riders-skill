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

<img src="https://user-images.githubusercontent.com/91251307/191746247-f11ecc1d-6d1c-4278-825e-5811e36df9d0.png" style="width:800px">





