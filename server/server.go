package server

import (
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"
)

func PingHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("pong"))
}

func HelloHandler(w http.ResponseWriter, r *http.Request) {
	log.Print("hello request received")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("Hello from golang-dummy"))
}

func DelayHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	log.Print("delay request received for ", vars["time_ms"], "ms")
	time_ms, _ := strconv.Atoi(vars["time_ms"])
	time.Sleep(time.Duration(time_ms) * time.Millisecond)
	w.WriteHeader(http.StatusOK)
}
