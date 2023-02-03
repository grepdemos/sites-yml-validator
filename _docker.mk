ifndef COMMON_MAKE_DOCKER_INCLUDED

# Docker common things
#
# INPUT VARIABLES
#   - None
#
# EXPORT VARIABLES
# 	- BUILD_NUM: The build number for this build. Will use pants default sandbox
# 	             if not on circleCI, if that isn't available will defauilt to 'dev'.
# 	             If it is in circle will use CIRCLE_BUILD_NUM otherwise.
#-------------------------------------------------------------------------------

export PATH := $(PATH):$(HOME)/google-cloud-sdk/bin

# By default `lint-hadolint` will fail if hadolint is not installed.
# Set this to `no` to disable this behavior and make `lint-hadolint` pass silently instead.
REQUIRE_DOCKER_LINT ?= yes
_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

include $(_DIR)/_base.mk

## Append tasks to the global tasks
lint:: lint-hadolint

# use pants if it exists outside of circle to get the default namespace and use it for the build
ifndef CIRCLECI
  BUILD_NUM := $(shell pants config get default-sandbox-name 2> /dev/null || echo dev)-$(COMMIT)
endif
BUILD_NUM ?= dev

# TODO: the docker login -e email flag logic can be removed when all projects stop using circleci 1.0 or
#       if circleci 1.0 build container upgrades its docker > 1.14
ifdef CIRCLE_BUILD_NUM
  BUILD_NUM := $(CIRCLE_BUILD_NUM)
  ifeq (email-required, $(shell docker login --help | grep -q Email && echo email-required))
    QUAY := docker login -p "$$QUAY_PASSWD" -u "$$QUAY_USER" -e "unused@unused" quay.io
  else
    QUAY := docker login -p "$$QUAY_PASSWD" -u "$$QUAY_USER" quay.io
  endif
endif

# If we have a circle branch, tag the image with it
ifdef CIRCLE_BRANCH
  BUILD_NUM := $(BUILD_NUM)-$(shell echo "${CIRCLE_BRANCH}" | tr -cd '[:alnum:]_-')
endif

DOCKER_TRY_PULL ?= false
# Should we rebuild the tag regardless of whether it exists locally or elsewhere?
DOCKER_FORCE_BUILD ?= true
# Should we include build arguments?
DOCKER_BUILD_ARGS ?= ""
# Should we bypass the default push step?
# Overriding this flag in your makefile is useful for custom push logic.
DOCKER_BYPASS_DEFAULT_PUSH ?= false

# use pants if it exists outside of circle to get the default namespace and use it for the build
ifndef CIRCLECI
  BUILD_NUM := $(shell pants config get default-sandbox-name 2> /dev/null || echo dev)-$(COMMIT)
endif
BUILD_NUM ?= dev

# TODO: the docker login -e email flag logic can be removed when all projects stop using circleci 1.0 or
#       if circleci 1.0 build container upgrades its docker > 1.14
ifdef CIRCLE_BUILD_NUM
  BUILD_NUM := $(CIRCLE_BUILD_NUM)
  ifeq (email-required, $(shell docker login --help | grep -q Email && echo email-required))
    QUAY := docker login -p "$$QUAY_PASSWD" -u "$$QUAY_USER" -e "unused@unused" quay.io
  else
    QUAY := docker login -p "$$QUAY_PASSWD" -u "$$QUAY_USER" quay.io
  endif
endif

# If we have a circle branch, tag the image with it
ifdef CIRCLE_BRANCH
  BUILD_NUM := $(BUILD_NUM)-$(shell echo "${CIRCLE_BRANCH}" | tr -cd '[:alnum:]_-')
endif

# if there is a docker file then set the docker variable so things can trigger off it
ifneq ("$(wildcard Dockerfile))","")
# file is there
  DOCKER:=true
endif

DOCKER_BUILD_CONTEXT ?= .

# stub build-linux std target
build-linux::

## Append tasks to the global tasks
lint:: lint-hadolint

DOCKERFILES := $(shell find . -name 'Dockerfile*' -not -path "./devops/make*")
lint-hadolint:: ## lint Dockerfiles
ifdef DOCKERFILES
  ifneq (, $(shell command -v hadolint;))
		$(call INFO, "running hadolint for $(DOCKERFILES)")
		hadolint $(DOCKERFILES)
  else
    ifeq (yes,${REQUIRE_DOCKER_LINT})
		$(error "In order to lint docker files, hadolint is required. Please install it and re-run lint.")
    endif
  endif
endif

.PHONY:: build-docker lint-hadolint

endif # ifndef COMMON_MAKE_DOCKER_INCLUDED
