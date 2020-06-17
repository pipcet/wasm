artifacts: | .github-init
	$(MKDIR) $@

.github-init:
	bash -x github/artifact-init
	touch $@

artifacts/%: | artifacts
	bash -x github/dl-artifact $*
	mv $@.new $@
	ls -l $@

artifact-timestamp:
	touch $@

artifact-push:
	(cd artifacts; for dir in *; do if [ "$$dir" -nt ../artifact-timestamp ]; then name=$$(basename "$$dir"); (cd ..; bash -x github/ul-artifact "$$name" "$$name"); fi; done)
