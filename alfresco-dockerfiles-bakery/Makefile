## This Makefile is a wrapper around the docker-bake command
## to provide support for login and push to a registry.

SHELL := /bin/bash
DOCKER_BAKE_ARGS := --progress=plain

.PHONY: help setenv auth all clean test

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  all                Build all images"
	@echo "  enterprise         Build enterprise images"
	@echo "  community          Build community images"
	@echo "  adf_apps           Build ADF Apps images"
	@echo "  ats                Build Transform Service images"
	@echo "  connectors         Build Connector images"
	@echo "  repo               Build Repository image"
	@echo "  search_enterprise  Build Search Enterprise images"
	@echo "  search_service     Build Search Service images"
	@echo "  share              Build Share images"
	@echo "  sync               Build Sync Service images"
	@echo "  tengines           Build Transform Engine images"
	@echo "  =================="
	@echo "  clean              Clean up Nexus artifacts"
	@echo "  clean_caches       Clean up Docker and artifact caches"
	@echo "  help               Display this help message"

ACS_VERSION ?= 23
TOMCAT_VERSIONS_FILE := tomcat/tomcat_versions.yaml

ifeq ($(ACS_VERSION), 23)
  TOMCAT_FIELD := "tomcat10"
else
  TOMCAT_FIELD := "tomcat9"
endif

export TOMCAT_MAJOR := $(shell yq e '.${TOMCAT_FIELD}.major' $(TOMCAT_VERSIONS_FILE))
export TOMCAT_VERSION := $(shell yq e '.${TOMCAT_FIELD}.version' $(TOMCAT_VERSIONS_FILE))
export TOMCAT_SHA512 := $(shell yq e '.${TOMCAT_FIELD}.sha512' $(TOMCAT_VERSIONS_FILE))

setenv: auth
ifdef BAKE_NO_CACHE
DOCKER_BAKE_ARGS += --no-cache
endif
ifdef BAKE_NO_PROVENANCE
DOCKER_BAKE_ARGS += --provenance=false
endif

auth:
ifeq ($(REGISTRY),localhost)
	@echo "REGISTRY environment variable is set to localhost. Images will be build & loaded locally"
else ifdef REGISTRY
	@echo "Checking for REGISTRY authentication"
	@if docker login ${REGISTRY}; then \
		echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'; \
		echo "Images will be pushed to ${REGISTRY}/$${REGISTRY_NAMESPACE:-alfresco}"; \
		echo "Do make sure this location is safe to push to!"; \
		echo "In particular, make sure you are not pushing to a public registry"; \
		echo "without paying attention to the security & legal implications."; \
		echo "If you are not sure, please stop the build and check"; \
		echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'; \
		read -p "Do you want to continue? [y/N] " -n 1 -r; \
		[[ $$REPLY =~ ^[Yy]$$ ]] && echo -e '\n' || (echo -e "\nStopping build"; exit 1); \
	else \
		echo "Failed to login to ${REGISTRY}. Stopping build."; \
		exit 1; \
	fi
DOCKER_BAKE_ARGS += --set *.output=type=registry,push=true
else
	@echo "REGISTRY environment variable is not set. Images will be build & loaded locally"
endif

clean:
	@echo "Cleaning up Artifacts"
	@./scripts/clean-artifacts.sh -f

clean_caches:
	@echo "Cleaning up Docker cache"
	docker builder prune -f
	@echo "Cleaning up Artifacts cache"
	find artifacts_cache/ ! -name .gitkeep -mindepth 1 -delete

## PREPARE TARGETS
## Keep targets in alphabetical order (following the folder structure)

prepare: scripts/fetch-artifacts.sh
	@echo "Fetching all artifacts"
	@./scripts/fetch-artifacts.sh
	@python ./scripts/fetch_artifacts.py

prepare_adf: scripts/fetch-artifacts.sh
	@echo "Fetching all artifacts for ADF targets"
	@./scripts/fetch-artifacts.sh adf-apps

prepare_ats: scripts/fetch-artifacts.sh
	@echo "Fetching all artifacts for ATS targets"
	@./scripts/fetch-artifacts.sh ats

prepare_connectors: scripts/fetch-artifacts.sh
	@echo "Fetching all artifacts for Connector targets"
	@./scripts/fetch-artifacts.sh connector

prepare_repo: scripts/fetch_artifacts.py
	@echo "Fetching all artifacts for Repository target"
	@python ./scripts/fetch_artifacts.py repository

prepare_search_enterprise: scripts/fetch-artifacts.sh
	@echo "Fetching all artifacts for Search Enterprise targets"
	@./scripts/fetch-artifacts.sh search/enterprise

prepare_search_service: scripts/fetch-artifacts.sh
	@echo "Fetching all artifacts for Search Service targets"
	@./scripts/fetch-artifacts.sh search/service

prepare_share: scripts/fetch-artifacts.sh
	@echo "Fetching all artifacts for Share targets"
	@./scripts/fetch-artifacts.sh share

prepare_sync: scripts/fetch-artifacts.sh
	@echo "Fetching all artifacts for ADF targets"
	@./scripts/fetch-artifacts.sh sync

prepare_tengines: scripts/fetch-artifacts.sh
	@echo "Fetching all artifacts for Transform Engine targets"
	@./scripts/fetch-artifacts.sh tengine

## BUILD TARGETS
## Keep targets in alphabetical order (following the folder structure)

all: docker-bake.hcl prepare setenv
	@echo "Building all images"
	docker buildx bake ${DOCKER_BAKE_ARGS}
	$(call grype_scan,$@)

enterprise: docker-bake.hcl prepare setenv
	@echo "Building all Enterprise images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

community: docker-bake.hcl prepare setenv
	@echo "Building all Community images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

adf_apps: docker-bake.hcl prepare_adf setenv
	@echo "Building ADF App images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

ats: docker-bake.hcl tengines prepare_ats prepare_tengines setenv
	@echo "Building Transform Service images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

connectors: docker-bake.hcl prepare_connectors setenv
	@echo "Building Connector images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

repo: docker-bake.hcl prepare_repo setenv
	@echo "Building Repository images"
	docker buildx bake ${DOCKER_BAKE_ARGS} repository
	$(call grype_scan,repository)

search_enterprise: docker-bake.hcl prepare_search_enterprise setenv
	@echo "Building Search Enterprise images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

search_service: docker-bake.hcl prepare_search_service setenv
	@echo "Building Search Service images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

share: docker-bake.hcl prepare_share setenv
	@echo "Building Share images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

sync: docker-bake.hcl prepare_sync setenv
	@echo "Building Sync Service images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

tengines: docker-bake.hcl prepare_tengines setenv
	@echo "Building Transform Egnine images"
	docker buildx bake ${DOCKER_BAKE_ARGS} $@
	$(call grype_scan,$@)

all_ci: adf_apps ats connectors repo search_enterprise search_service share sync tengines all prepare clean clean_caches
	@echo "Building all targets including cleanup for Continuous Integration"

GRYPE_OPTS := -f high --only-fixed --ignore-states wont-fix

grype:
	@command -v grype >/dev/null 2>&1 || { echo >&2 "grype is required but it's not installed. See https://github.com/anchore/grype/blob/main/README.md#installation. Aborting."; exit 1; }
	@echo "Running grype scan"
	@docker buildx bake $(GRYPE_TARGET) --print | jq '.target[] | select(.output == ["type=docker"]) | .tags[]' | xargs -I {} grype $(GRYPE_OPTS) {}

ifdef GRYPE_ONBUILD
define grype_scan
	@command -v grype >/dev/null 2>&1 || { echo >&2 "grype is required but it's not installed. See https://github.com/anchore/grype/blob/main/README.md#installation. Aborting."; exit 1; }
	@echo "Running grype scan for $(1)"
	@docker buildx bake $(1) --print | jq '.target[] | select(.output == ["type=docker"]) | .tags[]' | xargs -I {} grype $(GRYPE_OPTS) {}
endef
endif
