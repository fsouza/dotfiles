package main

import (
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/fsouza/dotfiles/tools"
)

func main() {
	fileType := getType(os.Args[1:])
	dotfilesDir, err := dotfilesDir()
	if err != nil {
		log.Fatal(err)
	}
	modDir := filepath.Join(dotfilesDir, "nvim", "langservers")
	tools.Exec([]string{
		"go",
		"run",
		"-C",
		modDir,
		"github.com/bazelbuild/buildtools/buildifier",
		"--lint=fix",
		"--warnings=all",
		"--type=" + fileType,
	})
}

func dotfilesDir() (string, error) {
	binName := os.Args[0]
	return filepath.Abs(filepath.Join(binName, "..", "..", ".."))
}

func getType(args []string) string {
	var filename string
	if len(args) > 0 {
		filename = filepath.Base(args[0])
	}

	switch filename {
	case "BUILD", "WORKSPACE":
		return strings.ToLower(filename)
	default:
		return "default"
	}
}
