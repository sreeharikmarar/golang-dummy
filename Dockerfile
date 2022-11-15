FROM golang:1.18-alpine 
WORKDIR /src
ENV GO111MODULE=on
# Use the official golang module proxy
ENV GOPROXY=http://proxy.golang.org
# COPY the go.mod and go.sum files to the workspace
COPY go.mod .
COPY go.sum .
# Get dependencies. Will be cached as long as go.mod and go.sum do not change
RUN go mod download
# COPY the source code as the last step
COPY . .
# Build the binaries
RUN CGO_ENABLED=0 go build -o /usr/local/golang-dummy main.go

ENV PORT=8080
# Start the main process.
CMD ["/usr/local/golang-dummy", "start"]