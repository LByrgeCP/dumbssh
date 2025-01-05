package config

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/LByrgeCP/coordinate-kali/internal/logger"
	. "github.com/LByrgeCP/coordinate-kali/internal/globals"
)

func ReadEnv() {
	EnvFilePath := "env.json"
	logger.Debug("Attempting to read environment file...")

	file, err := os.Open(EnvFilePath)
	if err != nil {
		if os.IsNotExist(err) {
			logger.Warning(fmt.Sprintf("Environment file '%s' not found.", EnvFilePath))
			return
		}
		logger.Err(fmt.Sprintf("Error opening environment file '%s': %v", EnvFilePath, err))
		return
	}
	defer file.Close()

	var env map[string]string
	err = json.NewDecoder(file).Decode(&env)
	if err != nil {
		logger.Err(fmt.Sprintf("Error decoding environment file '%s': %v", EnvFilePath, err))
		return
	}

	for key, value := range env {
		found := false
		for i, cmd := range EnvironCmds {
			if cmdKey := cmd[:len(key)]; cmdKey == key {
				EnvironCmds[i] = fmt.Sprintf("%s=%s", key, value)
				found = true
				break
			}
		}
		if !found {
			EnvironCmds = append(EnvironCmds, fmt.Sprintf("%s=%s", key, value))
		}
	}
	logger.Debug(fmt.Sprintf("Environment file '%s' read successfully.", EnvFilePath))
}