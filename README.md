# Bayesian analysis to infer MotoGP riders skill

<img src="https://camo.githubusercontent.com/f0c75c42d670c1153720d72688ab576936104b7b9a80ea336eeba472949394e6/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f522533452533442d332e322e342d3636363666662e737667" style="width:105px"> <img src="https://camo.githubusercontent.com/628aedf920d3cee6c4467d1f63915b015f131749861bcec4178bdeca3cf3810b/68747470733a2f2f7777772e722d706b672e6f72672f6261646765732f76657273696f6e2f75736574686973" style="width:115px"> <img src="https://camo.githubusercontent.com/7d329492423dc3eceea8e9b170b73d4f5e8d4b0c4878376bb0f94c7c91c2608e/68747470733a2f2f73766773686172652e636f6d2f692f5a68792e737667" style="width:80px"> <img src="https://img.shields.io/github/license/Naereen/StrapDown.js.svg" style="width:110px">

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

## The Framework

The model was estimated using the software package [brms](https://mc-stan.org/users/interfaces/brms) with the default priors for all parameter types. We used 4 Monte Carlo Markov Chains with 10000 iterations
and a fixed burn-in of 1000 observations.

The model will output not only the values of skill and advantage for each rider,
season and constructor but also the standard deviations of the distributions of the
parameters that are the ones we are more interested in in order to evaluate the impact.

## The Results

We are satisfied with the results obtained. In fact, both models achieved
the results we expected, that is to demonstrate that in MotoGP the rider’s ability is
much more influential than the strength of the bike (for the base model) and that in
the case of wet races this gap becomes even wider. 

Therefore, we believe that the second model is the most complete and suitable for estimating the contributions of the bike and rider in the outcome of a race also under different weather conditions.
The real strength of the model is in fact its bivalence for different weather conditions,
so it also incorporates the basic model by extending and improving it to make it able
to analyze in more detail.

Here some plots of the model outputs to better understand the results of the model:

|Posterior check|Overall performance|Skill evolution|
|:-------------------------:|:-------------------------:|:-------------------------:|
|<img width="512" src="https://user-images.githubusercontent.com/91251307/191751113-52651244-57d4-43da-9f62-b368e39652f5.png">|<img width="512" src="https://user-images.githubusercontent.com/91251307/191751245-b321c521-6258-4b9f-a6cd-26102f5c78ff.png">|<img width="512" src="https://user-images.githubusercontent.com/91251307/191751371-30a8e8f0-da51-4530-b9ac-e2eb8b503b46.png">|

## The Report

All the details of the project are extensively discussed in the [report](https://github.com/santurini/Bayesian-analysis-of-MotoGP-riders-skill/blob/main/Report.pdf) that can be found in the repository. The main results of the model and their numerical and non-numerical interpretation are discussed there for those who were interested.

<br />
<br />
<p align="center">
    <img src="https://user-images.githubusercontent.com/50860347/147412786-183da6b0-990f-4016-9f2e-0719d8066f5b.png" style="width: 100%"/>
<p>

<br />



