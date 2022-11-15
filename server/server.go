package server

import (
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"
)

func PingHandler(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("pong"))
}

func HelloHandler(w http.ResponseWriter, r *http.Request) {
	log.Print("hello request received")
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Write([]byte(`{"hello": "world"}`))
}

func DelayHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	log.Print("delay request received for ", vars["time_ms"], "ms")
	time_ms, err := strconv.Atoi(vars["time_ms"])
	if err != nil {
		log.Print("invalid time")
		w.WriteHeader(http.StatusBadRequest)
		return
	}
	time.Sleep(time.Duration(time_ms) * time.Millisecond)
}
