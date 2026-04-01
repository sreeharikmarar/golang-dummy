# Makefile for golang-dummy

GOCMD = go
GOBUILD = $(GOCMD) build
GOTEST = $(GOCMD) test
GOCLEAN = $(GOCMD) clean
BINARY_NAME = golang-dummy
VERSION ?= dev
GIT_COMMIT = $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME = $(shell date -u '+%Y-%m-%dT%H:%M:%SZ')
LDFLAGS = -ldflags="-s -w -X main.version=$(VERSION) -X main.gitCommit=$(GIT_COMMIT) -X main.buildTime=$(BUILD_TIME)"

DOCKER = docker
DOCKER_IMAGE_NAME = golang-dummy
DOCKER_IMAGE_TAG = latest
DOCKER_REPO = sreeharikmarar/golang-dummy

all: build

build:
	$(GOBUILD) $(LDFLAGS) -o $(BINARY_NAME) .

clean:
	$(GOCLEAN)
	rm -f $(BINARY_NAME)

test:
	$(GOTEST) -v ./...

run:
	PORT=8080 $(GOCMD) run main.go start

package:
	GOOS=linux GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BINARY_NAME) .

docker-build:
	$(DOCKER) build \
		--build-arg VERSION=$(VERSION) \
		--build-arg GIT_COMMIT=$(GIT_COMMIT) \
		--build-arg BUILD_TIME=$(BUILD_TIME) \
		-t $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) .

docker-push:
	$(DOCKER) tag $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) $(DOCKER_REPO):$(DOCKER_IMAGE_TAG)
	$(DOCKER) push $(DOCKER_REPO):$(DOCKER_IMAGE_TAG)

kind-setup:
	./setup.sh setup

kind-teardown:
	./setup.sh teardown

lint:
	@which golangci-lint > /dev/null 2>&1 || (echo "Install golangci-lint: https://golangci-lint.run/welcome/install/" && exit 1)
	golangci-lint run ./...

verify:
	./setup.sh verify 20

.PHONY: all build clean test run package docker-build docker-push kind-setup kind-teardown lint verify
