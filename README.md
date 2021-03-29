
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Disaster Victim Identification using library **dvir**

## Installation

To get the latest version, install from GitHub as follows:

``` r
 # First install devtools if needed
if(!require(devtools)) install.packages("devtools")

# Install dvir from GitHub
devtools::install_github("thoree/dvir")
```

The implementation relies heavily on the `ped suite` of R-libraries, in
particular **forrel** and **pedmut**.

## Tutorial example

The library **dvir** deals with computational aspects of DNA based
disaster victim identification (DVI). We use a toy example from the
preprint <https://www.researchsquare.com/article/rs-296414/v1> of the
paper “Joint DNA-based disaster victim identification” by Vigeland and
Egeland to illustrate DVI problems. The post mortem (PM) data in the
below figure consists of 3 victim samples to be matched against 3
missing persons (red) belonging to two different families. The AM data
contains profiles from the reference individuals R1 and R2 (blue), one
from each family. The hatched individuals are typed with a single marker
having 10 equifrequent alleles denoted 1, 2,…, 10.

<img src="man/figures/README-example-1.png" width="50%" />

There are 14 possible solutions or *assignments* and these are listed
next:

    #>    V1 V2 V3
    #> 1  M1 M2 M3
    #> 2  M1 M2  *
    #> 3   * M2 M3
    #> 4  M1  * M3
    #> 5   * M1 M3
    #> 6   * M2  *
    #> 7   *  * M3
    #> 8  M1  *  *
    #> 9   * M1  *
    #> 10  *  *  *
    #> 11 M2 M1 M3
    #> 12 M2 M1  *
    #> 13 M2  * M3
    #> 14 M2  *  *

The first line gives the assignment where V1 = M1, V2 = M2 and V3 = M3
while line 10 shows the *null model* corresponding to no victims
identified. For each assignment *a* we can calculate the likelihood,
denoted *L(a)*. The null likelihood is *L0*.

There are two main goals:

1)  Rank the assignments according to how likely they are. Calculate the
    LR comparing each assignment *a* to the null model., i.e.,
    LR=*L(a)/L0* . The assignments in the above table are sorted
    according to decreasing LR as we will see later.

2)  Find the posterior pairing and non pairing probabilities. These are
    defined as

*P(Vi = Mj* | data) and *P(Vi =* ’\*’ | data) for *i, j = 1, 2, 3*.

We next describe how to do the calculations to meet goals 1 and 2.

### The data

The data are available within the library and can be extracted as
follows

``` r
library(dvir)
pm = example2$pm
am = example2$am
missing = example2$missing
```

Alternatively, we can do the input from scratch as shown below

``` r
library(pedtools)
loc = list(name = "L1", 
           alleles = 1:10,
           afreq = rep(1/10,10))

# PM data
victims = paste0("V", 1:3)

pm.df = data.frame(famid = victims, id = victims,
                   fid = 0, mid = 0, sex = c(1, 1, 2),
                   L1 = c("1/1", "1/2", "3/4"))
pm = as.ped(pm.df, locusAttributes = loc)

# AM data
am1 = nuclearPed(father = "M1", mother = "R1", child = "M2")
L1 = marker(am1, "R1" = "2/2", name = "L1", alleles = loc$alleles, afreq = loc$afreq)
am1 = setMarkers(am1, L1)

am2 = nuclearPed(father = "R2", mother = "MO2", child = "M3", sex = 2)
L1 = marker(am2, "R2" = "3/3", name = "L1", alleles = loc$alleles, afreq = loc$afreq)
am2 = setMarkers(am2, L1)

am = list(am1, am2)

missing = c("M1", "M2", "M3")
```

### Calculation

The code and output below address the goals formulated in items 1 and 2:

``` r
jointRes = jointDVI(pm, am, missing, verbose = FALSE)
jointRes
#>    V1 V2 V3    loglik  LR   posterior
#> 1  M1 M2 M3 -16.11810 250 0.718390805
#> 2  M1 M2  * -17.72753  50 0.143678161
#> 3   * M2 M3 -18.42068  25 0.071839080
#> 4  M1  * M3 -20.03012   5 0.014367816
#> 5   * M1 M3 -20.03012   5 0.014367816
#> 6   * M2  * -20.03012   5 0.014367816
#> 7   *  * M3 -20.03012   5 0.014367816
#> 8  M1  *  * -21.63956   1 0.002873563
#> 9   * M1  * -21.63956   1 0.002873563
#> 10  *  *  * -21.63956   1 0.002873563
```

and

``` r
Bmarginal(jointRes, missing, prior = NULL)
#>            M1        M2        M3          *
#> V1 0.87931034 0.0000000 0.0000000 0.12068966
#> V2 0.01724138 0.9482759 0.0000000 0.03448276
#> V3 0.00000000 0.0000000 0.8333333 0.16666667
```

In both cases we have used a default flat prior assigning equal prior
probabilities to all assignments. The prior does not influence the LR.
The most likely joint solution V1 = M1, V2 = M2, V3 = M3 gets an LR of
250 compared to the null model. From the lower table we see that the
posterior pairing probabilities are

*P(V1 = M1* | data) = 0.88, *P(V2 = M2* | data) =0.95 and *P(V3 = M2*
|data) =0.83.