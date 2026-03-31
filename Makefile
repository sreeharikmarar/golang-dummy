# Makefile for golang-dummy

GOCMD = go
GOBUILD = $(GOCMD) build
GOTEST = $(GOCMD) test
GOCLEAN = $(GOCMD) clean
BINARY_NAME = golang-dummy
LDFLAGS = -ldflags="-s -w"

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
	$(DOCKER) build -t $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) .

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

.PHONY: all build clean test run package docker-build docker-push kind-setup kind-teardown lint
