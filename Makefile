# Makefile for Next.js App

# Include .env file if it exists and export variables
-include .env
export

# --- Configuration ---
# Variables are now read from .env file
# PROJECT_ID
# REGION (maps to LOCATION in .env)
# SERVICE_NAME

# Target platform for Docker image (ensure compatibility with Cloud Run)
TARGET_PLATFORM ?= linux/amd64

# Image name (can be kept as is or customized, defaults to SERVICE_NAME)
IMAGE_NAME ?= $(SERVICE_NAME)
# Full image path in GCR
IMAGE_TAG = gcr.io/$(PROJECT)/$(IMAGE_NAME)

# --- Initialization Check ---
.PHONY: init
init:
	@echo "Checking environment configuration..."
	@if [ ! -f .env ]; then \
		echo "Error: .env file not found."; \
		echo "Please copy .env.example to .env and fill in your environment variables."; \
		exit 1; \
	fi
	@if [ -z "$(GEMINI_API_KEY)" ]; then \
		echo "Error: GEMINI_API_KEY not set in .env file."; \
		echo "Please add GEMINI_API_KEY=YOUR_GEMINI_API_KEY to your .env file."; \
		exit 1; \
	fi
	@if [ -z "$(PROJECT)" ]; then \
		echo "Error: PROJECT not set in .env file."; \
		echo "Please add PROJECT=YOUR_PROJECT_ID to your .env file."; \
		exit 1; \
	fi
	@if [ -z "$(LOCATION)" ]; then \
		echo "Error: LOCATION not set in .env file."; \
		echo "Please add LOCATION=YOUR_REGION to your .env file."; \
		exit 1; \
	fi
	@if [ -z "$(SERVICE_NAME)" ]; then \
		echo "Error: SERVICE_NAME not set in .env file."; \
		echo "Please add SERVICE_NAME=gemini-image-editing-app to your .env file."; \
		exit 1; \
	fi
	@if [ "$(GEMINI_API_KEY)" = "YOUR_GEMINI_API_KEY" ]; then \
		echo "Error: Placeholder GEMINI_API_KEY found in .env file."; \
		echo "Please replace 'YOUR_GEMINI_API_KEY' with your actual Gemini API key."; \
		exit 1; \
	fi
	@if [ "$(PROJECT)" = "YOUR_PROJECT_ID" ]; then \
		echo "Error: Placeholder PROJECT found in .env file."; \
		echo "Please replace 'YOUR_PROJECT_ID' with your actual Project ID."; \
		exit 1; \
	fi
	@if [ "$(LOCATION)" = "YOUR_REGION" ]; then \
		echo "Error: Placeholder LOCATION found in .env file."; \
		echo "Please replace 'YOUR_REGION' with your actual Region."; \
		exit 1; \
	fi
	@if [ "$(SERVICE_NAME)" = "YOUR_SERVICE_NAME" ]; then \
		echo "Error: Placeholder SERVICE_NAME found in .env file."; \
		echo "Please replace 'YOUR_SERVICE_NAME' with your actual Service Name."; \
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
	@echo "Building Docker image: $(IMAGE_TAG) for platform $(TARGET_PLATFORM)..."
	docker build --platform=$(TARGET_PLATFORM) -t $(IMAGE_TAG) .

# Push the Docker image to Google Artifact Registry
# Ensure you have authenticated Docker with gcloud: gcloud auth configure-docker gcr.io
push-image: build-image
	@echo "Pushing Docker image: $(IMAGE_TAG)..."
	docker push $(IMAGE_TAG)

# Deploy the image to Google Cloud Run
deploy: push-image
	@echo "Deploying service $(SERVICE_NAME) to Cloud Run in region $(LOCATION)..."
	gcloud run deploy $(SERVICE_NAME) \
		--image=$(IMAGE_TAG) \
		--region=$(LOCATION) \
		--platform=managed \
		--allow-unauthenticated \
		--project=$(PROJECT) \
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
	@echo "Configuration Variables (read from .env):"
	@echo "  PROJECT       Google Cloud Project ID"
	@echo "  LOCATION      Google Cloud Region"
	@echo "  SERVICE_NAME  Cloud Run Service Name"
	@echo "  IMAGE_NAME    Docker Image Name (default: SERVICE_NAME)"
	@echo "  TARGET_PLATFORM Target platform for Docker build (default: $(TARGET_PLATFORM))"

.DEFAULT_GOAL := help
