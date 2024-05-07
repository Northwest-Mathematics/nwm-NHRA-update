# nwm-NHRA-update
Parallel implementation of SF-PROMETHEE method in https://www.tandfonline.com/doi/full/10.1080/09640568.2019.1599830

# Method Overview
The paper applies the PROMETHEE method of multi-criteria decision analysis (MCDA) to raster data, where each grid cell is an alternative choice. In the context of the NHRA update https://www.oregon.gov/lcd/nh/pages/risk-assessment-upgrade.aspx the criteria for "choosing" an alternative are actually risk factors for e.g. floods, so the method in this case is choosing which alternatives are at most risk.

For background on PROMETHEE methods in MCDA see https://www.cin.ufpe.br/~if703/aulas/promethee.pdf

The method takes as inputs a set of weightings given by decision makers (DM's) to each criteria and constructs a partial ordering of alternatives where $a\geq b$ if $a$ is at least as "preferable" to $b$. In our case the relation is $a$ is at least as at risk to floods as $b$. In the literature around this it seems this partial ordering is called _outranking_ and such methods _outranking methods_. The basic idea is the resulting partial ordering captures domain expert opinion on alternatives. From the partial ordering alternatives can be analyzed and ranked (ordered). 

It should be noted that such a partial ordering actually defines a directed graph on the alternatives.

The framework also can be used to define certain scores on each alternative, for each criteria, essentially through summing edge weights in the above graph.

# Details


### Inputs
- the set of alternatives (raster cells) $x_k$
- the set of criteria functions $g_j$ defined on the $x_k$
- DM weightings of each criteria $w_j$ (where $\sum w_j = 1$)
### Parameters
- Parametric preference functions $F_j:\mathbb R \to [0,1]$ for each criterion

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