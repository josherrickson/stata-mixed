^#^ Mixed Model Theory

When fitting a [regression model](https://errickson.net/stata-regression/index.html), the most important assumption the models make (whether it's
linear regression or generalized linear regression) is that of independence - each row of your data set is independent on all other rows.

Now in general, this is almost never entirely true. If this violation is mild, it can be ignored. For example, if you give an exam to a class full of
students, it's reasonable to assume some students study together and therefore their answers on some questions (right or wrong) will tend to be
similar.

Here we are more concerned with a structured violation of independence. The most straightforward situation in which this arises is repeated
measures. Say you're administering an experiment where you are testing stress to different stimuli and are measuring quantities like blood pressure or
heart rate. If I were to take the test multiple times, my measurements are correlated with each other - if I tend to have higher blood pressure, my
blood pressure will be higher in each round regardless of stimuli.

Another common repeated measures situation is follow-up over time. Say you track individuals who undergo some surgery, and follow-up with them every 2
months, asking them to take a survey on their quality of life. While there are many research questions which could be asked about such data, one might
be to examine the patient's quality of life depending on the various health markers they are experiencing. The surgery is targeting symptom A, is
improvement in symptom A associated with better QoL? Is it symptom B which was unaffected by the surgery that has the largest effect on QoL? Obviously
a given patient's QoL and health markers at one time-point are highly correlated with each other.

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

The tall form would have each row of data represent a person and a year. So you'd have a column for ID, a column for year, and then, continuing the
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

^#^^#^ Theory

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

Both error terms, ^$^\epsilon^$^ and ^$^\kappa^$^ are assumed to have a mean of 0.

The catch is that *we do not estimate ^$^\kappa^$^*. If we include a categorical variable for the grouping variable, we could estimate all those
intercepts, however, doing so would in most situations overfit the model (if each individual had two measurements, we'd be including ^$^n/2^$^
predictors in a model with ^$^n^$^ observations). Instead, we estimate only the variance of ^$^\kappa_j^$^ which allows us to determine whether the
intercepts differ between groups.

Let's use a concrete example to make this more precise. Let your data set consist of ^$^n^$^ students, labeled ^$^s = 1, 2, \cdots, n^$^, each belonging
to one of ^$^m^$^ classrooms, labeled ^$^c = 1, 2, \cdots, m^$^. For further simplicity, let's assume there is only a single fixed predictor ^$^X^$^.

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
