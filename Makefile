# Makefile for Next.js App

# --- Configuration ---
# Replace with your Google Cloud Project ID
PROJECT_ID ?= your-gcp-project-id
# Replace with your desired Google Cloud region (e.g., us-central1)
REGION ?= your-gcp-region
# Replace with your Artifact Registry repository name
ARTIFACT_REPO ?= your-artifact-repo-name
# Replace with your desired Cloud Run service name
SERVICE_NAME ?= gemini-image-editing-app
# Image name (can be kept as is or customized)
IMAGE_NAME ?= $(SERVICE_NAME)
# Full image path in Artifact Registry
IMAGE_TAG = $(REGION)-docker.pkg.dev/$(PROJECT_ID)/$(ARTIFACT_REPO)/$(IMAGE_NAME):latest

# --- Initialization Check ---
.PHONY: init
init:
	@echo "Checking environment configuration..."
	@if [ ! -f .env ]; then \
		echo "Error: .env file not found."; \
		echo "Please copy .env.example to .env and fill in your API key."; \
		exit 1; \
	fi
	@if ! grep -q "^GEMINI_API_KEY=" .env; then \
		echo "Error: GEMINI_API_KEY not found in .env file."; \
		echo "Please add GEMINI_API_KEY=your_actual_key to your .env file."; \
		exit 1; \
	fi
	@if grep -q "^GEMINI_API_KEY=your_gemini_api_key" .env; then \
		echo "Error: Placeholder GEMINI_API_KEY found in .env file."; \
		echo "Please replace 'your_gemini_api_key' with your actual Gemini API key."; \
		exit 1; \
	fi
	@echo "Environment configuration check passed."

# --- Local Development ---
.PHONY: install build run-local

# Install dependencies
install:
	npm install

# Build the Next.js app for production
build: init install
	NEXT_TELEMETRY_DISABLED=1 npm run build

# Run the Next.js app in development mode
run-local: init install
	NEXT_TELEMETRY_DISABLED=1 npm run dev

# --- Cloud Run Deployment ---
.PHONY: build-image push-image deploy clean

# Build the Docker image
build-image:
	@echo "Building Docker image: $(IMAGE_TAG)..."
	docker build -t $(IMAGE_TAG) .

# Push the Docker image to Google Artifact Registry
# Ensure you have authenticated Docker with gcloud: gcloud auth configure-docker $(REGION)-docker.pkg.dev
push-image: build-image
	@echo "Pushing Docker image: $(IMAGE_TAG)..."
	docker push $(IMAGE_TAG)

# Deploy the image to Google Cloud Run
deploy: push-image
	@echo "Deploying service $(SERVICE_NAME) to Cloud Run in region $(REGION)..."
	gcloud run deploy $(SERVICE_NAME) \
		--image=$(IMAGE_TAG) \
		--region=$(REGION) \
		--platform=managed \
		--allow-unauthenticated \
		--project=$(PROJECT_ID) \
		--quiet

# Remove build artifacts and node_modules
clean:
	rm -rf .next node_modules

# --- Help ---
.PHONY: help

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Local Development Targets:"
	@echo "  install      Install project dependencies"
	@echo "  build        Build the Next.js app for production"
	@echo "  run-local    Run the Next.js app in development mode"
	@echo ""
	@echo "Cloud Run Deployment Targets:"
	@echo "  build-image  Build the Docker image"
	@echo "  push-image   Push the Docker image to Artifact Registry (requires build-image)"
	@echo "  deploy       Deploy the application to Google Cloud Run (requires push-image)"
	@echo ""
	@echo "Utility Targets:"
	@echo "  clean        Remove build artifacts and node_modules"
	@echo ""
	@echo "Configuration Variables (can be overridden):"
	@echo "  PROJECT_ID   Google Cloud Project ID (default: $(PROJECT_ID))"
	@echo "  REGION       Google Cloud Region (default: $(REGION))"
	@echo "  ARTIFACT_REPO Artifact Registry Repository Name (default: $(ARTIFACT_REPO))"
	@echo "  SERVICE_NAME Cloud Run Service Name (default: $(SERVICE_NAME))"
	@echo "  IMAGE_NAME   Docker Image Name (default: $(IMAGE_NAME))"

.DEFAULT_GOAL := help
