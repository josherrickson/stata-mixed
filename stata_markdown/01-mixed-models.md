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


^#^^#^ Linear Mixed Model

https://www.icpsr.umich.edu/icpsrweb/ICPSR/studies/37105/summary

~~~~
<<dd_do>>
use "/Users/josh/Downloads/ICPSR_37105/DS0001/37105-0001-Data.dta"
do 37105-0001-Supplemental_syntax
<</dd_do>>
~~~~

The most basic mixed model is the linear mixed model, which extends the [linear regression](#linear-regression) model. A model is called "mixed"
because it contains a mixture of *fixed effects* and *random effects*.

- Fixed effects: These are the predictors that are present in regular linear regression. We will obtain coefficients for these predictors and be able
  to test and interpret them. Technically, an OLS linear model is a mixed model with only fixed effects.^[Though why called it mixed at that point?]
- Random effects: These are the "grouping" variables, and must be categorical (Stata will force every variable used to produce random effects as if it
  were prefaced by `i.`). These are essentially just predictors as well, however, we do not obtain coefficients to test or interpret. We do get a
  measure of the variability across groups, and a test of whether the random effect is benefiting the model.

Let's fit a model using the `mixed` command. It works similar to `regress` with a slight tweak. We'll try and predict log of wages^[Typically, salary
information is very right-skewed, and a log transformation makes the data closer to normal.] using work experience, race and age. The variable
`idcode` identifies individuals.

~~~~
<<dd_do>>
mixed ln_w ttl_exp i.race age || idcode:
<</dd_do>>
~~~~

The fixed part of the equation, `ln_w ttl_exp i.race age` is the same as with linear regression, `ln_w` is the outcome and the rest are predictors,
with `race` being categorical. The new part is `|| idcode:`. The `||` separates the fixed on the left from the random effects on the right. `idcode`
identifies individuals. The `:` is to enable the more complicated feature of random slopes which we won't cover here; for our purposes the `:` is just
required.

Let's walk through the output. Note that what we are calling the random effects (e.g. individuals in a repeated measures situation, classrooms in a
students nested in classroom situation), Stata refers to as "groups" in much of the output.

- At the very top, you'll see that the solution is arrived at iteratively, similar to [logistic regression](#fitting-the-logistic-model) (you probably
  also noticed how slow it is)!
- The log likelihood is how the iteration works; essentially the model "guesses" choices for the coefficients, and finds the set of coefficients that
  minimize the log likelihood. Of course, the "guess" is much smarter than random. The actual value of the log likelihood is meaningless.
- Since we are dealing with repeated measures of some sort, instead of a single sample size, we record the total number of obs, the number of groups
  (unique entries in the random effects) and min/mean/max of the groups. As before, just ensure these numbers seem right.
- As with logistic regression, the ^$^\chi^2^$^ test tests the hypothesis that all coefficients are simultaneously 0.
    - We gave a significant p-value, so we continue with the interpretation.
- The coefficients table is interpreted just as in linear regression, with the addendum that each coefficient is also controlling for the structure
  introduced by the random effects.
    - Increased values of `ttl_exp` is associated with higher log incomes.
    - The `race` baseline is "white"; compared to white, blacks have lower average income and others have higher average income.
    - Higher age is associated with lower income.
- The second table ("Random-effects parameters") gives us information about the error structure. The "idcode:" section is examining whether there is
  variation across individuals above and beyond the differences in characteristics such as age and race. Since the estimate of `var(_cons)` (the
  estimated variance of the constant per person - the individual level random effect) is non-zero (and not close to zero), that is evidence that the
  random effect is beneficial. If the estimate was 0 or close to 0, that would be evidence that the random effect is unnecessary and that any
  difference between individuals is already accounted for by the covariates.
- The estimated variance of the residuals is any additional variation between observations. This is akin to the residuals from linear regression.
- The ^$^\chi^2^$^ test at the bottom is a formal test of the inclusion of the random effects versus a [linear
  regression](regression.html#linear-regression) model without the random effects. We reject the null that the models are equivalent, so it is
  appropriate to include the random effects.

^#^^#^ Assumptions

The [linear additivity](regression.html#relationship-is-linear-and-additive) remains necessary. `rvfplot` will not work following a `mixed` command,
but you can [generate the residuals vs fitted plot manually](regression.html#obtaining-predicted-values-and-residuals).

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
