package cmd

import (
	"github.com/sreeharikmarar/golang-dummy/server"

	"github.com/spf13/cobra"
)

// startCmd represents the start command
var startCmd = &cobra.Command{
	Use:   "start",
	Short: "Start the API server",
	Long:  `Start the golang-dummy HTTP API server`,
	Run: func(cmd *cobra.Command, args []string) {
		server.Start()
	},
}

func init() {
	rootCmd.AddCommand(startCmd)
}
