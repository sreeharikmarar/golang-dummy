FROM golang:1.25-alpine AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app main.go

FROM alpine:3.21
RUN addgroup -S appgroup && adduser -u 10001 -S appuser -G appgroup
COPY --from=builder /app /app
USER appuser
ENV PORT=8080
EXPOSE 8080
ENTRYPOINT ["/app"]
CMD ["start"]
