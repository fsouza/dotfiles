package main

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/fsouza/dotfiles/tools"
)

func getJavaHome(version string) (string, error) {
	rtx, err := exec.LookPath("rtx")
	if err != nil {
		return "", fmt.Errorf("cannot find rtx: %w", err)
	}

	rtxTool := fmt.Sprintf("java@%s", version)
	err = tools.Run(&tools.RunOptions{
		Cmd:  rtx,
		Args: []string{"install", rtxTool},
	})
	if err != nil {
		return "", err
	}

	output, err := exec.Command(rtx, "where", rtxTool).CombinedOutput()
	if err != nil {
		os.Stderr.Write(output)
		return "", err
	}

	return string(bytes.TrimSpace(output)), nil
}

func downloadJDTLS(targetDir, latestSnapshot string) error {
	jdtlsURL := fmt.Sprintf("https://download.eclipse.org/jdtls/snapshots/%s", latestSnapshot)
	// taking a shortcut here instead of using archive/tar and compress/gzip
	return tools.Run(&tools.RunOptions{
		Cmd: "bash",
		Args: []string{
			"-c",
			fmt.Sprintf("curl -sL %s | tar -C %s -xzf -", jdtlsURL, targetDir),
		},
	})
}

func currentJDTLSSnapshot(langserversDir string) string {
	data, _ := os.ReadFile(filepath.Join(langserversDir, "jdtls.latest-snapshot"))
	return string(data)
}

func latestJDTLSSnapshot() (string, error) {
	const url = "https://download.eclipse.org/jdtls/snapshots/latest.txt"
	resp, err := http.Get(url)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	if resp.StatusCode > 299 {
		return "", fmt.Errorf("unexpected status from eclipse.org: %d - %s", resp.StatusCode, data)
	}
	return string(bytes.TrimSpace(data)), nil
}
