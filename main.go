package main

import (
	"github.com/sreeharikmarar/golang-dummy/cmd"
	"github.com/sreeharikmarar/golang-dummy/server"
)

var (
	version   = "dev"
	gitCommit = "unknown"
	buildTime = "unknown"
)

func main() {
	server.SetBuildInfo(version, gitCommit, buildTime)
	cmd.Execute()
}
