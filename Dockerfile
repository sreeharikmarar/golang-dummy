FROM golang:1.25-alpine AS builder
RUN apk add --no-cache git
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN VERSION=$(git describe --tags --always 2>/dev/null || echo "dev") && \
    GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown") && \
    BUILD_TIME=$(date -u '+%Y-%m-%dT%H:%M:%SZ') && \
    CGO_ENABLED=0 GOOS=linux go build \
      -ldflags="-s -w -X main.version=${VERSION} -X main.gitCommit=${GIT_COMMIT} -X main.buildTime=${BUILD_TIME}" \
      -o /app main.go

FROM alpine:3.21
RUN addgroup -S appgroup && adduser -u 10001 -S appuser -G appgroup
COPY --from=builder /app /app
USER appuser
ENV PORT=8080
EXPOSE 8080
ENTRYPOINT ["/app"]
CMD ["start"]
