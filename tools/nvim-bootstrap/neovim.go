package main

import (
	"encoding/json"
	"log"
	"os/exec"
	"strings"
)

type Neovim struct {
	CacheDir string
	DataDir  string
}

func loadNeovimSettings() (*Neovim, error) {
	cmd := exec.Command("nvim", "--clean", "-l", "-")
	cmd.Stdin = strings.NewReader(`print(vim.json.encode({cacheDir=vim.fn.stdpath("cache"), dataDir=vim.fn.stdpath("data")}))`)
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("failed to load neovim settings. output: %s", output)
		return nil, err
	}
	var neovim Neovim
	err = json.Unmarshal(output, &neovim)
	return &neovim, err
}
