include .env
export

# The target deployment for tf commands: setup / app / usecase / ...
TARGET ?= app
# The target deployment for docker commands (./docker folder): setup / app / usecase / ...
# The target environment (./environments folder): prod / dev / sandbox
ENV ?= sandbox


# Docker env vars
DOCKER_DIR ?= docker
VERSION ?= $(shell date +"%Y.%m.%d")
TAG ?= latest

# If working with dockers, this vars will be calculated lazily
AWS_ACCOUNT_ID=$(shell aws sts get-caller-identity --query "Account" --output text)
AWS_REGION=$(shell aws configure get region)

# Testing
EVENT_FILE ?= "test_event.json"
LAMBDA_ENV ?= "./lambda.env"

.PHONY :  aws/ docker/ tf/

# LOGIN
aws/login :
	@aws sso login

aws/ecr/login :
	@aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

# TARGET=docker-package
aws/ecr/create :
	@aws ecr create-repository --repository-name $(TARGET)

## DOCKER - TARGET=docker-package
docker/build :
	@docker build -t ${TARGET}:latest -t ${TARGET}:${VERSION} ./$(DOCKER_DIR)/$(TARGET)

docker/build/nocache :
	@docker build -t ${TARGET}:latest -t ${TARGET}:${VERSION} --no-cache ./$(DOCKER_DIR)/$(TARGET)

docker/clean :
	@dangling_images=$$(docker images -f "dangling=true" -q); \
	if [ -n "$$dangling_images" ]; then \
		docker rmi $$dangling_images; \
	fi

docker/push :
	@docker tag $(TARGET):$(VERSION) $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(TARGET):$(VERSION)
	@docker tag $(TARGET):$(VERSION) $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(TARGET):latest
	@docker push $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(TARGET):$(VERSION)
	@docker push $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(TARGET):latest

docker/push/rebuild : docker/build docker/push

##

lambda/test/run/local:
	docker run -p 9000:8080 --rm -v $(HOME)/.aws/:/root/.aws/ --env-file $(LAMBDA_ENV)  $(TARGET):$(TAG)

lambda/test/run/ecr:
	docker run -p 9000:8080 --rm -v $(HOME)/.aws/:/root/.aws/ --env-file $(LAMBDA_ENV)  $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(TARGET):$(TAG)

lambda/test/event:
	@ls $(DOCKER_DIR)/$(TARGET)/test_events/$(EVENT_FILE) || { echo "File not found"; exit 1; }
	curl -XPOST 'http://localhost:9000/2015-03-31/functions/function/invocations' -s -d @$(DOCKER_DIR)/$(TARGET)/test_events/$(EVENT_FILE) | jq .

## TERRAFORM COMMANDS: TARGET / INIT
# TARGET=deployment app
tf/init:
	terraform -chdir=./deployments/$(TARGET) init -backend-config=../../environments/$(ENV)/$(TARGET)/backend.conf

tf/apply:
	terraform -chdir=./deployments/$(TARGET) apply -var-file=../../environments/$(ENV)/$(TARGET)/terraform.tfvars

tf/apply/module:
	terraform -chdir=./deployments/$(TARGET) apply -var-file=../../environments/$(ENV)/$(TARGET)/terraform.tfvars -target=module.$(MODULE)

tf/apply/y:
	terraform -chdir=./deployments/$(TARGET) apply -auto-approve -var-file=../../environments/$(ENV)/$(TARGET)/terraform.tfvars

tf/destroy:
	terraform -chdir=./deployments/$(TARGET) destroy -var-file=../../environments/$(ENV)/$(TARGET)/terraform.tfvars

tf/destroy/module:
	terraform -chdir=./deployments/$(TARGET) destroy -var-file=../../environments/$(ENV)/$(TARGET)/terraform.tfvars -target=module.$(MODULE)

tf/destroy/y:
	terraform -chdir=./deployments/$(TARGET) destroy -auto-approve -var-file=../../environments/$(ENV)/$(TARGET)/terraform.tfvars

tf/plan:
	terraform -chdir=./deployments/$(TARGET) plan -var-file=../../environments/$(ENV)/$(TARGET)/terraform.tfvars
