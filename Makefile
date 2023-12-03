# Description: Makefile for building and deploying Lambda functions
# Author: Anthony Potappel 2023 <mail@aprxi.com>
# License: MIT License
#
# DISCLAIMER:
#   Use this software at your own risk -- it is provided as-is without any warranty or 
#   guarantee of any kind. The author is not responsible for any damage or loss.
#
#	Double/ triple check the AWS credentials and region in your environment before using this.
#
# Usage:
# 	make <target> [<target> ...] <app>
#
# 	additional usage notes:
#   - it should not be needed to change any variables in this Makefile 
#   - build/run/deploy one single lambda function located in lambdas/ at a time
#   - use aws cli v2 -- v1 is not supported
#   - if AWS credentials are used in the lambda, these must be defined in the environment
#   - for the aws cli targets (deploy_lambda_with_role, delete_lambda_with_role, lambda_*),
#     default aws cli rules apply (e.g. either environment or sourced from ~/.aws/credentials).
#     if profile used, set either AWS_PROFILE in environment (this wont be passed to the lambda)
#
#
# Examples:

# choose DEBUG, INFO, WARNING, ERROR, CRITICAL or leave it undefined
LOGLEVEL := DEBUG
NAME_SUFFIX := py-lambda

# if AWS_REGION is not set in environment, default to us-east-1
AWS_DEFAULT_REGION := us-east-1
AWS_REGION ?= $(AWS_DEFAULT_REGION)

# Get all command line targets
CMD_TARGETS := $(MAKECMDGOALS)

# Get valid DIR_TARGETS from CMD_TARGETS by matching against files in lambdas/
DIR_TARGETS := $(filter-out .,$(foreach target,$(CMD_TARGETS),$(if $(wildcard lambdas/$(target)/.),$(target))))

# Get APP_BASE_DIRECTORY from DIR_TARGETS
ifneq ($(DIR_TARGETS),)
APP_BASE_DIRECTORY := $(patsubst %/,%,$(firstword $(DIR_TARGETS)))
else
$(error No application target is given -- pick one from lambdas/)
endif

# Check if more than one directory is given
ifneq (,$(word 2,$(DIR_TARGETS)))
$(error Can only build 1 application at a time)
endif

# optional payload when invoking lambda
ifneq ($(payload),)
LAMBDA_PAYLOAD := $(payload)
else
LAMBDA_PAYLOAD := {}
endif

# APP_NAME is based on directory name of the app in lambdas/
# -- replace _ with - so it can be used safely
# note currently dont check for other non-compliant characters, we expect
# directory-names in lambdas/ to only contain [-a-z0-9_]
APP_NAME := $(subst _,-,$(APP_BASE_DIRECTORY))
FUNCTION_NAME := $(APP_NAME)-$(NAME_SUFFIX)
LAMBDA_ZIP = build/$(FUNCTION_NAME).zip

# validate non-phony target(s) 
# note this should be a 1 single app-target from lambdas/
%:
	@if ! [ -d "lambdas/$@" ]; then \
		echo "lambdas/$@ is not a valid directory"; \
		false; \
	fi

.PHONY: _docker_build
_docker_build:
	# add build args
	docker build \
		--build-arg APP_NAME=$(APP_BASE_DIRECTORY) \
		-t $(FUNCTION_NAME) .

.PHONY: _docker_remove
_docker_remove:
	docker rm -f $(FUNCTION_NAME) 2>/dev/null || exit 0

.PHONY: docker
docker: _docker_build _docker_remove
	docker run -d \
		--restart unless-stopped \
		--name $(FUNCTION_NAME) \
		-e AWS_DEFAULT_REGION=$(AWS_DEFAULT_REGION) \
		-e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
		-e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
		-e AWS_SESSION_TOKEN=$(AWS_SESSION_TOKEN) \
		-e LOGLEVEL=$(LOGLEVEL) \
		-p 9000:8080 \
		$(FUNCTION_NAME)

.PHONY: docker_clean
docker_clean: _docker_remove
	docker rmi $(FUNCTION_NAME) 2>/dev/null || exit 0

.PHONY: docker_logs
docker_logs:
	docker logs -f $(FUNCTION_NAME)

.PHONY: zip
zip:
	[ -d build ] || mkdir build
	[ -f $(LAMBDA_ZIP) ] && rm -f $(LAMBDA_ZIP) || true
	docker build \
		--target build-image \
		--build-arg APP_NAME=$(APP_BASE_DIRECTORY) \
		-t $(FUNCTION_NAME)-build .
	docker run \
		-v $(PWD)/build:/build \
		--entrypoint /bin/sh \
		--rm $(FUNCTION_NAME)-build -c 'zip -q -b /function -r /$(LAMBDA_ZIP) *'
	echo "Created $(LAMBDA_ZIP)"

.PHONY: lambda_deploy_with_role
lambda_deploy_with_role: zip
	@make -s -f aws/Makefile-lambda lambda_deploy_with_role \
		AWS_REGION=$(AWS_REGION) \
		FUNCTION_NAME=$(FUNCTION_NAME) \
		LOGLEVEL=$(LOGLEVEL) \
		APP_BASE_DIRECTORY=$(APP_BASE_DIRECTORY) 

.PHONY: lambda_delete_with_role
lambda_delete_with_role:
	@make -s -f aws/Makefile-lambda lambda_delete_with_role \
		AWS_REGION=$(AWS_REGION) \
		FUNCTION_NAME=$(FUNCTION_NAME) 

# while deploy also updates lambda,
# patching an existing lambda is much faster
.PHONY: lambda_patch
lambda_patch: zip
	@make -s -f aws/Makefile-lambda lambda_patch \
		AWS_REGION=$(AWS_REGION) \
		FUNCTION_NAME=$(FUNCTION_NAME) \
		LAMBDA_ZIP=$(LAMBDA_ZIP)

.PHONY: lambda_invoke
lambda_invoke:
	@make -s -f aws/Makefile-lambda lambda_invoke \
		AWS_REGION=$(AWS_REGION) \
		FUNCTION_NAME=$(FUNCTION_NAME) \
		LAMBDA_PAYLOAD='$(LAMBDA_PAYLOAD)'