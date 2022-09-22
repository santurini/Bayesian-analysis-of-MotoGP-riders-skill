# Bayesian analysis to infer MotoGP riders skill

In this repository it has been implemented a Bayesian model that is able to quantify and
discern, in a sports racing context, the skill of the rider from the advantage given by
the constructor. 

To be able to do that we will use a multilevel Beta regression that
models the individual race success as the proportion of outperformed competitors, as
described in [van Kesteren and Bergkamp, 2022](https://arxiv.org/pdf/2203.08489.pdf).

## The Data

The model was applied to the MotoGP 2016-2021 seasons data that were scraped from
the official [MotoGP](https://www.motogp.com/en/world-standing/2022/MotoGP/Championship) web page and available at the following [link](https://observablehq.com/@piratus/motogp-results-database) as csv files. All the trasnformation can be found in the code and are explained in the report.

This are the first five records of the dataset:
|Year|Sequence|Rider           |Constructor           |Position|Weather|POC|POC smoothed|
|:------|:------|:----------------------------|:---------------------------|:------|:------|:------|:------|
| 2016 | 1 | Jorge Lorenzo | Yamaha Factory | 1 | Dry | 1.00 | 0.97 |
| 2016 | 1 | Andrea Dovizioso | Ducati | 2 | Dry | 0.93 | 0.90 |
| 2016 | 1 | Marc Marquez | Repsol Honda Team | 3 | Dry | 0.86 | 0.83 |
| 2016 | 1 | Valentino Rossi | Yamaha Factory | 4 | Dry | 0.79 | 0.77 |
| 2016 | 1 | Dani Pedrosa | Repsol Honda Team | 5 | Dry | 0.71 | 0.70 |

## The Model

The proposed model is a multilevel Beta regression to estimate the smoothed POC
but, as said before, what we are more interested in is the mean of the Beta distribution
that is obtained as a sum of the rider skill and constructor advantage.

For each rider r and for each constructor c we specify two parameters: the long term
skill/advantage and the seasonal one.

$$
y_{rcs} \sim Beta(\mu_{rcs}, \ \phi), \ \phi = dispersion
$$

$$
\mu_{rcs} = \beta_r + \beta_{rs} + \beta_c + \beta_{cs}
$$

$$
\beta_r \sim N(0, \sigma_r^2)
$$

$$
\beta_{rs} \sim N(0, \sigma_{rs}^2)
$$

$$
\beta_c \sim N(0, \sigma_c^2)
$$

$$
\beta_{cs} \sim N(0, \sigma_{cs}^2)
$$

When taking into account also the weather impact as a boolean variable $\gamma_{1r}$ :

$$
\beta_r = \gamma_{0r} + \gamma_{1r} \cdot weather
$$

