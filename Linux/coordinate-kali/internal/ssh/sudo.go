package ssh

import (
	"fmt"
	"strings"

	"github.com/melbahja/goph"
	
	. "github.com/LByrgeCP/coordinate-kali/internal/globals"
	"github.com/LByrgeCP/coordinate-kali/internal/logger"
)

func escalateSudo (i Instance, client *goph.Client) bool {
	logger.Info(fmt.Sprintf("%s: Attempting to escalate privileges with sudo.", i.IP))
	_, err := client.Run("echo \"" + i.Password + "\" | sudo -S -s")
	if err != nil {
		_, err = client.Run("echo \"" + i.Password + "\" | sudo -S su")
		if err != nil {
			logger.Err(i, err)
		}
	}

	output, err := client.Run("whoami")

	if strings.TrimSpace(string(output)) != "root" {
		_, err = client.Run("echo \"" + i.Password + "\" | sudo -S su")
		if err != nil {
			logger.Err(i, err)
		}
	} else {
		logger.Info(i, "Successfully escalated privileges with sudo.")
		return true
	}

	output, err = client.Run("whoami")
	if strings.TrimSpace(string(output)) != "root" {
		logger.Err(i, "Failed to escalate privileges with sudo.")
		return false
	}

	logger.Info(i, "Successfully escalated privileges with sudo.")
	return true
}