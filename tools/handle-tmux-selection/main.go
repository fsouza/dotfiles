package main

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/fsouza/dotfiles/tools"
)

var diagnosticRegexp = regexp.MustCompile(`\s*([^:]+):\d+:(\d+:)?.+`)

func main() {
	rawInput, err := io.ReadAll(os.Stdin)
	if err != nil {
		log.Fatal(err)
	}

	if len(rawInput) == 0 {
		handleCurrentLine()
	}

	paneCwd, err := getPaneCwd()
	if err != nil {
		log.Fatal(err)
	}

	if _, err := exec.LookPath("nvim"); err == nil && shouldSendToNvim(paneCwd, rawInput) {
		err = exec.Command("tmux", "send-keys", "-X", "cancel").Run()
		if err != nil {
			log.Fatal(err)
		}
		sendToNvim(paneCwd, rawInput)
	}
}

func getPaneCwd() (string, error) {
	output, err := exec.Command("tmux", "display-message", "-p", "#{pane_current_path}").CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("failed to get paneCwd: %v. output: %s", err, output)
	}

	return strings.TrimSpace(string(output)), nil
}

func handleCurrentLine() {
	tools.Exec(append([]string{"tmux", "send-keys", "-X", "select-line", ";", "send-keys", "-X", "copy-pipe-and-cancel"}, os.Args...))
}

func shouldSendToNvim(paneCwd string, rawInput []byte) bool {
	lines := bytes.Split(rawInput, []byte{'\n'})
	for _, line := range lines {
		if isValidDiagnostic(paneCwd, line) {
			return true
		}
	}
	return false
}

func isValidDiagnostic(paneCwd string, line []byte) bool {
	groups := diagnosticRegexp.FindSubmatch(line)
	if groups == nil {
		return false
	}

	filename := string(groups[1])
	if !filepath.IsAbs(filename) {
		filename = filepath.Join(paneCwd, filename)
	}
	_, err := os.Stat(filename)
	return err == nil
}

func sendToNvim(paneCwd string, rawInput []byte) {
	file, err := os.CreateTemp("", "")
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()
	file.Write(rawInput)

	nvimCommand := fmt.Sprintf("lua require('fsouza.lib.tmux-selection').handle('%s')", file.Name())
	tools.Exec([]string{"tmux", "split-window", "-b", "-c", paneCwd, "-Z", "nvim", "-c", nvimCommand})
}
