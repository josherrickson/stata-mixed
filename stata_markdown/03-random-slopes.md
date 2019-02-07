^#^ Random slopes

So far all we've talked about are random intercepts. This is by far the most common form of mixed effects regression models. Recall that we set up the
[theory](#mixed-model-theory.html#theory) by allowing each group to have its own intercept which we don't estimate. We can also allow each group to
have it's own slope which we don't estimate. Just as random intercepts are akin to including a fixed effect allowing each group to have it's own fixed
effect, random slopes are akin to interacting a variable with the grouping variable, allowing each group to have it's own relationship.

We would include a random slope in the model if, instead of the relationship between a predictor and the outcome when controlling for group
membership, we were interested in the average relationship between the predictor and the outcome across groups. For example, if we had our basic class
example,

```
mixed gpa familyincome || class:
```

In this model, the coefficient on `familyincome` would estimate the relationship between family income and GPA, removing any additional class-level
differences. (Class-level differences here might be that a class that randomly has lower average income has a better teacher.)

If we include a random slope, we add the variable after the `:` in the second equation.

```
mixed gpa familyincome || class: familyincome
```

Now the model would allow each classroom to have it's own relationship between family income and GPA (which, just like random intercepts, is not
actually estimated) and the coefficient on `familyincome` would represent the average of those relationships.

Do you need a random slope? It depends on your theory. If your grouping variable is a nuisance and you're simply controlling for it (as it is in most
cases), you probably don't need a random slope. If, on the other hand, you suspect there are substantial differences between groups and you're really
interested in the average of those differences, then you should.

For reference, I'd say conservatively 95% of the mixed models I fit are in situations where a random slope is not needed, and 75% of the time when
people ask me if they need a random slope, the answer is no. However, my general bias is towards simpler models.^[If you're curious, my rational is
I'd rather fit a simpler model that misses a nuanced complexity, then fit a more complicated model that has takes a substantial power hit and
potentially is drastically further from the "truth".]

^#^^#^ Fitting a random slope

Let's add a random slope for gender.
~~~~
<<dd_do: quietly>>
use ICPSR_37105/DS0001/37105-0001-Data
quietly do ICPSR_37105/DS0001/37105-0001-Supplemental_syntax
rename _all, lower
rename mhcasp19_total qol
generate agebelow52 = age == 51
replace agebelow52 = . if missing(age)
generate ageabove82 = age == 81
replace ageabove82 = . if missing(age)
rename w2socialclass socialclass
generate female = gd002 == 2
replace female = . if missing(gd002)
<</dd_do>>
~~~~

~~~~
<<dd_do>>
mixed qol age agebelow52 ageabove82 i.socialclass female || household: female
<</dd_do>>
~~~~

Most of the output seems very familiar. The only addition is the "var(female)" in the Random-effects Parameters table which, just like in random
intercepts, estimates the variance across all the random slopes. Here it is very non-zero, so improves model fit. However, none of the fixed effects
really change. The only difference is in the interpretation of the coefficient on female:

In the random intercepts model, the coefficient on female represented that females were on average that much higher than males, regardless of age, social
class, or inter-household variance.

In this model with the random slope as well, the coefficient on female represents the average across all households of the amount that females are above
males, regardless of age or social class.

^#^^#^ Do you need to include the fixed slope if you have the random slopes

Yes.

In almost every model.

This is very similar to excluding the intercept (^$^\beta_0^$^) in a model - this forces the slope to pass through (0,0). In some very rare situations
that might be appropriate, but extremely rarely.

Excluding the fixed slope when including random slopes forces the average of all random slopes to be 0. If the true random slope is far from zero,
this will have catastrophic effects, including reversing the signs on a good number of the random slopes.
