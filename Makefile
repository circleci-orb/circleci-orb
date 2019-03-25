.DEFAULT_GOAL = help
NAMESPACE = cci-orb
VERSION ?= $(shell cat ./src/$*/VERSION.txt)

CIRCLECI_FLAGS ?= --skip-update-check
ifneq ($(V),)
	CIRCLECI_FLAGS+=--debug
endif

.PHONY: create/%
create/%:  ## creates orb registry to org namespace.
	@circleci orb create $(strip $(CIRCLECI_FLAGS)) --no-prompt ${NAMESPACE}/$* > /dev/null 2>&1 || true

.PHONY: pack/%
pack/%:  ## packing % to src/%.yml.
	@${RM} src/$*.yml
	@circleci config pack $(strip $(CIRCLECI_FLAGS)) src/$*/ > src/$*.yml

.PHONY: validate/%
validate/%: pack/%  ## validate ./src/%.yml.
	@circleci orb validate $(strip $(CIRCLECI_FLAGS)) ./src/$*.yml

.PHONY: process/%
process/%: validate/%
	@circleci orb process ./src/$*.yml | bat -l yaml -

.PHONY: check/%
check/%:  ## checks orb with pack and validation.
	@${MAKE} --silent validate/$* clean/$*

.PHONY: clean/%
clean/%:  ## clean packed orb yaml.
	@${RM} ./src/$*.yml

.PHONY: clean
clean: clean/golang

.PHONY: publish/dev/%
publish/dev/%: TAG=dev:$(shell cat ./src/$*/VERSION.txt)
publish/dev/%: validate/% create/%  ## publish %.yml to dev orb registry.
	circleci orb publish $(strip $(CIRCLECI_FLAGS)) ./src/$*.yml ${NAMESPACE}/$*@${TAG}

.PHONY: publish/%
publish/%: TAG=$(shell cat ./src/$*/VERSION.txt)
publish/%: validate/% create/%  ## publish %.yml to production orb registry.
	circleci orb publish $(strip $(CIRCLECI_FLAGS)) ./src/$*.yml ${NAMESPACE}/$*@${TAG}

.PHONY: help
help:  ## Show make target help.
	@perl -nle 'BEGIN {printf "Usage:\n  make \033[33m<target>\033[0m\n\nTargets:\n"} printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2 if /^([a-zA-Z\/_-].+)+:.*?\s+## (.*)/' ${MAKEFILE_LIST}
