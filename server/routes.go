package server

import "net/http"

func Router() *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /ping", pingHandler)
	mux.HandleFunc("GET /hello", helloHandler)
	mux.HandleFunc("GET /delay/{time_ms}", delayHandler)
	mux.HandleFunc("GET /health", healthHandler)
	mux.HandleFunc("GET /headers", headersHandler)
	mux.HandleFunc("GET /status/{code}", statusHandler)
	mux.HandleFunc("POST /echo", echoHandler)
	mux.HandleFunc("GET /env", envHandler)
	mux.HandleFunc("GET /info", infoHandler)
	return mux
}
