package server

import (
	"github.com/gorilla/mux"
)

func Router() *mux.Router {
	router := mux.NewRouter().StrictSlash(true)
	router.Methods("GET").Path("/ping").HandlerFunc(PingHandler)
	router.Methods("GET").Path("/hello").HandlerFunc(HelloHandler)
	router.Methods("GET").Path("/delay/{time_ms}").HandlerFunc(DelayHandler)
	return router
}
