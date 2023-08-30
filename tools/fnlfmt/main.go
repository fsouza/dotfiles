package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
)

func main() {
	cacheDir := cacheDir()
	var stdout, stderr bytes.Buffer
	cmd := exec.Command(filepath.Join(cacheDir, "fnlfmt", "fnlfmt"), os.Args[1:]...)
	cmd.Stdin = os.Stdin
	cmd.Stderr = &stderr
	cmd.Stdout = &stdout
	cmd.Env = append(
		slices.Clone(os.Environ()),
		"PATH="+filepath.Join(cacheDir, "hr", "bin"),
	)
	err := cmd.Run()
	if err != nil {
		os.Stderr.Write(stderr.Bytes())
		os.Exit(cmd.ProcessState.ExitCode())
	}

	output := stdout.Bytes()
	index := len(output) - 1
	for index >= 0 && output[index] == '\n' {
		index--
	}

	fmt.Printf("%s\n", output[:index+1])
}

func cacheDir() string {
	defaultCacheDir := os.ExpandEnv("${HOME}/.cache/nvim")
	if cacheDir, ok := os.LookupEnv("NVIM_CACHE_DIR"); ok {
		return cacheDir
	}
	return defaultCacheDir
}
