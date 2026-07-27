# Global Equity Risk Model (verbatim prose, converted from LaTeX)

> Converted from LaTeX: equations kept in inline notation without styling commands,
> figure includes replaced by their captions, footnotes inlined in [brackets].
> Lightly copyedited.

## INTRODUCTION

The definition of equity risk measurement has evolved from the calculation of sample statistics (e.g., standard deviation of stock returns) to advanced fundamental factor models. The multi-factor model enables a deeper understanding of portfolio risk exposures to common or stock-specific risk factors.

### Diversification, Correlation, and Complexity

Diversification in portfolio management stems from the idea that active managers *aren't* perfect forecasters of returns. If a manager somehow possessed this skill, the ideal long-only portfolio would consist of only one asset: the asset for which the manager predicted the highest return. A single-asset portfolio is bad financial advice because there is a degree of uncertainty in return forecasting. Diversification, therefore, is the attempt to immunize the active portfolio from disastrous errors in the return forecast.

For the purpose of mitigating the impact of forecasting errors, *correlations matter*. Unlike asset returns, prior asset correlations and covariances tend to be reasonable predictors of future asset correlations and covariances. Unfortunately, the estimation of covariance terms suitable for portfolio analysis is difficult. For example, if one has a portfolio consisting of $N$ different assets, they must estimate $(N^2 - N)/2$ unique covariance terms to capture all the pairwise co-movement in their portfolio. In the case of a 300-stock portfolio, one would need to estimate 44,850 unique parameters! The sheer number of required parameters renders many of the estimated parameters susceptible to spurious relationships that are unlikely to hold out of sample and would be ill-suited for portfolio optimization and analysis.

### The Factor Approach

Factor models provide a unique way to get around this problem by relying on the idea that variation in stock returns can be split into variation that is *common* among all stocks and variation that is *stock-specific* or *idiosyncratic*. For example, the Capital Asset Pricing Model (a very simple factor model) assumes that all common variation in stock returns can be explained by the excess returns of the market over treasuries [Technically, the model outlined in equation (1) is not the CAPM as $r_{i,t}$ should represent the excess returns of asset $i$ over treasuries, not the raw return.].

$$r_{i,t} = \alpha_i + \beta_i (r_{m,t} - r_{f,t}) + \epsilon_{i,t} \tag{1}$$

Where $r_{m,t}$ and $r_{f,t}$ represent the returns on the market portfolio and the risk-free rate, $\alpha_i$ and $\beta_i$ represent the regression model's intercept and slope (also called *sensitivity*), and $\epsilon_{i,t}$ represents the component of stock $i$'s return that is firm-specific.

Given common results from statistics and the equation expressed in (1), we can write the variance of stock $i$ and its covariance with another stock as:

$$Var(r_{i,t}) = \beta_i^2 Var(r_{m,t} - r_{f,t}) + Var(\epsilon_{i,t}) \tag{2}$$
$$Cov(r_i, r_j) = \beta_i \beta_j Var(r_{m,t} - r_{f,t}) \tag{3}$$

Hence, under the assumptions of the simple factor model, all we need to estimate the covariance matrix are estimates of $\beta_i$ and $Var(\epsilon_{i,t})$ for every stock and a single estimate of $Var(r_{m,t} - r_{f,t})$. The factor model dramatically reduces the number of unique parameters that need to be estimated for a 300-stock portfolio from 44,850 to 601. If we can specify a reasonable factor model with sufficient factors such that $Var(\epsilon_{i,t})$ and $Var(\epsilon_{j,t})$ are truly independent for any stocks $i$ and $j$, we should be able to reduce the dimensionality of the estimation process as specified above. With a correctly specified factor model, the reduction in complexity results in correlation forecasts that are much more stable and conducive to portfolio optimization.

## ESTIMATION UNIVERSE

Factor model construction involves the computation of a time series of daily factor returns from available data (equity returns, exposures, country and industry affiliations) by cross-sectional regression. This requires a list of securities to enter the regression at each cross-section—an *estimation universe* that is representative of the global market and, at the same time, characterized by high-quality market data that can be used to capture the common structure in equity market returns.

The initial estimation universe is defined by the MSCI ACWI Investable Market Index (IMI) and adjusted to include only those securities with available price history, industry and region classification, and fundamental reporting data [Price data and region classification provided by DataStream equities, industry classifications provided by S&P Global, and fundamental data provided by Thomson Reuters.]. The estimation universe is expanded to include certain regions not included in the MSCI ACWI IMI (e.g., Vietnam), where stringent market cap and liquidity constraints are applied to exclude securities that could be structurally driven by idiosyncratic events. For each expanded region the constraints are as follows:

- No over-the-counter (OTC) listings
- Annualized long-term share turnover greater than 10% [Defined in style factor methodology.]
- Market capitalization above the region's bottom decile

Additionally, only the primary security for each corporate entity [As defined by DataStream] is included in the estimation universe. After making the previously listed adjustments to the IMI, the model's estimation universe represents more than 99% of the float-adjusted global stock market. The size of the estimation universe, as determined by market capitalization and company count, is reported in Figures 1 and 2.

*Figure: Aggregate market capitalization of estimation universe (trillions of USD), broken out by region.*

*Figure: Number of companies in estimation universe, broken out by region.*

### Coverage Universe

While the size of the estimation universe tends to stay around 8,000 companies, this number is merely the sample size used to calibrate the risk model (i.e., the estimation universe is only used to generate the factor returns and determine the appropriate trimming of outliers within the model). In practice, the model can be extended to a much broader *coverage universe* to which it is applicable. Figure 3 illustrates that this coverage universe constituted approximately 45,000 companies at the end of calendar year 2023.

*Figure: Number of companies in coverage universe (top) and estimation universe (bottom) over time.*

## FACTOR EXPOSURES

### Style Factors

Style factor exposures are based on market and financial reporting data. In selecting robust style factors, we want to ensure that:

1. The factor characteristics explain cross-sectional variability in stock returns
2. The factor characteristics are reasonably uncorrelated

The first criterion calls for the selection of statistically significant factors that adequately explain the variability of stock returns. This explanatory power is the primary objective of a risk model. The second criterion is critical because, in the case of strongly correlated factor exposures, it could be difficult to distinguish the factors' effects on portfolio risk (Rosenberg & Perry).

In determining how many style factors to include in the model, we refer to the expansive corpus of factor-investing literature. This literature ranges from the seminal work of Sharpe, Lintner, and Mossin to the subsequent advances made by Fama and French and Carhart. The included factors are required to have a statistical impact across various time periods. They also appear to be in an undisputed subset, serving as core elements in many studies as reviewed by Hou et al. where the authors discuss size, dividend yield, earnings yield, book-to-price, leverage, momentum, liquidity, and growth factors. Guided by this literature, the following style factors have been used.

#### Beta

Beta is defined as the regression slope coefficient of a stock's weekly returns relative to the global market over the last 104 weeks. Beta exposures are standardized globally.

$$BETA_{i,m} = \frac{Cov(r_i, r_m)}{Var(r_m)} \times \frac{2}{3} + \frac{1}{3} \tag{4}$$

Where $Cov(r_i, r_m)$ is the 104-week covariance of weekly returns between stock $i$ and the global market. $Var(r_m)$ is the 104-week variance of weekly global market returns. The remainder of the equation constitutes a shrinkage adjustment, proposed in Vasicek, meant to compensate for the observed mean reversion of betas.

If return observations are sparse, the beta estimate will be shrunk towards the median industry beta of the estimation universe. The shrinkage intensity scales linearly depending on how many nonzero weekly return observations are present. At 30 or fewer observations, 100% shrinkage is applied. At 100 or more observations, 0% shrinkage is applied.

#### Volatility

Volatility is defined as the sample standard deviation of daily returns over the last 260 business days. Volatility exposures are standardized globally.

$$VOLATILITY_i = \sqrt{\frac{\sum_{t=1}^{260}(r_{i,t} - \bar{r})^2}{260 - 1}} \tag{5}$$

Where $r_{i,t}$ is the return of stock $i$ on day $t$ of 260. The same shrinkage procedure applied to betas is applied to volatility, with the 100% and 0% shrinkage breakpoints at 21 and 220 observations, respectively [Note that there are typically only 252 trading observations in a 1-year look-back window.].

#### Momentum

Momentum is defined as the sum of daily log returns over the last 260 business days, excluding the most recent 22 business days. Momentum exposures are standardized globally.

$$MOMENTUM_i = \sum_{t=1}^{260-22} \ln(1 + r_{i,t}) \tag{6}$$

Where $r_{i,t}$ is the return of stock $i$ on day $t$. The same shrinkage procedure and breakpoints used for volatilities are also used for momentum.

#### Reversal

Reversal is defined as the sum of daily log returns over the last 22 business days. Reversal exposures are standardized globally.

$$REVERSAL_i = \sum_{t=1}^{22} \ln(1 + r_{i,t}) \tag{7}$$

Where $r_{i,t}$ is the return of stock $i$ on day $t$. The same shrinkage procedure applied to betas, volatilities, and momentum is applied to reversal, with the 100% and 0% shrinkage breakpoints at 11 and 18 observations, respectively.

#### Yield

Dividend yield is defined as the ratio of total dividend amount per share paid over the last 260 business days to the latest share price. Yield exposures are standardized globally.

$$YIELD_i = \frac{\sum_{t=1}^{260} D_{i,t}}{P_{i,260}} \tag{8}$$

Where $D_{i,t}$ and $P_{i,t}$ are the per-share dividend and price of stock $i$ on day $t$. Unlike other factors, which employ shrinkage methods to deal with data sparsity, null dividend yields are intuitively set equal to zero.

#### Size

Size is defined as the log of a company's most recent float-adjusted market capitalization. Size exposures are standardized locally.

$$SIZE_i = \ln(P_{i,t} \times S_{i,t}) \tag{9}$$

Where $P_{i,t}$ and $S_{i,t}$ are the price and float-adjusted shares outstanding of stock $i$ on day $t$.

#### Liquidity

Liquidity is defined as the weighted combination of two components: 1) share turnover over the last month (22 business days) and 2) share turnover over the last 3 months (66 business days), with weights of 0.75 and 0.25, respectively. Liquidity exposures are standardized locally.

$$LIQ_{i,ST} = \ln\left(\frac{\sum_{t=1}^{22} V_{i,t}}{S_{i,22}}\right) \tag{10}$$
$$LIQ_{i,LT} = \ln\left(\frac{\sum_{t=1}^{66} V_{i,t}}{S_{i,66}}\right) \tag{11}$$
$$LIQUIDITY_i = LIQ_{i,ST} \times 0.75 + LIQ_{i,LT} \times 0.25 \tag{12}$$

Where $V_{i,t}$ and $S_{i,t}$ are the volume and shares outstanding of stock $i$ on day $t$.

#### Growth

Growth is defined as the average of three components: 1) linear trend slope coefficient of trailing earnings per share over the last 5 years, 2) linear trend slope coefficient of trailing operating cash flow per share over the last 5 years, and 3) analyst-estimated long-term earnings growth [Provided by IBES.]. Growth exposures are standardized locally. The trend slope coefficients follow the standard regression form.

$$y = \beta_0 + \beta_1 X + \epsilon \tag{13}$$

Where $y$ is the dependent variable (per-share earnings or cash flow), $X$ is a numerically expressed time series component associated with each financial filing, $\beta_0$ is an intercept term, $\beta_1$ is the trend coefficient, and $\epsilon$ is an error term. The slope coefficient is then standardized, as follows, to account for different currency scales in the dependent variable.

$$\beta_{std} = \beta_1 / \sigma_y \tag{14}$$

Where $\beta_{std}$ is the standardized slope coefficient, and $\sigma_y$ is the sample standard deviation of the dependent variable.

$$GROWTH_i = \frac{\beta_{i,e} + \beta_{i,c} + LTG_i}{3} \tag{15}$$

Where $\beta_{i,e}$ and $\beta_{i,c}$ are the standardized trend coefficients on per-share earnings and cash flow for stock $i$, and $LTG_i$ is the long-term growth estimate.

#### Earnings Yield

Earnings yield is defined as the average of three components: 1) trailing earnings yield, 2) trailing operating cash flow yield, and 3) analyst-estimated forward earnings yield. Earnings yield exposures are standardized locally.

$$Y_{i,e} = \frac{E_{i,trailing}}{P_{i,t}} \tag{16}$$
$$Y_{i,c} = \frac{C_{i,trailing}}{P_{i,t}} \tag{17}$$
$$Y_{i,exp} = \frac{E_{i,expected}}{P_{i,t}} \tag{18}$$
$$EARNINGS2PRICE_i = \frac{Y_{i,e} + Y_{i,c} + Y_{i,exp}}{3} \tag{19}$$

Where $E_{i,trailing}$ and $C_{i,trailing}$ are the one-year trailing per-share earnings and operating cash flow of stock $i$ at time $t$. $E_{i,expected}$ is the expected per-share earnings over the next year, and $P_{i,t}$ is the stock price.

#### Book-to-Price

Book-to-price is defined as the ratio of a stock's per-share book value of equity relative to its stock price. Book-to-price exposures are standardized locally.

$$BOOK2PRICE_i = \frac{B_{i,t}}{P_{i,t}} \tag{20}$$

Where $B_{i,t}$ and $P_{i,t}$ are the per-share book value and price of stock $i$ at time $t$.

#### Leverage

Leverage is defined as the average of a stock's debt-to-equity and debt-to-assets ratios. Leverage exposures are standardized locally.

$$D2E_i = \frac{D_{i,t}}{E_{i,t}} \tag{21}$$
$$D2A_i = \frac{D_{i,t}}{A_{i,t}} \tag{22}$$
$$LEVERAGE_i = \frac{D2E_i + D2A_i}{2} \tag{23}$$

Where $D_{i,t}$, $E_{i,t}$, and $A_{i,t}$ are the accounting values of debt, equity, and assets for stock $i$ at time $t$.

### Style Factor Post Processing and Scoring

While the previous section illustrates the style factor definitions, it is important to note that each factor is treated for outliers and scored before being used in the model. Style factors with multiple components have each individual component treated and scored before aggregation.

#### Post Processing

Obvious errors such as negative prices, market capitalizations, or trading volumes are dropped from the data set. Then, raw factor outliers are winsorized each day, with the daily outlier breakpoints determined by cross-sectional *median absolute deviation from the median* (MAD), which is a robust estimator of standard deviation [Further discussion of robust measures of scale can be found here: https://en.wikipedia.org/wiki/Robust_measures_of_scale].

$$MAD_{k,t} = 1.4826 \times median\left[ \left| X_{k,t} - median[X_{k,t}] \right| \right] \tag{24}$$

Where $X_{k,t}$ is a vector of raw exposures for factor $k$ at $t$. The constant 1.4826 ensures the consistency of this estimator, forcing MAD to converge to the standard deviation $\sigma$ in the case of a normal distribution. The upper and lower bounds for winsorization are determined as follows:

$$UPPER_{k,t} = median[X_{k,t}] + 3 \times MAD_{k,t} \tag{25}$$
$$LOWER_{k,t} = median[X_{k,t}] - 3 \times MAD_{k,t} \tag{26}$$

To maintain consistency in model application, winsorization breakpoints are determined exclusively within the estimation universe and then later applied to all securities in the coverage universe.

#### Scoring

Post-processed style exposures are standardized to have a capitalization-weighted mean of zero and unit variance. The market capitalization-weighted cross-sectional mean is subtracted from the values, and the results are divided by the equally weighted standard deviation. Like with post-processing, the means and standard deviations used are computed exclusively within the estimation universe and then later applied to the broader coverage universe for scoring.

$$X^{scored}_{k,t} = \frac{X^{treated}_{k,t} - WtdAvg[X^{treated}_{k,t}]}{StDev[X^{treated}_{k,t}]} \tag{27}$$

Where $X^{treated}_{k,t}$ is a vector of post-processed style exposures for factor $k$ at $t$.

### Style Exposure Correlations and Multicollinearity

Recall the earlier criterion that style exposures be reasonably uncorrelated over time. The villain in this case is a statistical property called *multicollinearity*. Multicollinearity can be assessed visually by inspecting the average pairwise correlations of scored factor exposures. Figure 4 illustrates pairwise style exposure correlations during the 2020–2021 period of increased market volatility and correlation. Upon visual inspection, these correlations appear acceptable, with higher correlations among more related factors (e.g., Beta and Volatility, Earnings-to-Price and Book-to-Price).

*Figure: Monthly style exposure cross-sectional correlations averaged over 2020 through 2021.*

A stronger requirement for a parsimonious model would be to minimize the multicollinearity among factor exposures. A frequently used measure of multicollinearity is the *Variance Inflation Factor* (VIF). For a given exposure $X_{k,t}$, it is calculated by finding the regression fit measure $R^2_k$ of a linear regression (without intercept) on the rest of the factor exposures and then computing the VIF value as follows:

$$VIF_k = \frac{1}{1 - R^2_k} \tag{28}$$

The historical series of VIFs for each of the style exposures is given in Figure 5. Values higher than 5 have been suggested to show high collinearity (Sheather). One can see that all the values stay below 4 and, for most exposures, are below 2. These results indicate that there is little multicollinearity in the underlying style exposures.

*Figure: Monthly cross-sectional VIFs for style exposures over time.*

### Industry and Region Factors

GICS industry groups are used to make the industry factors, while operating countries (as provided by DataStream) are used to make the region factors. The factor exposures are dummy variables, meaning that a company with an exposure to a given industry or region will have an exposure to those factors equal to one and an exposure to all other industries or regions equal to zero. See the approach proposed by Heston for more details.

To make industry factors backwards compatible over time, we reassign discontinued GICS categories based on where a majority of discontinued categorizations have been reassigned. In other words, we track the trajectory of GICS classifications over time and use that trajectory to map prior classifications to current classifications.

Regional factors may be grouped when individual countries are too thinly traded to create a robust factor portfolio. For example, Lithuania, Latvia, Romania, Serbia, Slovakia, and several other countries are grouped together to form the "Small Eastern European Markets" factor.

## FACTOR RETURNS

While previous sections outlined factor exposures, this section is concerned with the computation of factor returns (i.e., the return streams associated with each factor exposure). Factor returns are computed by performing cross-sectional regressions. The underlying multiple-regression model for the return on stock $i$ at time $t$ is the following:

$$r_{i,t} = f_{int} + \sum_{S \in styles} X^S_{i,t} f_S + \sum_{I \in industries} X^I_{i,t} f_I + \sum_{R \in regions} X^R_{i,t} f_R + \epsilon_{i,t} \tag{29}$$

Where $f_{int}$ and $\epsilon_{i,t}$ are intercept and error terms, respectively (more on the intercept later, as it has unique economic significance). The rest of the equation denotes the weighted sum of a stock's factor exposures and the returns of the corresponding factors.

### The Cross-Sectional Approach

An important problem is present in the approach described in equation (1)—namely, that we need a long time-series of data to accurately estimate regression coefficients (e.g., estimating $\beta$ from market returns in the CAPM). In a time-series approach, we implicitly assume that regression parameters remain constant over time, and that the parameters we estimate over our sample are a good indication of what those parameters should look like in the future.

We can solve this problem with a few changes to our regression model. First, let's assume that an asset's scored factor exposures can serve as proxies for regression coefficients (slopes). For example, assume we think that the return on a long-short portfolio that is long cheap stocks and short expensive stocks is a good factor that captures common variation in stock returns. In this case, we assume that our scored earnings yield calculation, as described in the previous sections, is a good proxy for the regression coefficient on this portfolio. We then run our regression in the *cross section* rather than in the *time series*. Specifically, we gather realized returns for all $N$ stocks for a *single day* into an $N \times 1$ vector $r_t$. We also gather all the factor exposures (e.g., the scored earnings yield and others that we might include) that we believe can serve as good proxies for regression coefficients in the $N \times K$ matrix $B_t$, where $K$ is the number of factor exposures we've chosen. For example, the first column could be an earnings yield score, the second could be a momentum score, and so forth.

We then do a statistical procedure that at first might seem a little strange. We run a regression *across stocks*, where returns are the dependent variables, and the *factor exposures (scores)* serve as the explanatory variables, as follows:

$$r_t = B_t f_t + \epsilon_t \tag{30}$$

Where $f_t$ are the factor returns on day $t$ that we are estimating based on the factor exposures provided in $B_t$, and $\epsilon_t$ is a vector of residuals (or idiosyncratic returns).

### Interpreting Factor Returns

But if $B_t$ is the matrix of factor exposures, what does $f_t$, the vector of factor return parameters we are estimating, represent? It turns out that there is an insightful economic interpretation if the matrix of factor exposures has been scored according to the methodology outlined in equation (27). When this transformation is applied, $f_t$ represents a vector of factor portfolio returns where each factor portfolio is long positive and short negative values of the corresponding exposure used to estimate it.

### Constrained Weighted Least-Squares and Dummy Variables

Recall that stock exposures to industry and region factors are dummy variables (either a one or zero) rather than the style exposure scores described in the previous section. These binary indicators introduce another problem into our regression model—namely that these industry and region exposures violate two key assumptions for ordinary least squares (OLS) regression. First, there is perfect collinearity among the dummy variables (i.e., when one industry exposure is set to one, all others are set to zero). Second, the residual returns are heteroskedastic.

When using dummy variables in a regression with an intercept, the common solution is to omit one of the dummy variable categories to avoid the so-called "dummy variable trap" of perfect collinearity, which makes the usual OLS estimate unidentified. However, this also drops one of our industry and region factor columns, which compromises our economic analysis of portfolio risk and return. Another solution, which allows us to interpret industry and region exposures as portfolio weights, is to perform a constrained regression where we enforce the constraint that the market-cap weighted industry and region factor returns must sum to zero.

A set of $j$ linear equality constraints on the vector $f_t$ can be written as follows:

$$C f_t = d \tag{31}$$

Where $C$ is a $j \times k$ matrix with linearly independent rows, and $d$ is a vector of $j$ elements whose values determine the equality constraint. For our purposes, all elements of $d$ are set equal to zero. Regarding our industry constraints, our $C$ matrix takes the following block form.

$$C = [S \quad I \quad R] \tag{32}$$

Where the individual concatenated blocks have two independent constraints: $S$ is a block of zeros over the styles and intercept columns, $I$ has capitalization weights $M$ in its first row over the industry columns and zeros in its second, and $R$ has zeros in its first row over the region columns and capitalization weights $M$ in its second.

Where $M$ is the capitalization weight of each industry or region within the estimation universe where the cross-sectional regression takes place.

We can also improve the efficiency of our regression estimates by correcting for heteroskedasticity and assuming that the variance of the firm-specific returns is inversely proportional to the square root of total market capitalization, a commonly used assumption in risk modeling. Weighted least squares requires that we weight the observations by the inverse of the residual variance matrix. To accomplish this, we weight our observed stock-level data with weights based on the square root of market cap. This manifests as a diagonal weighting matrix $W$ where the diagonal elements correspond to the following equation.

$$\frac{\sqrt{mcap_n}}{\sum_{j=1}^{N} \sqrt{mcap_j}} \tag{33}$$

This means that smaller firms, which tend to have higher variance, are weighted less than larger firms with lower variance. Our goal is to minimize the sum of the squared errors, which gives us the Lagrangian

$$L = (r_t - B_t f_t)^{\top} W (r_t - B_t f_t) + 2\lambda^{\top}(C f_t - d)$$
$$= r_t^{\top} W r_t - 2 r_t^{\top} W B_t f_t + f_t^{\top} B_t^{\top} W B_t f_t + 2\lambda^{\top} C f_t - 2\lambda^{\top} d$$

Taking the partial derivative of the Lagrangian with respect to $f_t$ and setting it equal to zero, we have:

$$\frac{\partial L}{\partial f_t} = -2 B_t^{\top} W r_t + 2 B_t^{\top} W B_t f_t + 2 C^{\top} \lambda = 0$$

And after additional rearranging we have:

$$B_t^{\top} W B_t f_t + C^{\top} \lambda = B_t^{\top} W r_t$$

Now we take the partial derivative of the Lagrangian with respect to $\lambda$ and set it equal to zero.

$$\frac{\partial L}{\partial \lambda} = 2 C f_t - 2d = 0 \Longrightarrow C f_t = d$$

We can combine both results into the following system:

$$\begin{bmatrix} B_t^{\top} W B_t & C^{\top} \\ C & 0 \end{bmatrix} \begin{bmatrix} f_t \\ \lambda \end{bmatrix} = \begin{bmatrix} B_t^{\top} W r_t \\ d \end{bmatrix}$$

Thus our closed-form regression solution for $f_t$ is:

$$\begin{bmatrix} f_t \\ \lambda \end{bmatrix} = \begin{bmatrix} B_t^{\top} W B_t & C^{\top} \\ C & 0 \end{bmatrix}^{-1} \begin{bmatrix} B_t^{\top} W r_t \\ d \end{bmatrix} \tag{34}$$

Although a significant amount of mathematical maneuvering is required, equation (34) gives us an elegant solution for our factor returns that can be easily programmed.

### Regression Results and Validation

A factor model is intended to capture the systematic market movements in stock returns. Each cross-sectional regression fit is characterized by its $R^2$, which represents the proportion of the variance in the stock returns that is explained by the model. Since we use weighted regression, the $R^2$ is defined by the following formula.

$$R^2 = 1 - \frac{\epsilon^{\top} W \epsilon}{(r - \bar{r})^{\top} W (r - \bar{r})} \tag{35}$$

Where $W$ is the diagonal matrix of regression weights defined in equation (33), $\epsilon$ is a vector of regression residuals, and $r$ is a vector of stock returns. The rolling $R^2$ of the estimation universe is illustrated in Figure 6.

*Figure: Grandeur Peak Risk Model—Rolling 3-month cross-sectional R².*

We've previously mentioned that our regression methodology gives unique economic significance to the intercept of our regression. Under our model, the intercept of our regression should approximate the capitalization-weighted return of the estimation universe. Therefore, in a global equity context, this intercept is referred to as the *World Factor*. This approximation is illustrated in Figure 7.

*Figure: Cumulative returns of world factor and capitalization-weighted estimation universe (left) and scatter plot of underlying returns (right).*

Upon visual inspection of Figure 7, we can see that the cumulative return streams and underlying return relationship between the world factor and capitalization-weighted estimation universe are a strong match.

## FORECASTING RISK

Once we've obtained our daily factor returns from our series of cross-sectional regressions, we can use those factor returns to compute a *factor covariance matrix*. For our purposes, we compute an *exponentially weighted* factor covariance matrix, meaning the computation puts more weight on recent observations [See the following article on exponential smoothing: https://en.wikipedia.org/wiki/Exponential_smoothing]. Additionally, we break the factor covariance matrix, $F$, into separate volatility and correlation components, allowing us to control the underlying assumptions for each component.

$$F_t = S_t C_t S_t \tag{36}$$

Where $F$ is the factor covariance matrix, $S$ is a diagonal matrix of factor volatilities, and $C$ is a factor correlation matrix. We use the following assumptions for computing $S$ and $C$.

| Component | Half-life | Window | Newey-West Lags |
|---|---|---|---|
| Factor Correlation | 520 | 520 | 3 |
| Factor Volatility | 260 | 520 | 5 |

The *Newey-West* adjustment is discussed later in this section. Additionally, there is a shrinkage adjustment applied to the factor correlation matrix $C$, which is also discussed later.

We also gather the exponentially weighted variances of each stock's residual returns ($\epsilon$) into a diagonal matrix, $\Gamma$, using the following parameters.

| Component | Half-life | Window | Newey-West Lags |
|---|---|---|---|
| Specific Volatility | 260 | 520 | None |

We can then use this factor covariance matrix, combined with a matrix of factor exposures, and a diagonal matrix of idiosyncratic variances to estimate a full covariance matrix of stock returns.

$$V_t = B_t F_t B_t^{\top} + \Gamma_t \tag{37}$$

So what just happened? In non-linear-algebra terms, the model focused the underlying factor exposures of each stock (contained in $B$) through the factor covariance matrix $F$, and layered on a matrix of stock-specific risk ($\Gamma$) to forecast pairwise covariances for every stock.

### Daily Asynchronicities and Newey-West Adjustments

It is widely understood that the asynchronous collection of daily return data introduces effects that models need to consider. Prices are collected from exchanges at regular intervals when each stock exchange closes, but trading hours of exchanges differ. For example, when the New York Stock Exchange opens at 9:30 a.m., it could be mid-day at the London Stock Exchange and between trading hours in Tokyo. Because of these time differences, news that affects the markets during the afternoon in New York is going to impact prices of other exchanges on the next day, and not at the same time. This aspect of financial market structure introduces systematic downward biases in return covariances when daily returns are used.

We can use the conditional response stress test of major global equity indices to illustrate this fact. Assume some vector of returns $r$ with mean $\mu$ and covariance matrix $\Sigma$. If $r$ is split into components $r_1$ whose response we are interested in, and components $r_2$ that are shocked, then $\mu$ and $\Sigma$ can be partitioned as follows.

$$\mu = \begin{bmatrix} \mu_1 \\ \mu_2 \end{bmatrix} \tag{38}$$

$$\Sigma = \begin{bmatrix} \Sigma_{11} & \Sigma_{12} \\ \Sigma_{21} & \Sigma_{22} \end{bmatrix} \tag{39}$$

Therefore, the expectation of $r_1$, conditional on $r_2$, is equal to the following.

$$\bar{\mu}_1 = \mu_1 + \Sigma_{12} \Sigma_{22}^{-1} (r_2 - \mu_2) \tag{40}$$

Now consider the responses of the following indices, spanning most time zones:

- All World USD Index (AWWRLD$)
- Toronto Composite Index (TTOCOMP)
- United Kingdom FTSE 100 Index (FTSE100)
- French CAC 40 Index (FRCAC40)
- German DAX Index (DAXXINDX)
- Swiss Market Index (SMIEXPI)
- Tokyo Exchange Index (TOKYOSE)
- ASX Composite Index (ASX200I)

Conditioned on a 20% decrease of:

- The S&P 500 Index (S&PCOMP)

Calculations were performed as described above using daily and weekly data between October 2017 and October 2019 (dates insulated from any major market turbulence periods). Covariance matrix calculations are exponentially weighted, putting more weight on more recent observations. The results of the conditional response test are recorded in Figure 8.

*Figure: Conditional response of major stock market indices in response to a 20% decline in the S&P 500.*

Since a market can react to news arriving after its close only on the next day, it is reasonable to expect that serial covariances can be significant on the daily frequency. In this setting, biases introduced by asynchronous data collection can be corrected with a robust estimator proposed by Newey and West. For financial purposes, it can be written as:

$$\hat{\Sigma}_{NW} = \hat{\Sigma}_0 + \sum_{j=1}^{M} k_j (\hat{\Sigma}_j + \hat{\Sigma}_j^{T}) \tag{41}$$

Where $\hat{\Sigma}_j$ are serial covariance matrix estimators with lag $j$ and $k_j = 1 - j/(M+1)$ are the Bartlett kernel weights. Figure 8 illustrates that employing the Newey-West estimator with an increasing number of lags on daily data in the conditional response test gradually brings the predicted index responses closer to the ones obtained with weekly return frequency.

### PCA Shrinkage Adjustments

Ledoit and Wolf showed that blending the sample covariance matrix with a covariance matrix from a one-factor model produced optimized fully invested portfolios with lower out-of-sample volatility than either model individually. Menchero expands upon this method by blending the sample correlation matrix towards a PCA correlation matrix (with weight $w$) using $J$ principal components from $K$ factors.

$$C_b = (1 - w) C_0 + w C_P \tag{42}$$

Where $C_b$ is the blended correlation matrix, $C_0$ is the sample correlation matrix, and $C_P$ is the PCA correlation matrix. Let's discuss how to compute the PCA correlation matrix, which we use to augment our factor correlation matrix according to equation (42).

Let $U_0$ denote the $K \times K$ rotation matrix whose column vectors are given by the eigenvectors of the sample correlation matrix $C_0$, arranged in descending order. These eigenvectors, also known as *eigenfactors*, represent portfolios of local factors. The sample correlation matrix, expressed in the diagonal basis, is given by:

$$D_0 = U_0^{\top} C_0 U_0 \tag{43}$$

Where the diagonal elements (i.e., the eigenvalues) of $D_0$ represent the predicted variances of the eigenfactor portfolios. Assume that only $J$ principal components are required to effectively capture the cross-sectional variation of local factor returns, where $J < K$. Let $\tilde{D}_0$ denote the $J \times J$ diagonal block of $D_0$, which consists of the $J$ largest eigenvalues arranged in decreasing order. Similarly, let $\tilde{U}_0$ represent the $K \times J$ matrix obtained by keeping only the first $J$ columns of $U_0$. The portion of the sample correlation matrix explained by the $J$ principal components is given by:

$$\tilde{C}_0(J) = \tilde{U}_0 \tilde{D}_0 \tilde{U}_0^{\top} \tag{44}$$

Note that if $J = K$, $\tilde{C}_0(J)$ equals the sample correlation matrix. However, for $J < K$, the principal components do not fully explain the cross-sectional variation in the sample correlation matrix. In this case, the diagonal elements of $\tilde{C}_0(J)$ are less than one, which implies that $\tilde{C}_0(J)$ cannot justifiably be interpreted as a correlation matrix.

This means we must adjust $\tilde{C}_0(J)$ to account for the variation that remains unexplained by the selected principal components. We then compute a diagonal $K \times K$ adjustment matrix $\Delta$.

$$\Delta = I - diag[\tilde{C}_0(J)] \tag{45}$$

We recompute our PCA correlation matrix (where the diagonal elements equal one) as follows:

$$C_P(J) = \tilde{U}_0 \tilde{D}_0 \tilde{U}_0^{\top} + \Delta \tag{46}$$

This result can be used in our original equation (42). For the purposes of this risk model, we augment the factor correlation matrix $C$ using $J = 1$ principal component and a shrinkage weight $w = 0.3$.

### Volatility Regime Bias Adjustments

Because risk models utilize historical data to make predictions about the future, they have the potential to underestimate risk in periods of rising volatility and overestimate risk in periods of declining volatility. In an attempt to correct for this, our model employs a *volatility regime adjustment* (VRA).

The factor VRA begins with a vector of standardized factor returns, where each factor return is standardized by dividing it by its predicted factor volatility.

$$f_{std,t} = f_t / \sigma_{f,t-1} \tag{47}$$

In theory, if our volatility forecasts are perfect, $f_{std}$ should be a vector of ones at each time $t$. We can then convert this vector into a cross-sectional bias statistic.

$$b_t = average\left[(f_{std,t})^2\right]^{1/2} \tag{48}$$

We take an exponentially weighted moving average of the cross-sectional bias statistics over time and modify our factor covariance matrix as follows:

$$F_{adj,t} = F_t \times ewma\left[(b_t, b_{t-1}, \ldots, b_{t-n})^2\right] \tag{49}$$

Where $F_t$ is the unadjusted factor covariance matrix at time $t$. For the exponentially weighted function, we use a rolling window and half-life parameter of 520 and 174 business days, respectively.

For idiosyncratic (firm-specific) volatility adjustments, the procedure is the same, except the vector of cross-sectional factor returns $f_t$ is replaced with the vector of residual returns from the estimation universe $\epsilon_t$ and the diagonal matrix of idiosyncratic variances $\Gamma_t$ is being scaled instead of the factor covariance matrix $F_t$. Additionally, the rolling window and half-life parameter are changed to 260 and 174 business days, respectively. Figure 9 shows the specific risk adjustments for the model over time. Values above one indicate periods where the model believes it is underestimating specific risk (and scaling the forecast upward) and values below one indicate periods where the model believes it is overestimating specific risk (and scaling the forecast downward).

*Figure: Volatility regime adjustment for company-specific risk.*

## APPENDIX A: RISK ATTRIBUTION

A portfolio $P$ is described by an $N$-element vector $h_P$ that gives the portfolio's weights of $N$ risky assets. The matrix $B$ gives the $N \times K$ matrix of portfolio factor exposures. The factor exposures of portfolio $P$ are given by:

$$x_P = B^{\top} h_P$$

The variance of portfolio $P$ is given by:

$$\sigma^2_P = x_P^{\top} F x_P + h_P^{\top} \Gamma h_P = h_P^{\top} V h_P$$

A similar formula lets us calculate $\sigma_A$, the active risk or tracking error. If $h_B$ is the benchmark weight vector, then we can define:

$$h_A = h_P - h_B$$
$$x_A = B^{\top} h_A$$
$$\sigma^2_A = x_A^{\top} F x_A + h_A^{\top} \Gamma h_A = h_A^{\top} V h_A$$

Notice that we have separated both total and active risk into common-factor and specific components. This works because we assume that factor risks and specific risks are uncorrelated.

The $N$ vector of stock betas relative to the benchmark $h_B$ is defined by the equation.

$$\beta = \frac{V h_B}{\sigma^2_B} = \frac{B F x_B + \Gamma h_B}{\sigma^2_B}$$

So that each asset's beta contains a factor contribution and a specific contribution. The specific contribution is zero for any asset not in the benchmark.

### Marginal Contributions

We can compute *marginal contributions* for total risk and active risk. The $N$ vector of marginal contributions to total risk is:

$$MCTR = \frac{\partial \sigma_P}{\partial h_P^{\top}} = \frac{V h_P}{\sigma_P}$$

The $MCTR$ of asset $n$ is the partial derivative of $\sigma_P$ with respect to the portfolio's weight in asset $n$. We can think of it as the approximate change in portfolio risk given a one-percent change in the weight of asset $n$, financed by decreasing the cash account by one percent. Likewise, marginal contribution to active risk is given by:

$$MCAR = \frac{\partial \sigma_A}{\partial h_A^{\top}} = \frac{V h_A}{\sigma_A}$$

We can also compute factor and specific marginal contributions as:

$$FMCTR = \frac{F x_P}{\sigma_P}, \quad FMCAR = \frac{F x_A}{\sigma_A}, \quad SMCTR = \frac{\Gamma h_P}{\sigma_P}, \quad SMCAR = \frac{\Gamma h_A}{\sigma_A}$$

We can use the marginal contributions to define a *percentage contribution to risk*.

$$PCTR = (MCTR \odot h_P) / \sigma_P, \quad PCAR = (MCAR \odot h_A) / \sigma_A$$
$$FPCTR = (FMCTR \odot x_P) / \sigma_P, \quad FPCAR = (FMCAR \odot x_A) / \sigma_A$$
$$SPCTR = (SMCTR \odot h_P) / \sigma_P, \quad SPCAR = (SMCAR \odot h_A) / \sigma_A$$
