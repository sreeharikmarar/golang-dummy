package server

import (
	"github.com/gorilla/mux"
)

func Router() *mux.Router {
	router := mux.NewRouter().StrictSlash(true)
	router.Methods("GET").Path("/ping").HandlerFunc(pingHandler)
	router.Methods("GET").Path("/hello").HandlerFunc(helloHandler)
	router.Methods("GET").Path("/delay/{time_ms}").HandlerFunc(delayHandler)
	return router
}
