package main

import (
	"log"
	"os"
	"path/filepath"
)

var dotfilesDir string

func init() {
	dotfilesDir = os.Getenv("FSOUZA_DOTFILES_DIR")
}

func main() {
	if dotfilesDir == "" {
		log.Fatal("missing FSOUZA_DOTFILES_DIR")
	}

	nv, err := loadNeovimSettings()
	if err != nil {
		log.Fatal(err)
	}

	venvDir := filepath.Join(nv.CacheDir, "venv")
	err = ensureVirtualenv(venvDir)
	if err != nil {
		log.Fatal(err)
	}

	setupLangervers(nv, venvDir)
}
