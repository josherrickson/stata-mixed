^#^ Generalized Linear Mixed Models

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
