artifacts: | .github-init
	$(MKDIR) $@

.github-init:
	bash -x github/artifact-init
	touch $@

artifacts/%: | artifacts
	bash -x github/dl-artifact $*
	mv $@.new/$* $@
	rm -rf $@.new
	ls -l $@

artifact-timestamp:
	touch $@

artifact-push:
	(cd artifacts; for dir in *; do if [ "$$dir" -nt ../artifact-timestamp ]; then name=$$(basename "$$dir"); (cd ..; bash -x github/ul-artifact "$$name" "artifacts/$$name"); fi; done)
	echo "(Do not be confused by the size stated above; it's the compressed size)"
