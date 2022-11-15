# golang-dummy

## Start server

```
$: go install github.com/sreeharikmarar/golang-dummy@latest
$: PORT=8080 golang-dummy start
```

## Delay request

```
/ # curl -v localhost:8080/delay/3000

> GET /delay/3000 HTTP/1.1
> User-Agent: curl/7.35.0
> Host: golang-dummy:8080
> Accept: */*
>
< HTTP/1.1 200 OK
< Date: Tue, 15 Nov 2022 11:33:52 GMT
< Content-Length: 0
<
```
