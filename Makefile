# --- AWS Configuration ---
REGION_ENV     := $(shell echo $$AWS_REGION)
REGION_CLI     := $(shell aws configure get region 2>/dev/null)
AWS_REGION     := $(if $(REGION_ENV),$(REGION_ENV),$(REGION_CLI))

AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --query Account --output text 2>/dev/null)

# --- Repository Configuration ---
REPO_NAME      := $(shell echo $$REPO_NAME)

# --- Strict Validation ---
ifeq ($(strip $(AWS_REGION)),)
$(error ERROR: AWS_REGION is not set. Export it with 'export AWS_REGION=your-region')
endif

ifeq ($(strip $(AWS_ACCOUNT_ID)),)
$(error ERROR: Could not retrieve AWS_ACCOUNT_ID. Check your session/token)
endif

ifeq ($(strip $(REPO_NAME)),)
$(error ERROR: REPO_NAME is not set. Export it with 'export REPO_NAME=ephemeral-keycload-db')
endif

# --- Image Metadata ---
IMAGE_NAME     := custom-keycloak-db
TAG            := latest
FULL_IMAGE_URI := $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(REPO_NAME):$(TAG)

# --- Test Credentials ---
DB_USER        := keycloak
DB_NAME        := keycloak
DB_PASS        := keycloak

.PHONY: build login push test clean info

info:
	@echo "Detected AWS Region:     $(AWS_REGION)"
	@echo "Detected AWS Account:    $(AWS_ACCOUNT_ID)"
	@echo "Detected Repo Name:      $(REPO_NAME)"
	@echo "Target ECR URI:          $(FULL_IMAGE_URI)"

build:
	docker build -t $(IMAGE_NAME) -f Dockerfile.pg .

login:
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

push: build login
	docker tag $(IMAGE_NAME) $(FULL_IMAGE_URI)
	docker push $(FULL_IMAGE_URI)

test: build
	@echo "Starting test container..."
	docker run -d --name db-test-run \
		-e POSTGRES_USER=$(DB_USER) \
		-e POSTGRES_PASSWORD=$(DB_PASS) \
		-e POSTGRES_DB=$(DB_NAME) \
		$(IMAGE_NAME)
	@echo "Waiting for Postgres engine to be ready..."
	@count=0; \
	until docker exec db-test-run pg_isready -U $(DB_USER) -d $(DB_NAME); do \
		if [ $$count -eq 15 ]; then echo "Timed out waiting for DB"; exit 1; fi; \
		echo "Waiting..."; \
		sleep 2; \
		count=$$((count + 1)); \
	done
	@echo "Postgres is UP. Displaying Tables (\dt):"
	docker exec db-test-run psql -U $(DB_USER) -d $(DB_NAME) -c "\dt"
	@$(MAKE) clean

clean:
	@docker rm -f db-test-run 2>/dev/null || true
