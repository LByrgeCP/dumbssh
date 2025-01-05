package utils

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"bufio"
	"strings"
	"crypto/rand"

	"inet.af/netaddr"

	"github.com/LByrgeCP/coordinate-kali/internal/logger"
)

func ParseIPs(targets string) ([]netaddr.IP, []string, error) {
	logger.Debug("Starting ParseIPs with targets:", targets)

	targetTokens := strings.Split(targets, ",")
	logger.Debug("Split targets into tokens:", targetTokens)

	ipSetBuilder := netaddr.IPSetBuilder{}

	for _, token := range targetTokens {
		token = strings.TrimSpace(token)
		if token == "" {
			continue
		}
		logger.Debug("Processing token:", token)
		if err := addTargetToSet(token, &ipSetBuilder); err != nil {
			logger.Err("Error adding target to IP set:", err)
			return nil, nil, err
		}
	}

	ipSet, err := ipSetBuilder.IPSet()
	if err != nil {
		logger.Err("Error building IP set:", err)
		return nil, nil, fmt.Errorf("error building IP set: %w", err)
	}

	logger.Debug("Built IP set:", ipSet)

	individualIPs, stringAddresses := extractIPsAndRanges(ipSet)

	logger.Debug("Extracted individual IPs:", individualIPs)
	logger.Debug("Extracted string addresses:", stringAddresses)

	return individualIPs, stringAddresses, nil
}

func GenerateRandomFileName(length int) string {
	logger.Debug("Starting GenerateRandomFileName with length:", length)
	const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	b := make([]byte, length)
	_, err := rand.Read(b)
	if err != nil {
		logger.Err("Error generating random bytes:", err)
		panic(err)
	}
	for i := range b {
		b[i] = charset[int(b[i])%len(charset)]
	}
	filename := string(b)
	logger.Debug("Generated random file name:", filename)
	return filename
}

func Dos2unix(filePath string) error {
	file, err := os.Open(filePath)
	if err != nil {
		return fmt.Errorf("failed to open file: %v", err)
	}
	defer file.Close()

	reader := bufio.NewReader(file)
	var buffer bytes.Buffer

	for {
		line, err := reader.ReadBytes('\n')
		if err != nil && err != io.EOF {
			return fmt.Errorf("error reading file: %v", err)
		}

		line = bytes.Replace(line, []byte("\r"), []byte(""), -1)
		buffer.Write(line)

		if err == io.EOF {
			break
		}
	}

	file, err = os.OpenFile(filePath, os.O_WRONLY|os.O_TRUNC, 0644)
	if err != nil {
		return fmt.Errorf("failed to open file for writing: %v", err)
	}
	defer file.Close()

	_, err = file.Write(buffer.Bytes())
	if err != nil {
		return fmt.Errorf("error writing to file: %v", err)
	}

	return nil
}