^#^ Mixed models

When fitting a [regression model](https://errickson.net/stata-regression/index.html), the most important assumption the models make (whether it's
linear regression or generalized linear regression) is that of independence - each row of your data set is indepdendent on all other rows.

Now in general, this is almost never entirely true. If this violation is mild, it can be ignored. For example, if you give an exam to a class full of
students, it's reasonable to assume some students study together and therefore their answers on some questions (right or wrong) will tend to be
similar.

Here we are more concerned with a structured violation of independence. The most straightforward situation in which this arises is repeated
measures. Say you're administring an experiment where you are testing stress to different stimuli and are measuring quantities like blood pressure or
heart rate. If I were to take the test multiple times, my measurements are correlated with each other - if I tend to have higher blood pressure, my
blood pressure will be higher in each round regardless of stimuli.

Another common repeated measures situation is follow-up over time. Say you track individuals who undergo some surgery, and follow-up with them every 2
months, asking them to take a survey on their quality of life. While there are many research questions which could be asked about such data, one might
be to examine the patient's quality of life depending on the various health markers they are experiencing. The surgery is targetting symptom A, is
improvement in symptom A associated with better QoL? Is it sympton B which was unaffected by the surgery that has the largest effect on QoL? Obviously
a given patient's QoL and health markers at one timepoint are highly correlated with each other.

Another situation where this arises which isn't explicitly repeated measures is when your data is collected in some sort of clustered fashion. Note
that if your data is collected via a complex survey design, this is an entirely different beast that needs to be addressed appropriately (with the
`svyset` and `svy` set of commands). Instead I'm assuming a simpler set-up here. Say you are conducting a random door-to-door sampling of household
food habits, asking all available household members. It's very likely that two individuals in the same household will have similar food
habits. Therefore we gain less information by getting information on a new individual in an existing household, then adding a new individual from a
new household.

The canonical example of this is students in classrooms in schools in districts. All the situations above are 2-level (defined precisely [below]() FIX
ME), but here we have four levels. Again, adding a new student from an existing class/school/district will likely not add as much information as a new
student from a new class in a new school in a new district.

To address the lack of independence, we will move from normal regression (linear or otherwise) into a mixed models framework, which models for this
dependence structure. It does this (at the most basic level) by allowing each [individual from the intervention example, household from the
door-to-door example] to have its own intercept which we *do not estimate*.

^#^^#^ Terminology

There are several different names for mixed models which you might encounter, that all fit essentially the same model:

- Mixed model
- Mixed Effects regression/model
- Multilevel regression/model
- Hierarchical regression/model (specifically HLM, hierarchical linear model)

The hierarchical/multilevel variations require thinking about the levels of the data and involves "nesting", where one variable only occurs within
another, e.g. family members nested in a household. The most canonical example of this is students in classrooms, we could have

- Level 1: The lowest level, the students.
- Level 2: Classroom or teacher (this could also be two separate levels of classrooms inside teacher)
- Level 3: District
- Level 4: State
- Level 5: Country

This is taking it a bit far; it's rare to see more than 3 levels, but in theory, any number can exist.

For this workshop, we will only briefly discuss this from hierarchical point of view, preferring the mixed models view (with the reminder again that
they are the same!).

^#^^#^^#^ Econometric terminology

To make the terminology a bit more complicated, in econometrics, some of the terms we will use here are overloaded. When you are discussing mixed
models with someone with econometric or economics training, it's important to differentiate between the statistical terms of "fixed effects" and
"random effects" which are the two components of a mixed model that we [discuss below](#linear_mixed_model), and what econometricians called "fixed
effects regression" and "random effects regression".

Without going into the full details of the econometric world, what econometricians called "random effects regression" is essentially what
statisticians called "mixed models", what we're talking about here. The Stata command `xtreg` handles those econometric models.

^#^^#^ Wide vs Long data, Time-varying vs Time-invariant

Before you begin your analysis, you need to ensure that the data is in the proper format. The data can be either in wide-form or
long-form. Long-format is sometimes called tall-form.

If the data is longitudinal (follows the same person over time, collecting data at intervals), the wide form would entail each row representing a
single person, with the variables representing the questions at each wave. For example, if you were asking about income every 2 years, you'd have
variables `income14`, `income16`, `income18` representing the individuals income in 2014, 2016 and 2018.

The tall form would have each row of data represent a person and a year. So you'd have a column for ID, a column for year, and then, continuing th
example above, a single variable `income`.

If the data is clustered in some sense, e.g. students in classroom, the wide form would have each row be a single classroom, and have a separate set
of variables for the first student, second student, etc. In this format, unbalanced data (classrooms having different number of students) would result
in a lot of missing values.

The tall form would have a single row per student, and a variable representing their class.

In a lot of situations, it is easier to collect and manage data in wide form. However, to fit a mixed model, we need the data in long format. We can
use the `reshape` command to transform wide data to long. This is covered in my [Introduction to
Stata](https://errickson.net/stata1/data-manipulation.html#reshaping-files) set of notes.

Additionally, there is the concept of time-varying vs time-invariant variables. Time-varying variables are those which can be different for each entry
within the same individual. Examples include weight or salary. Time-invariant are those which are the same across all entries. An example would be
race. When data is long, time-invariant variables need to be constant per person. (When the repeated structure is not over time, this terminology can
be confusing, but the idea remains.)

^#^^#^ Mixed Model Theory

The equation for ordinal least squares (linear regression) is

^$$^
  Y = \beta_0 + \beta_1X_1 + \beta_2X_2 + \cdots + \beta_pX_p + \epsilon
^$$^

where ^$^Y^$^ represents the outcome, the various ^$^X_k^$^ represent the predictor variables, the ^$^beta^$^ are the coefficients to be estimated,
and ^$^\epsilon^$^ is the error.

As mentioned [above](#terminology), there are two ways to think about mixed models - as a mixed model, or as a hierarchical model. Let's talk about
the mixed model first.

When we fit a mixed model, instead of a single set of ^$^X^$^'s and ^$^\beta^$^'s on the right-hand side, there are now two sets, one corresponding to
the fixed effects and one corresponding to the random effects (a mixture of the two, hence the name). For example, the most basic form of a mixed
model, which has some number of fixed effects and a single random intercept, we have:

^$$^
  Y_{ij} = \beta_0 + \beta_1X_{1i} + \beta_2X_{2i} + \cdots + \beta_pX_{pi} + \kappa_j + \epsilon_{ij}
^$$^

The subscript notation helps us keep track of things. Here, I've set it up such that each observation ^$^i^$^ belongs to a group ^$^j^$^. The response
belonging to individual ^$^i^$^ in group ^$^j^$^ is predicted based upon some ^$^X^$^ variables, plus some additive effect which is unique to group
^$^j^$^, and additional error.

The catch is that *we do not estimate ^$^\kappa^$^*. If we include a categorical variable for the grouping variable, we could estimate all those
intercepts, however, doing so would in most situations overfit the model (if each individual had two measurements, we'd be including ^$^n/2^$^
predictors in a model with ^$^n^$^ observations). Instead, we estimate only the variance of ^$^\kappa_j^$^ which allows us to determine whether the
intercepts differ between groups.

Let's use a concrete example to make this more precise. Let your data set consist of ^$^n^$^ students, labelled ^$^s = 1, 2, \cdots, n^$^, each belonging
to one of ^$^m^$^ classrooms, labelled ^$^c = 1, 2, \cdots, m^$^. For further simplicity, let's assume there is only a single fixed predictor ^$^X^$^.

^$$^
  Y_{sc} = \beta_0 + \beta_1X_s + \kappa_c + \epsilon_{sc}
^$$^

It helps to think of ^$^\kappa^$^ as part of the error. You predict ^$^Y^$^ based upon the ^$^X^$^'s, then there is some common error amongst all
students in classroom ^$^c^$^ which captured by ^$^\kappa_c^$^, then there is individual error captured by ^$^\epsilon_{sc}^$^.

(You sometimes see the ^$^\kappa_j^$^ term written as ^$^\kappa Z^$^ where ^$^Z^$^ would be the variable indicating group membership. I find the above
notation clearer, though they are mathematically equivalent.)

In the above example, I've assumed that the sole ^$^X^$^ in the model is measured as the student level (hence ^$^X_s^$^). There is no need for that. I
could instead fit the above model with one variable measured per student (say GPA) and one variable measured per classroom (say average teacher
evaluation).

^$$^
  Y_{sc} = \beta_0 + \beta_1X_{1s} + \beta_2X_{2c} + \kappa_c + \epsilon_{sc}
^$$^

The nice part is that when fitting the model, this distinction doesn't matter! Both ^$^X_{1s}^$^ and ^$^X_{2c}^$^ are treated the same way.

The error terms can be expanded if desired. For students (^$^s^$^) nested inside classrooms (^$^c^$^) nested inside districts (^$^d^$^):

^$$^
  Y_{scd} = \beta_0 + \beta_1X_{1s} + \beta_2X_{2c} + \gamma_d + \kappa_{cd} + \epsilon_{scd}
^$$^

Here ^$^\gamma^$^ is the error common to all students in a given district, ^$^\kappa^$^ is the additional error common to all students in a given
classroom, and ^$^\epsilon^$^ is any left over student error.

^#^^#^^#^ The Hierarchical framework

The hierarchical way to write these models is, in my opinion, unnecessarily complicated and does not improve on the understanding. It is more
complicated for two reasons: 1) it is simply more complicated to write and understand, and 2) it requires conceptualizing the levels of the model more
than needed. For completeness, I will briefly re-write the school and classroom above. In mixed form, the model would be:

^$$^
  Y_{sc} = \beta_0 + \beta_1X_{1s} + \kappa_c + \epsilon_{sc}
^$$^

In the hierarchical form, the model is:

^$$^
  Y_{sc} = \beta_{s0} + \beta_1X_{1s} + \epsilon_{sc}
^$$^
^$$^
  \beta_{s0} = \gamma_{0} + \gamma_{1}Z_c + \sigma_c
^$$^

If you were to plug ^$^\beta_{s0}^$^ back into the first equation, you can see the equivalence of the two forms.


^#^^#^ Linear Mixed Model

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
  (unique entries in the random effects) and min/mean/max of the groups. Just ensure there are no surprises in these numbers.
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

The [linear additivity](regression.html#relationship-is-linear-and-additive) remains necessary - we need to assume that the true relationship between
the predictors and the outcome is linear (as opposed to something more complicated like exponential) and additive (as opposed to multiplicative,
unless we are including interactions). With `regress`, we could use the `rvf` post-estimation command to generate a plot of residuals versus predicted
values. The `rvfplot` command does not work after `mixed`, but we can generate it manually.

~~~~
<<dd_do>>
predict xb, xb
predict res, res
twoway scatter res xb
<</dd_do>>
~~~~

<<dd_graph: replace>>

The odd grouping pattern shown is due to the two categorical variables (gender and social class in the model). Each "blob" represents one
permutation. You can see this by overlaying many plots:

~~~~
<<dd_do>>
twoway (scatter res xb if female == 1 & socialclass == 1) ///
			 (scatter res xb if female == 0 & socialclass == 1) ///
			 (scatter res xb if female == 1 & socialclass == 2) ///
			 (scatter res xb if female == 0 & socialclass == 2) ///
			 (scatter res xb if female == 1 & socialclass == 3) ///
			 (scatter res xb if female == 0 & socialclass == 3) ///
			 (scatter res xb if female == 1 & socialclass == 4) ///
			 (scatter res xb if female == 0 & socialclass == 4) ///
			 (scatter res xb if female == 1 & socialclass == 5) ///
			 (scatter res xb if female == 0 & socialclass == 5) ///
			 (scatter res xb if female == 1 & socialclass == 6) ///
			 (scatter res xb if female == 0 & socialclass == 6), ///
			 legend(off)
<</dd_do>>
~~~~

<<dd_graph: replace>>

The [homogeneity of residuals](regression.html#errors-are-homogeneous) assumption is violated by design in a mixed model. However, some forms of
heterogeneity, such as increasing variance as fitted values increase, are not supported. Therefore we can still use the residuals vs fitted plot to
examine this.

Again, the [independence](regression.html#independence) assumption is violated by design, but observations between groups (e.g. between individuals)
should be independent.

^#^^#^ Miscellaneous

As we've discussed before, [collinearity](regression.html#multicollinearity), [overfitting](regression.html#overfitting), and [model
selection](regression.html#model-selection-is-bad) remain concerns.

Sample size considerations are tricky with mixed models. Typically these are done with simulations. At a rough pass, the rules of thumb from linear
regression remain; 10-20 observations per predictor. Adding a new person will improve the power more than adding another observation for an existing
group.

The `margins` and `predict` command work similarly to `regress`, however note that both (by default) *ignore the random effects*; that is, the results
the produce are averaged across all individuals.

As with [linear regression](regression.html#robust-standard-errors) and [logistic regression](regression#logit-miscellaneous), `mixed` supports
`vce(robust)` to enable robust standard errors.

^#^^#^ Convergence issues

As with [logistic regression](regression.html#separation), the solution is arrived at iteratively, which means it can fail to converge for a number of
reasons. Separation isn't an issue here (though it will be in [logistic mixed models](#convergence-issues)), but there can be other causes of a
failure to converge.

Generally, failure to converge will be due to an issue with the data. Things to look for include:

- Different scales of predictors. For example, salary (in dollars) and number of children. The scales are drastically different which can cause
  issues. Try re-scaling any variables on extreme scales (you can do this with `egen scaledvar = std(origvar)`). This will affect interpretation (the
  estimated coefficient will be the average predicted change with a one standard deviation increase in the predictor) but not the overall model fit.
- High correlation can cause this. Check correlations (`pwcorr` or `corr`) between your predictors (including any categorical variables) and if you
  find a highly correlated pair, try removing one.
- If the iteration keeps running (as opposed to ending and complaining about lack of convergence), try passing the option `emiterate(#)` with a few
  "large" ("large" is relative to sample size) numbers to tell the algorithm to stop after # iterations, regardless of convergence. You're looking for
  two things:
    - First, if there are any estimated standard errors that are extremely close to zero, that predictor may be causing the issue. Try removing it.
    - Second, if you try a few different max iterations (say 50, 100 and 200), and the estimated coefficients and standard errors are relatively
      constant, you could consider that model as "good enough". You wouldn't have much confidence in the point estimates of the coefficients, but you
      could at least gain insight into the direction and approximate magnitude of the effect.
- You can try use the "reml" optimizer, by passing the `reml` option. This optimizer can be a bit easier to converge.

^#^^#^ Logistic Mixed Model

https://data.wprdc.org/dataset/allegheny-county-crash-data

```
import delim https://data.wprdc.org/datastore/dump/bf8b3c7e-8d60-40df-9134-21606a451c1a
```

Similar to [logistic regression](regression.html#logistic-regression) being an extension to [linear regression](regression#linear-regression),
logistic mixed models are an extension to [linear mixed models](#linear-mixed-model) when the outcome variable is binary.

The command for logistic mixed models is `melogit`. The rest of the command works very similarly to `mixed`, and interpretation is the best of
logistic regression (for fixed effects) and linear mixed models (for random effects). Unfortunately, neither `lroc` nor `estat gof` is supported, so
goodness of fit must be measured solely on the ^$^\chi^2^$^ test and perhaps a manual model fit comparison.

By default the log-odds are reported, give the `or` option to report the odds ratios.

^#^^#^^#^ `meqrlogit`

There is a different solver that can be used based upon QR-decomposition. This is run with the command `meqrlogit`. It functions identically to
`melogit`. If `melogit` has convergence issues, try using `meqrlogit` instead.

^#^^#^ Exercise 6

Load up the "chicken" data set from Stata's website:

```
webuse chicken, clear
```

The data contains order information from a number of restaurants and records whether the order resulted in a complaint. We'd like to see what
attributes (if any) of the servers may increase the odds of a complaint. Since we have multiple orders per restaurant, it's reasonable to assume that
certain restaurants just recieve more complaints than others, regardless of the server, so we'll need to include random effects for those.

Fit a mixed effects logistic regression model predicting `complain`, based upon server characteristics (`grade`, `race`, `gender`, `tenure`, `age`,
`income`) and a few restaurant characteristics (`genderm` for gender of manager and `nworkers` for number of workers). Include a random effect for
`restaurant`.

1. Does the model fit better than chance?
2. Interpret the model. What predicts a higher odds of recieving a complaint?
3. Does it appear that adding the random effect was needed?
