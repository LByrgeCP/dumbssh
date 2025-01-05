package runner

import (
	"fmt"
	"sync"

	"github.com/melbahja/goph"

	. "github.com/LByrgeCP/coordinate-kali/internal/globals"
	"github.com/LByrgeCP/coordinate-kali/internal/logger"
	"github.com/LByrgeCP/coordinate-kali/internal/ssh"
)

func handleSSHConnection(i Instance, client *goph.Client, err error) bool {
	if err != nil {
		logger.ErrExtra(i, fmt.Sprintf("Error while connecting to %s: %s", i.IP, err))
		AnnoyingErrs = append(AnnoyingErrs, fmt.Sprintf("Error while connecting to %s: %s", i.IP, err))
		return false
	}
	defer client.Close()
	logger.InfoExtra(i, fmt.Sprintf("Valid credentials for username '%s'", i.Username))
	ssh.SsherWrapper(i, client)
	return true
}

func attemptSSH(ip, outfile, username, password string) bool {
	logger.Debug(fmt.Sprintf("Starting attemptSSH with IP: %s, username: %s", ip, username))

	i := Instance{
		IP:       ip,
		Outfile:  outfile,
		Username: username,
		Password: password,
	}

	if !ssh.IsValidPort(i.IP, *Port) {
		logger.Debug(fmt.Sprintf("Port %d is invalid or closed on host %s", *Port, i.IP))
		return false
	}

	client, err := goph.NewUnknown(i.Username, i.IP, goph.KeyboardInteractive(i.Password))
	return handleSSHConnection(i, client, err)
}

func RunnerBf(ip string, outfile string, w *sync.WaitGroup) {
	defer w.Done()
	logger.Debug(fmt.Sprintf("Starting RunnerBf for IP: %s", ip))

	i := Instance{IP: ip, Outfile: outfile}
	if !ssh.IsValidPort(i.IP, *Port) {
		logger.Debug(fmt.Sprintf("Port %d is invalid or closed on host %s", *Port, i.IP))
		return
	}

	found := false
	for _, u := range UsernameList {
		if found {
			logger.Debug(fmt.Sprintf("Valid credentials found for user '%s', skipping remaining usernames.", u))
			break
		}
		for _, p := range PasswordList {
			if p == "" {
				logger.Debug(fmt.Sprintf("Skipping empty password for user '%s'", u))
				continue
			}
			logger.DebugExtra(i, fmt.Sprintf("Trying username '%s' and password '%s'", u, p))
			if attemptSSH(ip, outfile, u, p) {
				found = true
				break
			}
		}

		if !found && *Key != "" {
			logger.DebugExtra(i, fmt.Sprintf("Trying key-based authentication for username '%s'", u))
			privKey, err := goph.Key(*Key, "")
			if err != nil {
				logger.ErrExtra(i, fmt.Sprintf("Error loading private key for user '%s': %s", u, err))
				continue
			}
			client, err := goph.NewUnknown(u, ip, privKey)
			found = handleSSHConnection(i, client, err)
		}
	}

	if !found {
		logger.Debug(fmt.Sprintf("No valid credentials found for IP: %s", ip))
	}
}

func RunnerCred(ip string, outfile string, w *sync.WaitGroup, username, password string) {
	defer w.Done()
	logger.Debug(fmt.Sprintf("Starting RunnerCred for IP: %s, username: %s", ip, username))

	if !attemptSSH(ip, outfile, username, password) {
		logger.Err(fmt.Sprintf("Login attempt failed for IP: %s, username: %s", ip, username))
		AnnoyingErrs = append(AnnoyingErrs, fmt.Sprintf("Login attempt failed to: %s", ip))
	} else {
		logger.Debug(fmt.Sprintf("Login succeeded for IP: %s, username: %s", ip, username))
	}
}
