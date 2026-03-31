package server

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"runtime"
	"strconv"
	"strings"
	"time"
)

var startTime time.Time

func pingHandler(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("pong"))
}

func helloHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"hello": "world"}`))
}

func delayHandler(w http.ResponseWriter, r *http.Request) {
	ms, err := strconv.Atoi(r.PathValue("time_ms"))
	if err != nil || ms < 0 {
		http.Error(w, `{"error": "invalid time_ms"}`, http.StatusBadRequest)
		return
	}
	if ms > 30000 {
		ms = 30000
	}
	time.Sleep(time.Duration(ms) * time.Millisecond)
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintf(w, `{"delayed_ms": %d}`, ms)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"status":    "ok",
		"timestamp": time.Now().UTC().Format(time.RFC3339),
		"uptime":    time.Since(startTime).String(),
	})
}

func headersHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(r.Header)
}

func statusHandler(w http.ResponseWriter, r *http.Request) {
	code, err := strconv.Atoi(r.PathValue("code"))
	if err != nil || code < 100 || code > 599 {
		http.Error(w, `{"error": "invalid status code, must be 100-599"}`, http.StatusBadRequest)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	fmt.Fprintf(w, `{"status": %d, "description": %q}`, code, http.StatusText(code))
}

func echoHandler(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 1<<20))
	if err != nil {
		http.Error(w, `{"error": "body too large, max 1MB"}`, http.StatusRequestEntityTooLarge)
		return
	}
	if len(body) == 0 {
		http.Error(w, `{"error": "empty body"}`, http.StatusBadRequest)
		return
	}
	ct := r.Header.Get("Content-Type")
	if ct == "" {
		ct = "application/octet-stream"
	}
	w.Header().Set("Content-Type", ct)
	w.Write(body)
}

func envHandler(w http.ResponseWriter, r *http.Request) {
	allowed := []string{"HOSTNAME", "POD_NAME", "POD_NAMESPACE", "POD_IP", "NODE_NAME", "PORT"}
	result := make(map[string]string)
	for _, key := range allowed {
		if v, ok := os.LookupEnv(key); ok {
			result[key] = v
		}
	}
	for _, env := range os.Environ() {
		if strings.HasPrefix(env, "APP_") {
			parts := strings.SplitN(env, "=", 2)
			result[parts[0]] = parts[1]
		}
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(result)
}

func infoHandler(w http.ResponseWriter, r *http.Request) {
	hostname, _ := os.Hostname()
	var ips []string
	addrs, err := net.InterfaceAddrs()
	if err == nil {
		for _, addr := range addrs {
			if ipNet, ok := addr.(*net.IPNet); ok && !ipNet.IP.IsLoopback() {
				ips = append(ips, ipNet.IP.String())
			}
		}
	}
	if ips == nil {
		ips = []string{}
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"hostname":   hostname,
		"ips":        ips,
		"go_version": runtime.Version(),
		"os":         runtime.GOOS,
		"arch":       runtime.GOARCH,
		"num_cpus":   runtime.NumCPU(),
		"uptime":     time.Since(startTime).String(),
	})
	log.Printf("info request: hostname=%s", hostname)
}
