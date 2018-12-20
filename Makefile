NAMESPACE = cci-orb
VERSION ?= $(shell cat ./src/$*/VERSION.txt)
GIT_COMMIT := $(shell git rev-parse --short HEAD)

CIRCLECI_FLAGS ?= --skip-update-check

ifneq ($(V),)
	CIRCLECI_FLAGS+=--debug
endif

.PHONY: pack/%
pack/%:  ## packing % to src/%.yml.
	@${RM} src/$*.yml
	@circleci config pack $(strip $(CIRCLECI_FLAGS))  src/$*/ > src/$*.yml

.PHONY: validate/%
validate/%:  ## validate ./src/%.yml.
	@circleci orb validate $(strip $(CIRCLECI_FLAGS)) ./src/$*.yml

.PHONY: check/%
check/%: pack/% validate/%  ## checks orb with pack and validation.
	@${MAKE} --silent clean/$*

.PHONY: create/%
create/%:  ## creates orb registry to org namespace.
	@circleci orb create $(strip $(CIRCLECI_FLAGS)) ${NAMESPACE}/$* || true

.PHONY: clean/%
clean/%:  ## clean packed orb yaml.
	@${RM} ./src/$*.yml

.PHONY: publish/dev/%
publish/dev/%: TAG=dev:$(shell cat ./src/$*/VERSION.txt)-${GIT_COMMIT}
publish/dev/%: pack/% validate/% create/%  ## publish %.yml to dev orb registry.
	circleci orb publish $(strip $(CIRCLECI_FLAGS)) ./src/$*.yml ${NAMESPACE}/$*@${TAG}

.PHONY: publish/%
publish/%: TAG=$(shell cat ./src/$*/VERSION.txt)
publish/%: pack/% validate/% create/%  ## publish %.yml to production orb registry.
	circleci orb publish $(strip $(CIRCLECI_FLAGS)) ./src/$*.yml ${NAMESPACE}/$*@${TAG}

.PHONY: help
help:  ## Show make target help.
	@perl -nle 'BEGIN {printf "Usage:\n  make \033[33m<target>\033[0m\n\nTargets:\n"} printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2 if /^([a-zA-Z\/_-].+)+:.*?\s+## (.*)/' ${MAKEFILE_LIST}
