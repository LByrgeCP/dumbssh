package config

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/LByrgeCP/coordinate-kali/internal/logger"
)

type ConfigEntry struct {
	IP       string
	Username string
	Password string
}


var ConfigEntries = []ConfigEntry{}

func ReadConfig() error {
	ConfigFilePath := "config.json"
	logger.Debug("Attempting to read configuration file...")

	file, err := os.Open(ConfigFilePath)
	if err != nil {
		if os.IsNotExist(err) {
			logger.Warning(fmt.Sprintf("Configuration file '%s' not found. Proceeding with empty configuration.", ConfigFilePath))
			return nil
		}
		logger.Err(fmt.Sprintf("Error opening configuration file '%s': %v", ConfigFilePath, err))
		return err
	}
	defer file.Close()

	decoder := json.NewDecoder(file)
	err = decoder.Decode(&ConfigEntries)
	if err != nil {
		logger.Err(fmt.Sprintf("Error decoding configuration file '%s': %v", ConfigFilePath, err))
		return err
	}

	logger.Info(fmt.Sprintf("Successfully loaded configuration from '%s'. Entries: %d", ConfigFilePath, len(ConfigEntries)))
	return nil
}

func UpdateEntry(entry ConfigEntry) {
	for i, e := range ConfigEntries {
		if e.IP == entry.IP {
			ConfigEntries[i] = entry
			return
		}
	}
	ConfigEntries = append(ConfigEntries, entry)
}

func GetEntryByIP(ip string) ConfigEntry {
	for _, e := range ConfigEntries {
		if e.IP == ip {
			return e
		}
	}
	return ConfigEntry{}
}

func DeleteEntryByIP(ip string) {
	for i, e := range ConfigEntries {
		if e.IP == ip {
			ConfigEntries = append(ConfigEntries[:i], ConfigEntries[i+1:]...)
			return
		}
	}
}

func SaveConfig() error {
	ConfigFilePath := "config.json"
	
	logger.Debug("Attempting to save configuration file...")

	data, err := json.MarshalIndent(ConfigEntries, "", "  ")
	if err != nil {
		logger.Err(fmt.Sprintf("Error marshaling configuration to JSON: %v", err))
		return err
	}

	file, err := os.Create(ConfigFilePath)
	if err != nil {
		logger.Err(fmt.Sprintf("Error creating configuration file '%s': %v", ConfigFilePath, err))
		return err
	}
	defer file.Close()

	_, err = file.Write(data)
	if err != nil {
		logger.Err(fmt.Sprintf("Error writing to configuration file '%s': %v", ConfigFilePath, err))
		return err
	}

	logger.Info(fmt.Sprintf("Successfully saved configuration to '%s'.", ConfigFilePath))
	return nil
}