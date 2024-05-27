# nwm-NHRA-update
This repository contains documentation and code for a prototype implementation of the SF-PROMETHEE method in https://www.tandfonline.com/doi/full/10.1080/09640568.2019.1599830 being used in the Natural Hazards Risk Assessment (NHRA) upgrade by the DLCD (https://www.oregon.gov/lcd/nh/pages/risk-assessment-upgrade.aspx), contributed by Northwest Mathematics (www.northwestmath.com). 

The purpose is to explore the computational complexity and other possible issues in implementing the method as planned by the DLCD.

### References:
1. https://www.tandfonline.com/doi/full/10.1080/09640568.2019.1599830
2. https://www.cin.ufpe.br/~if703/aulas/promethee.pdf

# Method Overview
The paper applies the PROMETHEE method of multi-criteria decision analysis (MCDA) to raster data, where each grid cell is an alternative choice. In the context of the NHRA update https://www.oregon.gov/lcd/nh/pages/risk-assessment-upgrade.aspx the criteria for "choosing" an alternative are actually risk factors for e.g. floods, so the method in this case is choosing which alternatives are at most risk.

For background on PROMETHEE methods in MCDA see ref [2].

The method takes as inputs a set of weightings given by decision makers (DM's) to each criteria and constructs a partial ordering (https://en.wikipedia.org/wiki/Partially_ordered_set) of alternatives where $a\geq b$ if $a$ is at least as "preferable" to $b$. In our case an example of the relation is $a$ is at least as at risk to floods as $b$. In the literature around this it seems this partial ordering is called _outranking_ and such methods _outranking methods_. The basic idea is the resulting partial ordering captures domain expert opinion on alternatives. From the partial ordering alternatives can be analyzed and ranked (ordered). 

It should be noted that such a partial ordering actually defines a directed graph on the alternatives.

The framework also can be used to define certain scores on each alternative, for each criteria, essentially through summing edge weights in the above graph.

# Algorithm


### Inputs
- the set of alternatives (raster cells) $x_k$
- the set of criteria functions $g_j$ defined on the $x_k$. These will be the measurements/data used.
- DM weightings of each criteria $w_j$ (where $\sum w_j = 1$)
### Parameters
- Parametric preference functions $F_j:\mathbb R \to [0,1]$ for each criterion. Technically these are also set with DM input so that the function matches their "scale" on each criteria (see https://www.cin.ufpe.br/~if703/aulas/promethee.pdf)

### Algorithm
Given the above, proceed as follows:
$$d_j(x_i,x_k) = g_j(x_i)-g_j(x_k) \tag{d}$$
$$P_j(x_i,x_k) = F_j(d_j(x_i,x_k))$$
$$\pi(x_i,x_k) = \sum_j w_j P_j(x_i,x_k)$$
$\pi$ thus defines a complete directed graph. Note also the following properties of $\pi$:
- $\pi(a,a) =0$
- $0\leq \pi(a,b)\leq 1$
- $0\leq \pi(a,b)+\pi(b,a)\leq 1$

From this graph the following _outranking flows_ are defined:

$$\Phi^+(x_i) = \frac 1{m-1}\sum_{k=1}^m\pi(x_i,x_k)$$
$$\Phi^-(x_i) = \frac 1{m-1}\sum_{k=1}^m\pi(x_k,x_i)$$

From these the PROMETHEE type 1 partial ranking is defined:
- $a$ is preferable to $b$, denoted $aP^1b$, if $$\Phi^+(a)>\Phi^+(b) \text{ and }\Phi^-(a)\leq \Phi^-(b)$$ or if 
$$\Phi^+(a)=\Phi^+(b) \text{ and }\Phi^-(a)< \Phi^-(b)$$
- $a$ and $b$ are equivalent, denoted $aI^1b$ (I denotes indifference in the literature) if
$$\Phi^+(a)=\Phi^+(b) \text{ and }\Phi^-(a)= \Phi^-(b)$$
- $a$ and $b$ are incompatible or incomparable (no preference can be deduced from the data), denoted $aR^1b$, if $$\Phi^+(a)>\Phi^+(b) \text{ and }\Phi^-(a)> \Phi^-(b)$$ or if 
$$\Phi^+(a)<\Phi^+(b) \text{ and }\Phi^-(a)< \Phi^-(b)$$

When $aR^1b$ then it is up to DM's to decide which alternative to choose between $a$ and $b$. If there are too many incomparable alternatives the output of the method is not very useful, and either more data or another ranking is required.

In the latter case, the so called PROMETHEE type 2 complete ranking is given by:
$$\Phi(x) = \Phi^+(x)-\Phi^-(x)$$
- $aP^2b$ if $$\Phi(a)>\Phi(b)$$
- $aI^2b$ if 
$$\Phi(a)=\Phi(b)$$

Thus in this case $a$ is either preferable or equivalent to $b$, but it should be noted this completeness comes at the cost of information lost in the definition of $\Phi$. Note that 
$$-1\leq\Phi(a)\leq 1$$
$$\sum_a\Phi(a) = 0$$

It is suggested that both the type 1 and type 2 rankings be considered, as consideration of the incomparables can provide useful insight in reaching a final decision.

From these one can also build so called _alternative profiles_ (basically marginals) as follows:
$$\Phi_j^+(x_i) = \frac 1{m-1}\sum_{k=1}^mP_j(x_i,x_k)$$
$$\Phi_j^-(x_i)  = \frac 1{m-1}\sum_{k=1}^mP_j(x_k,x_i)$$
$$\Phi_j(x_i)  = \Phi_j^+(x_i)  - \Phi_j^-(x_i) $$

We then of course have 
$$\Phi(x_i) = \sum_j w_j \Phi_j(x_i),$$
which the authors say gives a useful way of visualizing the various scores for alternatives viewed as layered raster grids.

# Implementation
 ## computational complexity
The computational complexity of $\pi$ is $O(m^2)$ where as above $m$ is the number of alternatives $x_i$. This can be seen by recognizing $\pi$ as the adjacency of a complete graph on $m$ vertices, or verfied directly from the above formulas. Therefor the computatoinal complexity of $\Phi_j^+$ is $O(m^3)$, being the row sum of $\pi$ (and likewise for $\Phi_j^-$). 

To cost of computing the full $\Phi = \sum_j w_j \Phi_j$ is thus $O(n*m^3)$ where $n$ is the number of criteria. In other words, the computational complexity of the SF-Promethee method is _linear_ in the number of criteria, but _polynomial_ in the number of alternatives. This clearly makes a naive implementation infeasible for moderately large numbers of alternatives.

However, the computation over the alternatives can be carried out _in parallel_, thus making it tractable. We implement here a simple parallel computation on an Nvidia A5500 laptop gpu where we parallelize over the alternatives $x_i$ in the outer loop of a double loop to compute the sum $\Phi_j^+$ in place (see the kernel `pairwisecompare1D`).

## Data, weights and preference functions
We use synthetic data generated as stanard normal random variables, and a simple RELU function for all the preference functions (called Type V in ref[1]). We use uniform random weights. 

 # Discussion
 ## Runtime
 Oregon is about 254806 km², so as pretty strong test let us assume we have raster data with .5km² cells covering all of Oregon. This would give us $m=4\cdot 254,806 = 1,019,224$ alternatives. 

We find that with this $m$ the computation of $\Phi_j^+$ and $\Phi_j^-$ together take about $4$ seconds per criteria (see `speedtest1D`), so e.g. one criteria takes about $4$ seconds, $30$ criteria takes about $120$ seconds, etc. Given it seems unlikely that the resolution of actual data being used in the NHRA will be much smaller than this, the simple paralelization given here should be sufficient to carry out testing and implementation of the method.

## Fuzzy numbers
In ref [1] the authors state that "To reduce computational complexity, the application of PROMETHEE fuzzy extensions is proposed," and, the authors claim, "the approach significantly reduces the computational load needed for the typical version of the PROMETHEE method." In other words, the reason for inclusion of fuzzy numbers in their algorithm is "due to computational limitations that arise from the need to perform pairwise comparisons for every cell (pixel) in the examined area" Moreover, the use of fuzzy numbers in the method results in information loss ("defuzzification approach implementation causes loss of information") as the fuzzy numbers are essentially arithmetic averages, and at the end sharp, "defuzzified" numbers are output.

We decided to not use any fuzzy numbers, since the above shows that some straightforward parallelism alleviates the major computational challenge of the method. Thus we gain speed without additional loss  of information.

## DM Inputs: weights and preference functions
 PROMETHEE methods like that used here are meant as a way to quantify and aggregrate the opinions of domain experts and decision makers for choosing among alternatives. In our setting, the idea would be to take the opinions of domain experts in ranking the susceptibility or risk of various locations accross the state to various natural hazards.

 The way these opinions are quantified is through domain experts assigning weights, e.g. via surveys, to criteria (risk factors or indicators), as well as choosing preference functions that reflect the scale of importance of differences (how much difference is meaningful) between mesurements within each criteria.

 However, it is possible to take a completely agnostic approach by using only uniform weighting, and re-scaling each criteria to a common scale (e.g. center and divide by standard deviation), and using a single preference function for all computations as we have here.

 Either way, assinging weights via survey or making no distinctions between criteria, is a choice that will impact the outputs of the model. Further discussion of this point would seem useful.
 
 One way to gain clarity on which course of action might be best would be to do some sensitivity analysis on the method, experimentally testing the impact of different weightings or preference functions on output.

 ## Data quality
The method in ref [1] appears to make no allowances for missing data, but assinging weights to criteria with more poorly sampled data may be one way to account for this. Alternatively, it may be possible to extend the above method to take noise into account and thus somehow incorporate measurement error or other uncertainty about the data into account, but this would require further investigation.

