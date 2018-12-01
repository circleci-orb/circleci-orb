NAMESPACE = cci-orb
VERSION ?=
GIT_COMMIT := $(shell git rev-parse --short HEAD)

.PHONY: pack/%
pack/%:  ## packing % to src/%.yml.
	@${RM} src/$*.yml
	circleci config pack src/$*/ > src/$*.yml

.PHONY: validate/%
validate/%:  ## validate ./src/%.yml.
	circleci orb validate ./src/$*.yml

.PHONY: publish/dev/%
publish/dev/%: VERSION=$(shell cat ./src/$*/VERSION.txt)
publish/dev/%: pack/% validate/%  ## publish %.yml dev version orb.
	circleci orb create ${NAMESPACE}/$* || true
	circleci orb publish ./src/$*.yml ${NAMESPACE}/$*@dev:$(VERSION)-${GIT_COMMIT} --debug

.PHONY: help
help:  ## Show make target help.
	@perl -nle 'BEGIN {printf "Usage:\n  make \033[33m<target>\033[0m\n\nTargets:\n"} printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2 if /^([a-zA-Z\/_-].+)+:.*?\s+## (.*)/' ${MAKEFILE_LIST}
