# Makefile for golang-dummy

# Go parameters
GOCMD = go
GOBUILD = $(GOCMD) build
GOTEST = $(GOCMD) test
GOCLEAN = $(GOCMD) clean
GOGET = $(GOCMD) get

# Application binary name
BINARY_NAME = golang-dummy

# Package information
PKG = github.com/sreeharikmarar/golang-dummy

# Docker parameters
DOCKER = docker
DOCKER_IMAGE_NAME = golang-dummy
DOCKER_IMAGE_TAG = latest
DOCKER_REPO = sreeharikmarar/golang-dummy

# Default target
all: build

# Build the application
build:
	$(GOBUILD) -o $(BINARY_NAME) $(PKG)

# Clean build artifacts
clean:
	$(GOCLEAN)
	rm -f $(BINARY_NAME)

# Run tests
test:
	$(GOTEST) -v ./...

# Install dependencies
get:
	$(GOGET)

# Build and package the application as a binary (you can customize the target platform with GOOS and GOARCH)
package:
	GOOS=linux GOARCH=amd64 $(GOBUILD) -o $(BINARY_NAME) $(PKG)

# Build a Docker image
docker-build:
	$(DOCKER) build -t $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) .

# Push Docker image to a registry
docker-push:
	$(DOCKER) tag $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) $(DOCKER_REPO):$(DOCKER_IMAGE_TAG)
	$(DOCKER) push $(DOCKER_REPO):$(DOCKER_IMAGE_TAG)

.PHONY: all build clean test get package docker-build docker-push
