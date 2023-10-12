# Golang dummy

A Go project that serves as a dummy example.


## Build the Application

to build the application, run:

```sh
make build
```

### Clean Build Artifcats

To clean build artifacts, run:

```sh
make clean
```

### Run Tests

To run tests, use:

```sh
make test
```

### Install Dependencies

If you need to install project dependencies, use:

```sh
make get
```
### Build and Package as Binary

To build and package the application as a binary (Linux, AMD64 by default), run:

```sh
make package
```


## Docker Build

To build a Docker image from the project, use:

```sh
make docker-build
```

To tag the Docker image and push it to a Docker registry, you need to run:

```sh
make docker-push
```
Note: Before using the docker-push target, replace your-docker-repo with your actual Docker repository.

## Run the Application
### Start server

```
$: go install github.com/sreeharikmarar/golang-dummy@latest
$: PORT=8080 golang-dummy start
```

### Delay request

```
/ # curl -v localhost:8080/delay/3000

> GET /delay/3000 HTTP/1.1
> User-Agent: curl/7.35.0
> Host: localhost:8080
> Accept: */*
>
< HTTP/1.1 200 OK
< Date: Tue, 15 Nov 2022 11:33:52 GMT
< Content-Length: 0
<
```
