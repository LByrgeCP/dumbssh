package main

import (
	"fmt"
	"os"
	"strings"
	"sync"
	"syscall"

	"golang.org/x/term"

	"github.com/LByrgeCP/coordinate-kali/internal/cli"
	"github.com/LByrgeCP/coordinate-kali/internal/config"
	. "github.com/LByrgeCP/coordinate-kali/internal/globals"
	"github.com/LByrgeCP/coordinate-kali/internal/logger"
	"github.com/LByrgeCP/coordinate-kali/internal/runner"
	"github.com/LByrgeCP/coordinate-kali/internal/utils"
)

func main() {
	logger.Debug("Starting the application...")

	cli.Init()
	logger.Debug("CLI initialization completed.")
	err := cli.InputCheck()
	if err != nil {
		logger.Err(err)
		cli.PrintUsage()
		return
	}

	logger.Debug(fmt.Sprintf("UseConfig flag: %v", *UseConfig))
	if *UseConfig {
		useConfigDeploy()
	} else {
		prepareManualDeploy()
	}
	logger.Debug(fmt.Sprintf("Parsed %d IP addresses.", len(Addresses)))
	logger.Debug(fmt.Sprintf("Key: %s, PasswordList length: %d", *Key, len(PasswordList)))
	if *Key != "" || len(PasswordList) != 0 {
		useManualDeploy()
	}

	if len(BrokenHosts) != 0 {
		logger.Debug(fmt.Sprintf("BrokenHosts detected: %v", BrokenHosts))
		printBrokenHosts()
	}

	if *CreateConfig != "" {
		logger.Debug("CreateConfig flag detected. Saving config...")
		config.SaveConfig()
	}

	if len(AnnoyingErrs) > 0 {
		logger.Debug("Processing AnnoyingErrs...")
		for _, conerr := range AnnoyingErrs {
			logger.Err(conerr)
		}
	}

	logger.Info(fmt.Sprintf("Total hosts hit: %d\n", TotalRuns))
	logger.Debug("Application execution completed.")
}

func useConfigDeploy() {
	logger.Debug("Starting useConfigDeploy...")
	config.ReadConfig()

	if len(config.ConfigEntries) == 0 {
		logger.Err("No entries in config file")
		return
	}

	logger.Debug(fmt.Sprintf("Config entries found: %d", len(config.ConfigEntries)))
	tempConfigEntries := config.ConfigEntries

	if *Targets != "" {
		logger.Debug("Filtering config entries based on specified targets...")
		var err error
		Addresses, _, err = utils.ParseIPs(*Targets)
		if err != nil {
			logger.Err(fmt.Sprintf("Error parsing targets: %s", err))
			return
		}

		filteredEntries := []config.ConfigEntry{}
		for _, entry := range tempConfigEntries {
			for _, address := range Addresses {
				if entry.IP == address.String() {
					filteredEntries = append(filteredEntries, entry)
					break
				}
			}
		}
		tempConfigEntries = filteredEntries
		logger.Debug(fmt.Sprintf("Filtered config entries: %d", len(tempConfigEntries)))
	}

	var wg sync.WaitGroup
	for _, Entry := range tempConfigEntries {
		logger.Debug(fmt.Sprintf("Running config entry: %+v", Entry))
		wg.Add(1)
		go runner.RunnerCred(Entry.IP, *Outfile, &wg, Entry.Username, Entry.Password)
	}
	wg.Wait()
	logger.Debug("useConfigDeploy completed.")
}

func prepareManualDeploy() {
	logger.Debug("Starting prepareManualDeploy...")

	var err error
	Addresses, StringAddresses, err = utils.ParseIPs(*Targets)

	if err != nil {
		logger.Err(fmt.Sprintf("Error parsing targets: %s", err))
		return
	}

	logger.Debug(fmt.Sprintf("Parsed %d IP addresses.", len(Addresses)))
	if !*QuietOut {
		fmt.Printf("Specified targets (%d addresses):\n\t%s\n", len(Addresses), strings.Join(StringAddresses, "\n\t"))
		fmt.Printf("Specified scripts (%d files):\n\t%s\n", len(Scripts), strings.Join(Scripts, "\n\t"))
		if len(EnvironCmds) != 0 {
			fmt.Printf("Specified environmental commands (%d items):\n\t%s\n", len(EnvironCmds), strings.Join(EnvironCmds, "\n\t"))
		}
	}

	UsernameList = strings.Split(*Usernames, ",")
	logger.Debug(fmt.Sprintf("Parsed usernames: %v", UsernameList))

	if *Passwords == "" && *Key == "" && *CreateConfig == "" {
		fmt.Print("Password: ")
		password, err := term.ReadPassword(int(syscall.Stdin))
		if err != nil {
			logger.Fatal(err)
		}
		PasswordList = []string{strings.TrimSpace(string(password))}
		fmt.Println()
		logger.Debug("Password read from terminal.")
	} else if *Passwords != "" {
		PasswordList = strings.Split(*Passwords, ",")
		logger.Debug(fmt.Sprintf("Parsed passwords: %v", PasswordList))
	} else if *Key != "" {
		_, err = os.ReadFile(*Key)
		if err != nil {
			logger.Fatal(err)
		}
		logger.Debug(fmt.Sprintf("Key file found: %s", *Key))
	}
	logger.Debug(fmt.Sprintf("Parsed %d IP addresses.", len(Addresses)))
	logger.Debug("prepareManualDeploy completed.")
}

func useManualDeploy() {
	logger.Debug("Starting useManualDeploy...")

	if len(Addresses) == 0 {
		logger.Err("No addresses to deploy. Ensure target IPs are parsed correctly.")
		return
	}

	var wg sync.WaitGroup
	for _, address := range Addresses {
		logger.Debug(fmt.Sprintf("Deploying to address: %s", address.String()))
		wg.Add(1)
		go runner.RunnerBf(address.String(), *Outfile, &wg)
	}
	wg.Wait()
	logger.Debug("useManualDeploy completed.")
}


func printBrokenHosts() {
	logger.Debug("Printing broken hosts...")
	logger.Err("The following hosts had janky ssh and should be configured manually:")
	for _, host := range BrokenHosts {
		logger.Err(host)
	}
	logger.Debug("Broken hosts printed.")
}
