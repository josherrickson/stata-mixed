dyndocs = 01-mixed-model-theory.qmd 02-fitting-mixed-models.qmd \
          03-random-slopes.qmd 04-generalized-linear-mixed-models.qmd


.PHONY:default
default: $(dyndocs)
	quarto render

.PHONY:stata
stata: $(dyndocs)
	@echo > /dev/null

$(dyndocs): %.qmd: %.dyndoc
	/Applications/Stata/StataSE.app/Contents/MacOS/stata-se -b 'dyntext "$<", saving("$@") replace nostop'

.PHONY:open
open:
	@open docs/index.html

.PHONY:preview
preview:
	quarto preview
