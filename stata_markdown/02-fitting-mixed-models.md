^#^ Fitting Linear Mixed Models

The data we'll be using The Irish Longitudinal Study on Ageing, specificically the 2012-2013 data. It is available via ICPSR,
https://www.icpsr.umich.edu/icpsrweb/ICPSR/studies/37105/datadocumentation (you may need to sign in to access the data). The data represents surveys
of the elderly (50+) in Ireland.

(The reason we're using such an esoteric data set is that a lot of good publically available longitudinal data comes in seperate files per wave. This
is very common, and if you need to use these, you'll want to get familiar with the `append` and `merge` commands. This data requires no merging and is
easier for demonstration purposes.)

Once you've downloaded and extracted the files, and set your proper working directory, you can load the data and run the provided cleaning script
which identifies missing values for Stata.

~~~~
<<dd_do>>
use ICPSR_37105/DS0001/37105-0001-Data
quietly do ICPSR_37105/DS0001/37105-0001-Supplemental_syntax
rename _all, lower
<</dd_do>>
~~~~

Each row of this data is from a single individual, but multiple individuals from the same household may be included. The primary variable of interest
we'll be focusing on is a Quality of Life scale, `mhcasp19_total`, which is a score build from several sub-surveys. Let's see if we can predict it
based upon age, social class, and gender. First let's explore each variable.

~~~~
<<dd_do>>
rename mhcasp19_total qol
histogram qol
<</dd_do>>
~~~~

<<dd_graph: replace>>

Looks fine.

~~~~
<<dd_do>>
histogram age
<</dd_do>>
~~~~

<<dd_graph: replace>>

There's actually a bit of censoring in the data, anyone below 52 or above 82. One way around this is to add dummy variables flagging those
individuals, so let's do that.

~~~~
<<dd_do>>
label list AGE
generate agebelow52 = age == 51
replace agebelow52 = . if missing(age)
generate ageabove82 = age == 81
replace ageabove82 = . if missing(age)
<</dd_do>>
~~~~

Next social class and gender:

~~~~
<<dd_do>>
rename w2socialclass socialclass
tab socialclass
tab gd002
generate female = gd002 == 2
replace female = . if missing(gd002)
<</dd_do>>
~~~~

Both look fine.

Finally, the `household` variable identifies individuals belonging to the same household.

~~~~
<<dd_do>>
display _N
quietly levelsof household
display r(r)
<</dd_do>>
~~~~

So we have <<dd_display: _N>> total individuals across <<dd_display: r(r)>> households.

^#^^#^ Fitting the model

First, let's fit a linear regression model ignoring the dependence within households.

~~~~
<<dd_do>>
regress qol age agebelow52 ageabove82 i.socialclass female
<</dd_do>>
~~~~

This model doens't do so hot, but it's sufficient for our purposes - the F-test rejects.

The interpretation of the age variables is that the coefficient on `age` represents the relationship between age and QoL which is for individuals
between ages 52 and 81. The two coefficients on `agebelow52` and `ageabove82` is allowing those individuals to have a unique intercept, which means
they don't affect the slope on age. If you really wanted to drill down into what this all means, you could do some fancy `margins` calls to predict
the average response using `at()` to force the two dummies to the appropriate levels (not run):

```
margins, at(age = 51 agebelow52 = 1 ageabove82 = 0) at(age = (52 81) agebelow52 = 0 ageabove82 = 0) at(age=81 agebelow52 = 0 ageabove82 = 1)
```

In this case, there doesn't seem to be much effect of age (though it is good we controlled for it!).

We see a marginal effect for female, and we see some differences amongst socialclasses. Let's explore them more with `margins`:

~~~~
<<dd_do>>
margins socialclass
margins socialclass, pwcompare(pv)
<</dd_do>>
~~~~

So Professional and Managerial are indistinguishable, and Semi-skilled and Unskilled are likewise indistinguishable.

To fit the mixed model, the command is `mixed`. Let's first fit it again ignoring the household random effects.

~~~~
<<dd_do>>
mixed qol age agebelow52 ageabove82 i.socialclass female
<</dd_do>>
~~~~

We get identical results. If you look at the [equations](#mixed-model-theory) again, when there are no random effects, the model simplifies to ordinal
least squares.

To add our random effect, we'll use the following generic notation:

```
mixed y <fixed effects> || <group variable>:
```

The `||` splits a formula into two sides, the left of it is the fixed effects, the right is the random effects. The `:` is for including [random
slopes]() FIX ME which we'll discuss below.

~~~~
<<dd_do>>
mixed qol age agebelow52 ageabove82 i.socialclass female || household:
<</dd_do>>
~~~~

Let's walk through the output. Note that what we are calling the random effects (e.g. individuals in a repeated measures situation, classrooms in a
students nested in classroom situation), Stata refers to as "groups" in much of the output.

- You probably noticed how slow it is - at the very top, you'll see that the solution is arrived at iteratively. Recall that any regression model
  aside from OLS requires an iterative solution.
- The log likelihood is how the iteration works; essentially the model "guesses" choices for the coefficients, and finds the set of coefficients that
  minimize the log likelihood. Of course, the "guess" is much smarter than random. The actual value of the log likelihood is meaningless.
- Since we are dealing with repeated measures of some sort, instead of a single sample size, we record the total number of obs, the number of groups
  (unique entries in the random effects) and min/mean/max of the groups. Just ensure there are no surprises in these numbers. In this model, the
  quality of life has a good chunk of missingness, so we're losing about 2000 individuals.
- The ^$^\chi^2^$^ test tests the hypothesis that all coefficients are simultaneously 0.
    - We gave a significant p-value, so we continue with the interpretation.
- The coefficients table is interpreted just as in linear regression, with the addendum that each coefficient is also controlling for the structure
  introduced by the random effects.
    - There is still nothing informative in age, however, compared to OLS, the two dummy variables have notably different coefficients.
    - We'll have to check whether there is any difference in our conclusion regarding social class.
    - The coefficient on gender is larger and much more significant.
- The second table ("Random-effects parameters") gives us information about the error structure. The "household:" section is examining whether there
  is variation across households above and beyond the differences in the controlled variables. Since the estimate of `var(_cons)` (the estimated
  variance of the constant per person - the individual level random effect) is non-zero (and not close to zero), that is evidence that the random
  effect is beneficial. If the estimate was 0 or close to 0, that would be evidence that the random effect is unnecessary and that any difference
  between individuals is already accounted for by the covariates.
- The estimated variance of the residuals is any additional variation between observations. This is akin to the residuals from linear regression.
- The ^$^\chi^2^$^ test at the bottom is a formal test of the inclusion of the random effects versus a [linear
  regression](regression.html#linear-regression) model without the random effects. We reject the null that the models are equivalent, so it is
  appropriate to include the random effects.

Let's quickly examine the social class categories. The calls to `margins` are identical, but they operate slightly differently with the random
effects. Recall that the `margins` command works by assuming every row data is a given social class, then uses the observed values of the other fixed
effets and the regression equation to predict the outcome, and averaging to obtain the marginal means. This is *not* the case with the random effects;
the random effects (^$^\kappa_j^$^) are assumed to be 0. So for any given household, the marginal mean could be higher or lower, but on aggregate
across all households, we are estimating the marginal means.

~~~~
<<dd_do>>
margins socialclass
margins socialclass, pwcompare(pv)
<</dd_do>>
~~~~

Here our conclusions don't change - Unskilled & Semi-skilled have the same marginal means, and Professional and Managerial have the same marginal
means, all other comparisons are significant.

^#^^#^ Assumptions

The [linear additivity](https://errickson.net/stata-regression/ordinary-least-squares.html#relationship-is-linear-and-additive) remains necessary - we
need to assume that the true relationship between the predictors and the outcome is linear (as opposed to something more complicated like exponential)
and additive (as opposed to multiplicative, unless we are including interactions). With `regress`, we could use the `rvf` post-estimation command to
generate a plot of residuals versus predicted values. The `rvfplot` command does not work after `mixed`, but we can generate it manually.

~~~~
<<dd_do>>
predict fitted, xb
predict residuals, res
twoway scatter residuals fitted
<</dd_do>>
~~~~

<<dd_graph: replace>>

The odd grouping pattern shown is due to the two categorical variables (gender and social class in the model). Each "blob" represents one
permutation. You can see this by overlaying many plots:

~~~~
<<dd_do>>
twoway (scatter residuals fitted if female == 1 & socialclass == 1) ///
       (scatter residuals fitted if female == 0 & socialclass == 1) ///
       (scatter residuals fitted if female == 1 & socialclass == 2) ///
       (scatter residuals fitted if female == 0 & socialclass == 2) ///
       (scatter residuals fitted if female == 1 & socialclass == 3) ///
       (scatter residuals fitted if female == 0 & socialclass == 3) ///
       (scatter residuals fitted if female == 1 & socialclass == 4) ///
       (scatter residuals fitted if female == 0 & socialclass == 4) ///
       (scatter residuals fitted if female == 1 & socialclass == 5) ///
       (scatter residuals fitted if female == 0 & socialclass == 5) ///
       (scatter residuals fitted if female == 1 & socialclass == 6) ///
       (scatter residuals fitted if female == 0 & socialclass == 6), ///
       legend(off)
<</dd_do>>
~~~~

<<dd_graph: replace>>

Overall though we see no pattern in the residuals.

The other two assumptions which are relevant in linear regression, [homogeneity of
residuals](https://errickson.net/stata-regression/ordinary-least-squares.html#errors-are-homogeneous) and
[independence](https://errickson.net/stata-regression/ordinary-least-squares.html#independence), are both violated by design in a mixed
model. However, you need to assume that no other violations occur - if there is additional variance heterogenity, such as that brought above by very
skewed response variables, you may need to make adjustments. Similarly, if there is some other form of dependence you are not yet modeling, you need
to adjust your model to account for it.

^#^^#^ Predicting the random effects

While keeping in mind that we do not *estimate* the random intercepts when fitting this model, we can *predict* them. What's the difference? It's
subtle, but basically we have far less confidence in predicted values than in estimated values. So any confidence intervals will be substantially
larger. We know from the model output above that there is variance among the household random intercepts but don't have a sense of the pattern - is
there a single household that's much different than all the rest? Are they all rather noisy? Or something in between. We can test this.

First, we'll predict the random intercepts and the standard error of those intercepts.

~~~~
<<dd_do>>
predict rintercept, reffects
predict rintse, reses
<</dd_do>>
~~~~

As noted above, the quality of life variable is missing for around 2000 individuals, so we'll remove them from the data for ease (calling `preserve`
first to recover the full data later).

~~~~
<<dd_do>>
preserve
drop if missing(qol)
<</dd_do>>
~~~~

Now within each household, the random intercepts and standard errors are identical, so we can collapse down to the household level.

~~~~
<<dd_do>>
collapse (first) rintercept rintse (count) age, by(household)
<</dd_do>>
~~~~

Now we will sort by those random intercepts to add order, generate a variable indicating row number for plotting on the x-axis, and compute upper and
lower bounds of confidence intervals. Finally we generate a dummy variable to identify which households have confidence intervals not crossing zero.

~~~~
<<dd_do>>
sort rintercept
gen n = _n
gen lb = rintercept - 1.96*rintse
gen ub = rintercept + 1.96*rintse
gen significant = (lb > 0 & ub > 0) | (lb < 0 & ub < 0)
<</dd_do>>
~~~~

Now we can plot.

~~~~
<<dd_do>>
twoway (rcap ub lb n if significant) (scatter rintercept n if significant), legend(off) yline(0)
<</dd_do>>
~~~~

<<dd_graph: replace>>

The range in the middle is all households which we predict to have intercepts not distinguishable from zero. We can see that most of the random
intercept's confidenced intervals cross with the exception of very few large values and a larger chunk of small values.

So households tended to have slightly higher random intercepts (even though most aren't distinguishable from 0), but there's a sizeable chunk whose
random intercept is quite low:

~~~~
<<dd_do>>
count if ub < 0 & lb < 0
<</dd_do>>
~~~~

^#^^#^ Nested and Crossed random effects

The model we've fit so far has a single random intercept, corresponding to household. However, we could have more than one.

^#^^#^^#^ Nested random effects

Nested random effects exist when we have a nested level structure. In this data, we actually have this as each household belongs to a single sampling
cluster, identified by the `cluster` variable.

We can re-fit the model including a random intercept for cluster, then within each cluster, a random intercept for household. We do so by adding another equation via `||`:

~~~~
<<dd_do>>
restore
mixed qol age agebelow52 ageabove82 i.socialclass female || cluster: || household:
<</dd_do>>
~~~~

Overall the output looks very similar to the model before, but now in the last table, the Random-effects Parameters, we have estimates of three
variances, with the addition of cluster random effects.

In this case, the estimated variance is almost 0 (so close to 0 that Stata refuses to even compute a confidence interval), so we do not need this
random effect - once we control for the fixed effects, there is no additional error common to each cluster. This shouldn't be too surprising, as the
clusters in this data are part of the survey design (which, again, we are ignoring) and somewhat meaningless.

If you compare the results of this model to the first model, you'll see that the results are basically identical - as we expect when adding a
predictor that does not improve model fit. It's up to you whether you want to remove it. On the one hand, you can now appropriately claim you're
controlling for cluster-effects, but on the other hand, an additional random intercept makes the model converge much more slowly.

^#^^#^^#^ Crossed random effects

In the above design, we had nesting - within each cluster there are households, within each household there are individuals. However, this need not
always be the case.

For example, imagine you lead a large research team where 100 research assistants are conducting repeated surveys of individuals. Here we have
repeated measures per person, but we also potentially have interviewer effects that we want to include as random intercepts. However, there is no
nesting structure here. Instead, we call this a crossed random effects structure.

Here's the rub though: There is no such thing as "nested random effects". Everything is crossed. So why do nested random effects exist? Consider the
following small data set.

| classroom | studentid |
|-----------|-----------|
| a         | 1         |
| a         | 2         |
| b         | 1         |
| b         | 2         |

Here the first row of data reprsents the first student in classroom a, and the third row represents the first student in classroom b - both students
are **not the same student**. If we attempted to tell Stata that these random effects are crossed, Stata will incorrectly think rows 1 and 3 are the
same student. By telling Stata that studentid is nested inside classroom, it knows that student 1 from classroom a is distinct from student 1 from
classroom b.

However, if we were more clever with our data, we might instead store our data as:

| classroom | studentid |
|-----------|-----------|
| a         | 1         |
| a         | 2         |
| b         | 3         |
| b         | 4         |

Now if I tell Stata these are crossed random effects, it won't get confused! So all nested random effects are are a way to make up for the fact that
you may have been foolish in identifying individuals earlier.

Unfortunately fitting crossed random effects in Stata is a bit unwieldy. Here's the model we've been working with with crossed random effects.

~~~~
<<dd_do>>
mixed qol age agebelow52 ageabove82 i.socialclass female || _all:R.household || _all:R.cluster
<</dd_do>>
~~~~

This exposes one difference we haven't addressed - just because functionally crossed and nested effects are the same, does not mean the algorithm
which the software uses functions the same. Stata simply fails more often with crossed random effects. On the other hand, the `lmer` command in R has an easier time of specifying crossed effects and can converge this model just fine.

^#^^#^ Choosing Random or Fixed effects

When these models were first being developed, the recommended guidelines were:

- Fixed effects are used when the categories in the data represent all possible categories. For example, the collection of all schools in a given state.
- Random effects are used when the categories in the data represent a sample of all possible categories. For example, a sample of students in a school.

There are plenty of grey-areas in between so this advice isn't always useful. Instead think of it from a practical point of view

1. Do you have a large enough sample size to include fixed effects (recall the rule of 10-20 observations per predictor. If each person in your data
   has no more than 2 observations, that's far too many fixed effects)?
2. Do you need to actually estimate the average response within each group? (We can always [predict random effects](#predicting_the_random_ effects)
   but that's not as powerful as estimating.)

If the answer to these are No, include as random effects.

^#^^#^ Miscellaneous

There are various concerns we had with non-mixed models; most still hold. See the previous set of notes (linked to each topic) for more details.

[Multicollinearity](https://errickson.net/stata-regression/ordinary-least-squares.html#multicollinearity), the issue that predictor variables can be
correlated amongst each other to provide false positive results, remains an issue in linear regression. The VIF cannot be estimated after a mixed
model.

[Overfitting](https://errickson.net/stata-regression/ordinary-least-squares.html#overfitting) is still possible. Sample size considerations are
tricky, but the general rule of 10-20 observations per predictor is a good starting point. There's the additional complexity of the group structure,
but generally there are no restrictions on it. However, in practice, in you have a large number of groups with only a single measurement, [convergence
issues](#convergence-issues) tend to arise.

[Model selection](https://errickson.net/stata-regression/ordinary-least-squares.html#model-selection-is-bad) is still a very bad idea to do.

[Robust standard errors](https://errickson.net/stata-regression/ordinary-least-squares.html#robust-standard-errors) are still obtainable using
`vce(robust)` option.

^#^^#^ Convergence issues

With mixed models, the solution is arrived at iteratively, which means it can fail to converge for a number of reasons. Generally, failure to converge
will be due to an issue with the data.

The first thing to try is scaling all your parameters:

```
egen scaled_var = std(var)
```

Dummy variables typically don't need to be scaled, but can be. If scaling all your variables allows convergence, try different combinations of scaled
and unscaled to figure out what variables are causing the problem. It's typically (but not always) the variables which have the largest scale to begin
with.

Another potential convergence issue is extremely high correlation between predictors (including dummy variables). You should have already addressed
this when considering multicollinearity,but if not, it can make convergence challenging.

If the iteration keeps running (as opposed to ending and complaining about lack of convergence), try passing the option `emiterate(#)` with a few
"large" ("large" is relative to sample size) numbers to tell the algorithm to stop after `#` iterations, regardless of convergence. (Recall that an
interative solution produces an answer at each iteration, it's just not a consistent answer until you reach convergence.) You're looking for two
things:

- First, if there are any estimated standard errors that are extremely close to zero or exploding towards infinity, that predictor may be causing the
  issue. Try removing it.
- Second, if you try a few different max iterations (say 50, 100 and 200), and the estimated coefficients and standard errors are relatively constant,
  you may be running into a case where the model is converging to just beyond the tolerance which Stata uses, but for all intents and purposes is
  converged. Set `emiterate(#)` to a high number and use that result.

You can try use the "reml" optimizer, by passing the `reml` option. This optimizer can be a bit easier to converge, though may be slower.

Finally, although it pains me to admit it, you should try running the model in different software such as R or SAS. Each software has slightly
different algorithms it uses, and there are situations where one software will converge and another won't
