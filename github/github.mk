artifacts:
	$(MKDIR) $@

.github-init:
	bash -x github/artifact-init
	touch $@

artifacts/%: | artifacts .github-init
	bash -x github/dl-artifact $*

artifact-timestamp:
	touch $@

artifact-push:
	for dir in artifacts/*; do
	    if [ "$$dir" -nt artifact-timestamp ]; then
		name=$$(basename "$$dir")
		bash -x github/ul-artifact "$$name" "$$(find "$$name" -type f)"
	    fi
	done
