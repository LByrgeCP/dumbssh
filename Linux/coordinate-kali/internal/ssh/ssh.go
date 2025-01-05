package ssh

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"net"
	"os"
	"regexp"
	"strings"
	"sync"
	"time"

	"github.com/bramvdbogaerde/go-scp"
	"github.com/melbahja/goph"

	. "github.com/LByrgeCP/coordinate-kali/internal/config"
	. "github.com/LByrgeCP/coordinate-kali/internal/globals"
	"github.com/LByrgeCP/coordinate-kali/internal/logger"
	"github.com/LByrgeCP/coordinate-kali/internal/utils"
)

func SsherWrapper(i Instance, client *goph.Client) {
	logger.Debug(fmt.Sprintf("Starting SsherWrapper for instance: %+v", i))
	var wg sync.WaitGroup

	first := true
	for _, path := range Scripts {
		logger.Debug(fmt.Sprintf("Processing script path: %s", path))
		var Script string
		i.Script = path

		ScriptContents, err := os.ReadFile(path)
		if err != nil {
			logger.Crit(i, errors.New("Error reading "+i.Script+": "+err.Error()))
			continue
		}
		for _, cmd := range EnvironCmds {
			Script += fmt.Sprintf("%s ", cmd)
		}
		Script += string(ScriptContents)

		for t := 0; t < *Threads && t < len(Scripts); t++ {
			if first {
				logger.Debug("Launching first thread for script execution.")
				first = false
			}
			wg.Add(1)
			go ssher(i, client, Script, &wg)
			i.ID++
		}
	}

	wg.Wait()
	logger.Debug("Finished executing all threads in SsherWrapper.")
}

func ssher(i Instance, client *goph.Client, script string, wg *sync.WaitGroup) {
	defer wg.Done()

	logger.Debug(fmt.Sprintf("Starting ssher for instance: %+v with script length: %d", i, len(script)))

	filename := fmt.Sprintf("%s/%s", *TmpDir, utils.GenerateRandomFileName(16))
	remoteFilename := fmt.Sprintf("/tmp/%s", utils.GenerateRandomFileName(16))
	logger.Debug(fmt.Sprintf("Generated temporary filename: %s", filename))

	output, err := client.Run("echo a ; asdfhasdf")
	if len(output) == 0 {
		logger.Err(fmt.Sprintf("%s: Couldn't read stdout. Coordinate does not work with this host's shell probably\n", i.IP))
		BrokenHosts = append(BrokenHosts, i.IP)
		return
	}

	elevated := true
	if i.Username != "root" {
		elevated = false
		logger.Debug(fmt.Sprintf("User '%s' is not root.", i.Username))
		if *Sudo {
			logger.Debug("Sudo is enabled. Attempting privilege escalation.")
			if escalateSudo(i, client) {
				elevated = true
				logger.InfoExtra(i, "Privilege escalation succeeded.")
			} else {
				logger.InfoExtra(i, "Privilege escalation failed.")
			}
		} else {
			logger.InfoExtra(i, "Not root, not sudoing. Proceeding with user.")
		}
	}

	name := "hostname"
	output, err = client.Run(name)
	if err != nil {
		logger.Debug("Hostname command failed, attempting 'cat /etc/hostname'")
		name = "cat /etc/hostname"
		output, err = client.Run(name)
	}
	stroutput := string(output)
	if !strings.Contains(stroutput, "No such file or directory") {
		i.Hostname = strings.TrimSpace(stroutput)
		logger.Debug(fmt.Sprintf("Resolved hostname: %s", i.Hostname))
	} else {
		i.Hostname = i.IP
		logger.Debug("No hostname found.")
	}

	i.Outfile = strings.Replace(i.Outfile, "%i%", i.IP, -1)
	i.Outfile = strings.Replace(i.Outfile, "%h%", i.Hostname, -1)
	i.Outfile = strings.Replace(i.Outfile, "%s%", strings.TrimSuffix(i.Script, ".sh"), -1)

	logger.Debug(fmt.Sprintf("Resolved output file path: %s", i.Outfile))

	err = os.WriteFile(filename, []byte(script), 0644)
	if err != nil {
		logger.Err(fmt.Sprintf("Error writing to temporary file: %s", filename))
		return
	}
	logger.Debug(fmt.Sprintf("Script written to temporary file: %s", filename))

	logger.Debug(fmt.Sprintf("Converting to unix endings: %s", filename))
	err = utils.Dos2unix(filename)
	if err != nil {
		logger.Err(fmt.Sprintf("Error converting file to unix endings: %s", err))
	}

	err = Upload(client, filename, remoteFilename)
	if err != nil {
		logger.ErrExtra(i, err)
		os.Remove(filename)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), Timeout)
	defer cancel()

	var command string
	if elevated || !*Sudo {
		command = fmt.Sprintf("%s ; rm %s", remoteFilename, remoteFilename)
	} else {
		command = fmt.Sprintf("echo \"%s\" | sudo -S %s; sudo rm %s", i.Password, remoteFilename, remoteFilename)
	}
	logger.Debug(fmt.Sprintf("Executing command: %s", command))

	output, err = client.RunContext(ctx, command)
	stroutput = string(output)

	if err != nil {
		if strings.Contains(err.Error(), "context deadline exceeded") {
			if len(i.Hostname) > 0 {
				AnnoyingErrs = append(AnnoyingErrs, fmt.Sprintf("%s timed out on %s", i.Script, i.Hostname))
			} else {
				AnnoyingErrs = append(AnnoyingErrs, fmt.Sprintf("%s timed out on %s", i.Script, i.IP))
			}
		} else {
			logger.Err(fmt.Sprintf("%s: Error running script: %s\n", i.IP, err))
		}
	}
	if len(stroutput) > 0 {
		logger.Stdout(i, stroutput)
		if *CreateConfig != "" {
			for _, line := range strings.Split(stroutput, "\n") {
				parts := strings.Split(line, ",")
				if len(parts) < 2 || parts[0] != "root" {
					continue
				}
				Password := parts[1]
				UpdateEntry(ConfigEntry{IP: i.IP, Username: "root", Password: Password})
			}
		}
	}
	os.Remove(filename)
	logger.Debug(fmt.Sprintf("Removed temporary file: %s", filename))

	TotalRuns++
	logger.Debug(fmt.Sprintf("Total runs incremented: %d", TotalRuns))
}

func Upload(client *goph.Client, localPath string, remotePath string) error {
	logger.Debug(fmt.Sprintf("Starting Upload. Local path: %s, Remote path: %s", localPath, remotePath))

	scp_client, err := scp.NewClientBySSH(client.Client)
	if err != nil {
		logger.Err(fmt.Sprintf("Failed to initialize SCP client: %s", err))
		return err
	}

	f, err := os.Open(localPath)
	if err != nil {
		logger.Err(fmt.Sprintf("Failed to open local file: %s", err))
		return err
	}
	defer f.Close()

	err = scp_client.CopyFromFile(context.Background(), *f, remotePath, "0777")
	if err != nil {
		logger.Err(fmt.Sprintf("Failed to SCP file: %s", err))
		return err
	}

	output, err := client.Run("ls " + remotePath)
	if err != nil {
		logger.Err(fmt.Sprintf("Failed to verify remote file: %s", err))
		return err
	}
	if strings.Contains(string(output), "No such file or directory") {
		logger.Err("Remote file does not exist after upload.")
		return errors.New("upload failed: remote file missing")
	}
	logger.Debug("Upload successful.")
	return nil
}

func IsValidPort(host string, port int) bool {
	logger.Debug(fmt.Sprintf("Checking if port %d is valid on host %s", port, host))

	address := fmt.Sprintf("%s:%d", host, port)
	conn, err := net.DialTimeout("tcp", address, 5000*time.Millisecond)
	if err != nil {
		return false
	}
	defer conn.Close()

	banner, _ := bufio.NewReader(conn).ReadString('\n')
	regex := regexp.MustCompile(`(?i)windows|winssh`)
	isValid := !regex.MatchString(banner)
	logger.Debug(fmt.Sprintf("Port %d validity on host %s: %t", port, host, isValid))
	return isValid
}
